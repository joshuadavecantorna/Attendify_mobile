import { reactive, computed } from 'vue';
import type { ChatMessage, ChatState } from '@/types/chatbot';
import axios from 'axios';

const state = reactive<ChatState>({
    isOpen: false,
    messages: [],
    isLoading: false,
    error: null,
});

export function useChatbot() {
    const generateId = () => `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

    const addMessage = (role: 'user' | 'assistant', content: string, isLoading = false) => {
        const message: ChatMessage = {
            id: generateId(),
            role,
            content,
            timestamp: new Date(),
            isLoading,
        };
        state.messages.push(message);
        return message;
    };

    const sendMessage = async (message: string) => {
        if (!message.trim() || state.isLoading) return;

        addMessage('user', message);
        state.isLoading = true;
        state.error = null;

        const loadingMessage = addMessage('assistant', '', true);

        try {
            const conversationHistory = state.messages
                .slice(-10)
                .map(m => ({ role: m.role, content: m.content }));

            // The logic to differentiate between DB and streaming queries can be simplified
            // For now, we will use the 'query' endpoint for all messages.
            const response = await axios.post('/api/chatbot/query', {
                message,
                conversation_history: conversationHistory,
            }, {
                headers: { 'Content-Type': 'application/json' }
            });

            const idx = state.messages.findIndex(m => m.id === loadingMessage.id);
            if (idx !== -1) state.messages.splice(idx, 1);

            if (response.data.reply) {
                addMessage('assistant', response.data.reply);
            } else {
                const errMsg = response.data.error || 'Failed to get a response.';
                state.error = errMsg;
                addMessage('assistant', `Sorry, I encountered an error: ${errMsg}`);
            }

        } catch (err: any) {
            const idx = state.messages.findIndex(m => m.id === loadingMessage.id);
            if (idx !== -1) {
                const errorMessage = err.response?.data?.reply || err.message || 'Failed to send message.';
                state.messages[idx].content = `Sorry, I encountered an error: ${errorMessage}`;
                state.messages[idx].isLoading = false;
                state.error = errorMessage;
            } else {
                const errorMessage = err.response?.data?.reply || err.message || 'Failed to send message.';
                addMessage('assistant', `Sorry, I encountered an error: ${errorMessage}`);
                state.error = errorMessage;
            }
        } finally {
            state.isLoading = false;
        }
    };

    const openChat = () => { state.isOpen = true; state.error = null; };
    const closeChat = () => { state.isOpen = false; };
    const toggleChat = () => { state.isOpen = !state.isOpen; };
    const clearHistory = () => { state.messages = []; state.error = null; };

    return {
        isOpen: computed(() => state.isOpen),
        messages: computed(() => state.messages),
        isLoading: computed(() => state.isLoading),
        error: computed(() => state.error),
        openChat,
        closeChat,
        toggleChat,
        sendMessage,
        clearHistory,
    };
}