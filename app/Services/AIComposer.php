<?php

namespace App\Services;

use Illuminate\Support\Arr;
use Illuminate\Support\Str;

class AIComposer
{
    /**
     * Compose a structured prompt combining cached user context, dynamic retrieval results, and the user question.
     *
     * @param array $cachedContext  The output of UserContextBuilder::build()
     * @param array $retrieval      The output of RetrievalPlanner::planAndExecute() (contains 'intent','plan','results')
     * @param string $question      The original user question
     * @param array $opts           Options: max_list_items (int), truncate_chars (int)
     * @return string               Final message to send to the AI model
     */
    public function compose(array $cachedContext, array $retrieval, string $question, array $opts = []): string
    {
        $maxItems = $opts['max_list_items'] ?? 12;
        $truncateChars = $opts['truncate_chars'] ?? 8000; // keep prompt within reasonable size

        $role = $cachedContext['role'] ?? ($cachedContext['user']['role'] ?? 'unknown');

        // Sanitize and prepare cached context (limit arrays)
        $sanitizedCached = $this->sanitizeContext($cachedContext, $maxItems);

        // Prepare retrieval plan and results
        $plan = $retrieval['plan'] ?? [];
        $resultsRaw = $retrieval['results'] ?? null;
        $results = $this->prepareResults($resultsRaw, $maxItems);

        // Build structured prompt
        $parts = [];
        $parts[] = "User Role: {$role}";
        $parts[] = "User Cached Context:";
        $parts[] = $this->toJson($sanitizedCached);

        // Provide a compact UI-focused context the frontend shows to the user.
        // This helps the model answer consistently with what the UI displays.
        $uiContext = $this->extractUiContext($sanitizedCached);
        $parts[] = "UI Context (sanitized):";
        $parts[] = $this->toJson($uiContext);

        $parts[] = "Dynamic Retrieval Plan:";
        $parts[] = $this->toJson($plan);

        $parts[] = "Dynamic Retrieval Results (sample / trimmed):";
        $parts[] = $this->toJson($results);

        $parts[] = "User Question:";
        $parts[] = '"' . trim($question) . '"';

        // Guidance for the model: be explicit about constraints and output style
        $instructions = [];
        $instructions[] = "Instructions:";
        $instructions[] = "- Use only the data provided above (Cached Context + Retrieval Results) to answer the question.";
        $instructions[] = "- Do NOT hallucinate or invent database fields or records that are not present.";
        $instructions[] = "- When responding, clearly label facts that come from cached context vs dynamic retrieval.";
        $instructions[] = "- If the data is insufficient, say you don't have enough information and suggest a safe next step (e.g., ask for clarification or request fresh data).";
        $instructions[] = "- Keep the answer concise and actionable for the user role ({$role}).";
        $instructions[] = "- OUTPUT CONTRACT: Reply only in cheerful, plain English. Do NOT return code blocks, raw JSON, arrays, numeric vectors, or tabular CSV. Do NOT include backticks or triple-backtick fences. If you must present structured data, convert it into short bullet points or 1-2 friendly sentences per item.";
        $instructions[] = "- TONE: Friendly, helpful, upbeat, and concise. Example: 'Sure — I checked your attendance for March: you have 92% attendance. Keep it up!'";

        $parts = array_merge($parts, $instructions);

        $message = implode("\n\n", $parts);

        // Truncate if necessary
        if (strlen($message) > $truncateChars) {
            $message = substr($message, 0, $truncateChars - 100) . "\n\n[TRUNCATED: prompt exceeded {$truncateChars} chars]";
        }

        return $message;
    }

    protected function sanitizeContext(array $ctx, int $maxItems): array
    {
        // Deep copy
        $san = $ctx;

        // Limit student/classes and attendance
        if (isset($san['student'])) {
            if (isset($san['student']['classes']) && is_array($san['student']['classes'])) {
                $san['student']['classes'] = array_slice($san['student']['classes'], 0, $maxItems);
            }
            if (isset($san['student']['recent_attendance']) && is_array($san['student']['recent_attendance'])) {
                $san['student']['recent_attendance'] = array_slice($san['student']['recent_attendance'], 0, $maxItems);
            }
        }

        if (isset($san['teacher'])) {
            if (isset($san['teacher']['classes']) && is_array($san['teacher']['classes'])) {
                $san['teacher']['classes'] = array_slice($san['teacher']['classes'], 0, $maxItems);
            }
        }

        // Remove any large keys the AI doesn't need
        if (isset($san['user']['password'])) {
            unset($san['user']['password']);
        }

        return $san;
    }

    protected function prepareResults($resultsRaw, int $maxItems)
    {
        // Convert collections / objects -> arrays when possible
        if (is_object($resultsRaw) && method_exists($resultsRaw, 'toArray')) {
            $arr = $resultsRaw->toArray();
        } elseif (is_array($resultsRaw)) {
            $arr = $resultsRaw;
        } else {
            // scalar or other
            $arr = [$resultsRaw];
        }

        // If it's a numeric-indexed list, limit items
        if ($this->isList($arr)) {
            $arr = array_slice($arr, 0, $maxItems);
        } else {
            // For associative arrays, possibly trim nested lists
            array_walk_recursive($arr, function (&$val, $key) use ($maxItems) {
                // noop — keep values as-is
            });
        }

        return $arr;
    }

    protected function isList(array $arr): bool
    {
        if (empty($arr)) return true;
        return array_keys($arr) === range(0, count($arr) - 1);
    }

    /**
     * Extract a small UI-friendly context from the cached context.
     */
    protected function extractUiContext(array $ctx): array
    {
        $ui = [];
        if (isset($ctx['user'])) {
            $ui['user'] = [
                'id' => $ctx['user']['id'] ?? null,
                'name' => $ctx['user']['name'] ?? null,
                'role' => $ctx['user']['role'] ?? null,
                'email' => $ctx['user']['email'] ?? null,
            ];
        }

        if (isset($ctx['student'])) {
            $s = $ctx['student'];
            $ui['student'] = [
                'id' => $s['id'] ?? null,
                'name' => $s['name'] ?? null,
                'student_id' => $s['student_id'] ?? null,
                'year' => $s['year'] ?? null,
                'course' => $s['course'] ?? null,
                'section' => $s['section'] ?? null,
                'stats' => $s['stats'] ?? null,
                'classes' => array_slice($s['classes'] ?? [], 0, 6),
                'recent_attendance' => array_slice($s['recent_attendance'] ?? [], 0, 6),
                'recent_requests' => array_slice($s['recent_requests'] ?? [], 0, 3),
            ];
        }

        if (isset($ctx['teacher'])) {
            $t = $ctx['teacher'];
            $ui['teacher'] = [
                'id' => $t['id'] ?? null,
                'name' => ($t['first_name'] ?? null) . ' ' . ($t['last_name'] ?? ''),
                'stats' => $t['stats'] ?? null,
                'classes' => array_slice($t['classes'] ?? [], 0, 8),
            ];
        }

        if (isset($ctx['admin'])) {
            $ui['admin'] = [
                'id' => $ctx['admin']['id'] ?? null,
                'name' => $ctx['admin']['name'] ?? null,
            ];
        }

        return $ui;
    }

    protected function toJson($data): string
    {
        // Ensure clean JSON without binary data
        try {
            return json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        } catch (\Throwable $e) {
            return '[unserializable data]';
        }
    }
}
