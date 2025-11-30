import { defineStore } from 'pinia';
import { ref, reactive } from 'vue';

export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant' | 'system' | 'error';
  text: string;
  streaming?: boolean;
  error?: string | null;
}

function uid() {
  return Math.random().toString(36).slice(2, 9);
}

function getCsrfToken(): string | null {
  const el = document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement | null;
  return el?.getAttribute('content') ?? null;
}

export const useChatbotStore = defineStore('chatbot', () => {
  const messages = reactive<ChatMessage[]>([]);
  const loading = ref(false);
  const streaming = ref(false);
  const lastError = ref<string | null>(null);
  const abortController = ref<AbortController | null>(null);
  const aiOnline = ref<boolean>(false);
  const healthPollIntervalId = ref<number | null>(null);

  function pushMessage(m: ChatMessage) {
    messages.push(m);
  }

  function clear() {
    messages.splice(0, messages.length);
    lastError.value = null;
  }

  async function sendMessage(text: string, useStream = true) {
    // If AI service is known to be offline, fail fast
    if (aiOnline.value === false) {
      const assistantId = uid();
      const assistantMsg: ChatMessage = { id: assistantId, role: 'error', text: '', error: 'AI service offline' };
      pushMessage(assistantMsg);
      lastError.value = 'AI service offline';
      return;
    }
    if (!text || !text.trim()) return;
    const userId = uid();
    const userMsg: ChatMessage = { id: userId, role: 'user', text: text };
    pushMessage(userMsg);

    const assistantId = uid();
    const assistantMsg: ChatMessage = { id: assistantId, role: 'assistant', text: '', streaming: useStream };
    pushMessage(assistantMsg);

    lastError.value = null;

    if (useStream) {
      return streamToAssistant(assistantId, text);
    }

    return postQuery(assistantId, text);
  }

  async function postQuery(assistantId: string, text: string) {
    loading.value = true;
    try {
      const token = getCsrfToken();
      const res = await fetch('/api/chatbot/query', {
        method: 'POST',
        credentials: 'same-origin',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { 'X-CSRF-TOKEN': token } : {}),
        },
        body: JSON.stringify({ message: text }),
      });

      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        const err = body?.error || body?.reply || `Request failed: ${res.status}`;
        markAssistantError(assistantId, String(err));
        lastError.value = String(err);
        return;
      }

      const data = await res.json();
      const out = (data?.reply && String(data.reply)) || JSON.stringify(data);
      updateAssistantText(assistantId, out);
    } catch (e: any) {
      const err = e?.message ?? String(e);
      markAssistantError(assistantId, err);
      lastError.value = err;
    } finally {
      loading.value = false;
    }
  }

  async function streamToAssistant(assistantId: string, text: string) {
    streaming.value = true;
    lastError.value = null;
    abortController.value = new AbortController();
    const controller = abortController.value;

    try {
      const token = getCsrfToken();
      const res = await fetch('/api/chatbot/stream', {
        method: 'POST',
        credentials: 'same-origin',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { 'X-CSRF-TOKEN': token } : {}),
        },
        body: JSON.stringify({ query: text }),
        signal: controller.signal,
      });

      if (!res.ok || !res.body) {
        const body = await res.text().catch(() => '');
        const err = body || `Stream failed: ${res.status}`;
        markAssistantError(assistantId, err);
        lastError.value = err;
        streaming.value = false;
        return;
      }

      const reader = res.body.getReader();
      const decoder = new TextDecoder();
      let done = false;
      // Buffer for partial JSON lines
      let partial = '';
      // The assembled assistant text to display
      let assistantText = '';

      while (!done) {
        const { value, done: d } = await reader.read();
        done = d;
        if (!value) continue;

        const chunk = decoder.decode(value, { stream: true });

        // Append to partial buffer and split by newline (NDJSON)
        partial += chunk;
        const lines = partial.split(/\r?\n/);

        // Keep the last line as partial (it may be incomplete)
        partial = lines.pop() ?? '';

        for (const line of lines) {
          const trimmed = line.trim();
          if (!trimmed) continue;

          let extracted: string | null = null;

          // Try to parse JSON line (NDJSON from the model)
          try {
            const obj = JSON.parse(trimmed);
            // Common shapes: { response: "..." } or { message: { content: "..." } }
            if (obj && typeof obj === 'object') {
              if (typeof obj.response === 'string') {
                extracted = obj.response;
              } else if (obj.message && typeof obj.message.content === 'string') {
                // Some model servers nest content here
                extracted = obj.message.content;
              } else if (typeof obj === 'string') {
                extracted = obj as unknown as string;
              }
            }
          } catch (e) {
            // not JSON — fallback below
          }

          // If we didn't extract structured content, try to salvage plain text
          if (extracted === null) {
            // Attempt to remove leading/trailing braces if server sent JSON-like but unparsable pieces
            const maybe = trimmed.replace(/^\{+|}+$/g, '').trim();
            if (maybe) extracted = maybe;
          }

          // Unescape double-encoded JSON strings like '"..."'
          if (extracted && extracted.startsWith('"') && extracted.endsWith('"')) {
            try {
              extracted = JSON.parse(extracted);
            } catch (e) {
              // ignore parse error and keep original
            }
          }

          if (extracted) {
            assistantText += extracted;
            updateAssistantText(assistantId, assistantText);
          }
        }
      }

      // If any leftover partial contains printable text, append it
      if (partial && partial.trim()) {
        // try to parse leftover as JSON
        try {
          const obj = JSON.parse(partial.trim());
          let leftover = null;
          if (obj && typeof obj === 'object') {
            leftover = obj.response ?? obj.message?.content ?? null;
          }
          if (!leftover && typeof obj === 'string') leftover = obj as unknown as string;
          if (leftover) {
            assistantText += leftover;
            updateAssistantText(assistantId, assistantText);
          }
        } catch (e) {
          assistantText += partial;
          updateAssistantText(assistantId, assistantText);
        }
      }

      // finalize
      streaming.value = false;
    } catch (e: any) {
      if (e.name === 'AbortError') {
        markAssistantError(assistantId, 'Stream aborted');
        lastError.value = 'Stream aborted';
      } else {
        const err = e?.message ?? String(e);
        markAssistantError(assistantId, err);
        lastError.value = err;
      }
      streaming.value = false;
    } finally {
      abortController.value = null;
    }
  }

  async function checkHealth() {
    try {
      const res = await fetch('/api/chatbot/status', { credentials: 'same-origin' });
      if (!res.ok) {
        aiOnline.value = false;
        return aiOnline.value;
      }
      const data = await res.json().catch(() => ({}));
      const ok = !!(data?.ai && data.ai.ok);
      aiOnline.value = ok;
      return ok;
    } catch (e) {
      aiOnline.value = false;
      return false;
    }
  }

  // Start polling AI health when the store is initialized
  (function startHealthPolling() {
    // initial check
    checkHealth();
    // poll every 15s
    healthPollIntervalId.value = window.setInterval(() => {
      checkHealth();
    }, 15000) as unknown as number;
  })();

  function updateAssistantText(id: string, text: string) {
    const idx = messages.findIndex((m) => m.id === id);
    if (idx !== -1) messages[idx].text = text;
  }

  function markAssistantError(id: string, error: string) {
    const idx = messages.findIndex((m) => m.id === id);
    if (idx !== -1) {
      messages[idx].error = error;
      messages[idx].streaming = false;
      messages[idx].role = 'error';
    }
  }

  function cancelStream() {
    if (abortController.value) {
      abortController.value.abort();
      abortController.value = null;
      streaming.value = false;
    }
  }

  async function retry(assistantId: string) {
    // Find the failed assistant message and original user message prior to it
    const idx = messages.findIndex((m) => m.id === assistantId);
    if (idx === -1) return;

    // find preceding user message
    const userMsg = [...messages]
      .slice(0, idx)
      .reverse()
      .find((m) => m.role === 'user');
    if (!userMsg) return;

    // remove assistant failed message
    messages.splice(idx, 1);

    // send again with streaming enabled
    await sendMessage(userMsg.text, true);
  }

  return {
    messages,
    loading,
    streaming,
    lastError,
    aiOnline,
    pushMessage,
    sendMessage,
    clear,
    cancelStream,
    retry,
    checkHealth,
  };
});
