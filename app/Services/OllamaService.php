<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use App\Models\Attendance;
use App\Models\ClassModel;
use App\Models\Excuse;
use Carbon\Carbon;

class OllamaService
{
    protected string $model;
    protected string $baseUrl;
    protected bool $stream;

    public function __construct()
    {
        $this->model = config('ollama.model', 'mistral');
        $this->baseUrl = config('ollama.url', 'http://localhost:11434');
        $this->stream = true; // Force stream to be false for now
    }

    public function generate(string $prompt, bool $stream = true)
    {
        // Quick health-check: fail fast if Ollama base URL is unreachable
        if (!$this->isServiceReachable()) {
            Log::error('OllamaService::generate - model service unreachable', ['baseUrl' => $this->baseUrl]);
            return null;
        }

        // Simplified for non-streaming generation
        return $this->sendRequest('generate', [
            'prompt' => $prompt,
        ]);
    }

    /**
     * Quick, lightweight reachability check for the Ollama/base model service.
     * Returns true when the host responds to a short GET request.
     */
    private function isServiceReachable(): bool
    {
        try {
            $resp = Http::withOptions(['connect_timeout' => 2])->timeout(3)->get($this->baseUrl);
            return $resp->successful();
        } catch (\Exception $e) {
            Log::warning('OllamaService::isServiceReachable failed: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Public health check wrapper for external callers.
     * Returns an array with a boolean 'ok' and some metadata.
     */
    public function healthCheck(): array
    {
        $ok = $this->isServiceReachable();
        return [
            'ok' => $ok,
            'baseUrl' => $this->baseUrl,
            'model' => $this->model,
        ];
    }

    public function chat(array $messages, bool $stream = true)
    {
        // Temporarily honor the provided stream flag for this request
        $prev = $this->stream;
        $this->stream = $stream;
        $resp = $this->sendRequest('chat', [
            'messages' => $messages,
        ]);
        $this->stream = $prev;
        return $resp;
    }

    private function sendRequest(string $endpoint, array $data)
    {
        $data['model'] = $this->model;
        $data['stream'] = $this->stream;
        $data['options'] = [
            'temperature' => 0.1,
            'top_p' => 0.9,
            'num_predict' => 256,
        ];
        $data['format'] = 'json'; // Ensure JSON format for structured output

        try {
            // allow more execution time for this request to the local Ollama model
            if (function_exists('set_time_limit')) {
                set_time_limit(65);
            }

            // Use a connect timeout and overall timeout; include stream option when needed
            // Implement a small retry/backoff policy for transient errors
            $attempts = 0;
            $maxAttempts = 3;
            $response = null;
            $lastException = null;

            while ($attempts < $maxAttempts) {
                try {
                    $attempts++;
                    $response = Http::withOptions(['connect_timeout' => 5, 'stream' => $this->stream])
                        ->timeout(55)
                        ->post("{$this->baseUrl}/api/{$endpoint}", $data);

                    // If we received a response without throwing, break and use it
                    break;
                } catch (\Illuminate\Http\Client\ConnectionException $e) {
                    $lastException = $e;
                    Log::warning("OllamaService sendRequest connection attempt {$attempts} failed: " . $e->getMessage());
                } catch (\Illuminate\Http\Client\RequestException $e) {
                    $lastException = $e;
                    Log::warning("OllamaService sendRequest request attempt {$attempts} failed: " . $e->getMessage());
                } catch (\Exception $e) {
                    $lastException = $e;
                    Log::warning("OllamaService sendRequest unexpected attempt {$attempts} failed: " . $e->getMessage());
                }

                // Exponential backoff (200ms, 500ms, 1000ms)
                $backoffs = [200, 500, 1000];
                $delay = $backoffs[min($attempts - 1, count($backoffs) - 1)];
                usleep($delay * 1000);
            }

            if ($response === null) {
                if ($lastException) {
                    Log::error('OllamaService: all retry attempts failed: ' . $lastException->getMessage());
                } else {
                    Log::error('OllamaService: all retry attempts failed without exception');
                }
                return null;
            }

            if ($response->failed()) {
                Log::error("Ollama API request failed", [
                    'status' => $response->status(),
                    'response' => $response->body(),
                ]);
                return null;
            }

            // Handle streaming and non-streaming responses
            if ($this->stream) {
                // For streaming responses, return the PSR response body resource so callers can stream it.
                try {
                    return $response->toPsrResponse()->getBody();
                } catch (\Exception $e) {
                    Log::warning('Failed to obtain stream body from Ollama response: ' . $e->getMessage());
                    return $response->body();
                }
            } else {
                // The response body is a sequence of JSON objects, decode them
                $jsonResponses = explode("\n", trim($response->body()));
                $decodedResponses = [];
                foreach ($jsonResponses as $jsonResponse) {
                    if (!empty($jsonResponse)) {
                        $decoded = json_decode($jsonResponse, true);
                        if (json_last_error() === JSON_ERROR_NONE) {
                            $decodedResponses[] = $decoded;
                        } else {
                            Log::warning("Failed to decode JSON chunk from Ollama response", ['chunk' => $jsonResponse]);
                        }
                    }
                }

                // If it's a chat response, we want the content of the last message
                if ($endpoint === 'chat' && !empty($decodedResponses)) {
                    $lastResponse = end($decodedResponses);
                    if (isset($lastResponse['message']['content'])) {
                        // The content itself is often a JSON string, so decode it again
                        $structuredContent = json_decode($lastResponse['message']['content'], true);
                        if (json_last_error() === JSON_ERROR_NONE) {
                            return $structuredContent;
                        }
                        // If it's not a valid JSON, return as is
                        return $lastResponse['message']['content'];
                    }
                }
                return $decodedResponses;
            }
        } catch (\Illuminate\Http\Client\ConnectionException $e) {
            Log::error('Ollama connection failed: ' . $e->getMessage());
            return null;
        } catch (\Illuminate\Http\Client\RequestException $e) {
            Log::error('Ollama request error: ' . $e->getMessage(), ['exception' => $e->getMessage()]);
            return null;
        } catch (\Exception $e) {
            Log::error('Unexpected error calling Ollama: ' . $e->getMessage());
            return null;
        }
    }

    public function extractStructuredQuery(string $userQuery, array $userContext): ?array
    {
        $userName = $userContext['user_name'] ?? 'N/A';
        $userRole = $userContext['user_role'] ?? 'N/A';

        $systemPrompt = <<<PROMPT
You are an expert at analyzing user queries for a university attendance system. Your task is to classify the user's intent and extract key entities into a structured JSON object.

The user context is:
- User Name: {$userName}
- User Role: {$userRole}

Based on the user's query, you must identify the `query_category`, `query_type`, and any relevant `entities`.

Possible `query_category` values are:
1.  `attendance`: For questions about attendance records, rates, absences, etc.
2.  `classes`: For questions about class schedules, enrolled classes, or class performance.
3.  `excuses`: For questions about excuse letters, their status, or submission counts.
4.  `general`: For greetings, or questions you cannot classify.

Possible `query_type` values are:
- For `attendance`: `rate`, `count_absences`, `count_presents`, `count_lates`, `list_absences`, `list_records`, `summary`.
- For `classes`: `list_all`, `rank_classes`, `list_details`.
- For `excuses`: `status`.
- For `general`: `greeting`, `fallback`.

Possible `entities` to extract:
- `student_name`: The name of the student being asked about.
- `class_name`: The name or code of the class.
- `time_period`: Can be 'today', 'this week', 'this month', 'this semester', etc. Default to 'this month'.
- `excuse_status`: e.g., 'pending', 'approved', 'rejected'.
- `metric`: For ranking, can be 'attendance' or 'absences'.

Example Scenarios:
- Query: "What is my attendance rate this month?" -> `{"query_category": "attendance", "query_type": "rate", "entities": {"time_period": "this month"}}`
- Query: "Show me my classes." -> `{"query_category": "classes", "query_type": "list_all", "entities": {}}`
- Query: "List all my classes, subject, time, day, and room" -> `{"query_category": "classes", "query_type": "list_details", "entities": {}}`
- Query: "Do I have any pending excuse requests?" -> `{"query_category": "excuses", "query_type": "status", "entities": {"excuse_status": "pending"}}`
- Query: "Which class has the most absences?" -> `{"query_category": "classes", "query_type": "rank_classes", "entities": {"metric": "absences"}}`
- Query: "Show me attendance summary for this week" -> `{"query_category": "attendance", "query_type": "summary", "entities": {"time_period": "this week"}}`

Now, analyze the following user query and provide the JSON output. Do not include any explanations, just the raw JSON.

User Query: "{$userQuery}"
PROMPT;

        $messages = [
            ['role' => 'system', 'content' => $systemPrompt],
            ['role' => 'user', 'content' => $userQuery]
        ];

        // Request a non-streaming chat response (we need a decoded JSON/array)
        $response = $this->chat($messages, false);

        // If sendRequest returned a PSR stream, cast to string and decode
        if ($response instanceof \Psr\Http\Message\StreamInterface) {
            $body = (string)$response;
            $decoded = json_decode($body, true);
            if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
                return $decoded;
            }
            // Try newline-delimited JSON
            $lines = array_filter(array_map('trim', explode("\n", $body)));
            foreach ($lines as $line) {
                $maybe = json_decode($line, true);
                if (json_last_error() === JSON_ERROR_NONE && is_array($maybe)) {
                    return $maybe;
                }
            }
            return null;
        }

        // If response is already an array, return it
        if (is_array($response)) {
            return $response;
        }

        // If response is a string, try to decode JSON
        if (is_string($response)) {
            $decoded = json_decode($response, true);
            if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
                return $decoded;
            }
            $lines = array_filter(array_map('trim', explode("\n", $response)));
            foreach ($lines as $line) {
                $maybe = json_decode($line, true);
                if (json_last_error() === JSON_ERROR_NONE && is_array($maybe)) {
                    return $maybe;
                }
            }
            return null;
        }

        return null;
    }

    public function generateGenericResponse(string $userQuery, string $context = null): string
    {
        if ($context) {
            // Ask the model to rewrite the technical/structured output into cheerful plain language.
            $prompt = "You are 'Attendify Bot', a friendly and cheerful assistant. The user asked: '{$userQuery}'.\n\n" .
                      "Below is a technical or structured answer that may contain JSON, arrays, code, or numeric vectors. Your task: rewrite it into a single friendly, concise, human-readable reply. Do NOT include any code blocks, JSON, or raw numbers-only arrays. Use short sentences or bullet points if needed, and keep a cheerful tone.\n\n" .
                      "Technical output:\n" . $context . "\n\n" .
                      "Friendly rewrite:";
        } else {
            $prompt = "You are a friendly, cheerful, and helpful assistant named 'Attendify Bot'! Always tell the truth. The user asked: '{$userQuery}'. Please provide a fun and helpful response. If you don't know the answer, say it in a funny way.";
        }

        // Use the non-streaming generate method. Ensure we temporarily disable streaming
        $prevStream = $this->stream;
        $this->stream = false;
        $response = $this->sendRequest('generate', ['prompt' => $prompt]);
        // restore previous stream flag
        $this->stream = $prevStream;

        // If response is a PSR stream, cast to string first
        if ($response instanceof \Psr\Http\Message\StreamInterface) {
            $body = (string)$response;
            $lines = array_filter(array_map('trim', explode("\n", $body)));
            $decodedResponses = [];
            foreach ($lines as $line) {
                $decoded = json_decode($line, true);
                if (json_last_error() === JSON_ERROR_NONE) {
                    $decodedResponses[] = $decoded;
                }
            }
            $response = $decodedResponses ?: $body;
        }

        if ($response && is_array($response) && !empty($response[0]['response'])) {
            // Combine chunks
            $fullResponse = array_reduce($response, function ($carry, $item) {
                return $carry . ($item['response'] ?? '');
            }, '');

            // Try to decode; if it's structured, extract a friendly string
            $decoded = json_decode($fullResponse, true);
            if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
                // Common keys to check for human text
                $preferredKeys = ['reply', 'response', 'message', 'text', 'answer'];
                foreach ($preferredKeys as $k) {
                    if (isset($decoded[$k]) && is_string($decoded[$k]) && trim($decoded[$k]) !== '') {
                        return trim($decoded[$k]);
                    }
                    // nested message object
                    if (isset($decoded[$k]) && is_array($decoded[$k]) && isset($decoded[$k]['content']) && is_string($decoded[$k]['content'])) {
                        return trim($decoded[$k]['content']);
                    }
                }

                // If the array has a single string value, return it
                if (count($decoded) === 1) {
                    $val = reset($decoded);
                    if (is_string($val)) return trim($val);
                }

                // Otherwise, build a short human-readable summary
                $parts = [];
                $maxParts = 5;
                foreach ($decoded as $key => $val) {
                    if (is_scalar($val)) {
                        $parts[] = ucfirst(str_replace('_', ' ', $key)) . ': ' . (string)$val;
                    } elseif (is_array($val)) {
                        $parts[] = ucfirst(str_replace('_', ' ', $key)) . ': ' . (is_string(@reset($val)) ? (string)@reset($val) : count($val) . ' items');
                    } else {
                        $parts[] = ucfirst(str_replace('_', ' ', $key)) . ': (complex data)';
                    }
                    if (count($parts) >= $maxParts) break;
                }
                if (!empty($parts)) {
                    return "Sure — " . implode('. ', $parts) . '.';
                }
            }

            return trim($fullResponse);
        }

        return "I'm sorry, I couldn't generate a friendly response for that question.";
    }

    public function streamGenerate(string $prompt)
    {
        if (!$this->isServiceReachable()) {
            return function () {
                yield json_encode(['error' => 'AI service unreachable']);
            };
        }
        $data = [
            'model' => $this->model,
            'prompt' => $prompt,
            'stream' => true,
        ];

        return function () use ($data) {
            try {
                if (function_exists('set_time_limit')) {
                    set_time_limit(120);
                }

                $response = Http::withOptions(['stream' => true, 'connect_timeout' => 5])
                    ->timeout(115)
                    ->post("{$this->baseUrl}/api/generate", $data);

                if ($response->failed()) {
                    Log::error("Ollama API stream request failed", ['status' => $response->status()]);
                    yield json_encode(['error' => 'Failed to connect to AI service.']);
                    return;
                }

                $stream = $response->toPsrResponse()->getBody();

                while (!$stream->eof()) {
                    $line = stream_get_line($stream, 1024, "\n");
                    if (trim($line) !== '') {
                        $decoded = json_decode($line, true);
                        if (json_last_error() === JSON_ERROR_NONE && isset($decoded['response'])) {
                            yield $decoded['response'];
                        }
                    }
                }
            } catch (\Exception $e) {
                Log::error('Ollama stream connection failed: ' . $e->getMessage());
                yield json_encode(['error' => 'A streaming error occurred.']);
            }
        };
    }


    public function formatResponse(string $queryCategory, string $queryType, $data, string $userQuery): string
    {
        if ($data === null || (is_array($data) && isset($data['error']))) {
            return $this->generateSqlQuery($userQuery);
        }

        switch ($queryCategory) {
            case 'attendance':
                return $this->formatAttendanceResponse($queryType, $data);
            case 'classes':
                return $this->formatClassResponse($queryType, $data);
            case 'excuses':
                return $this->formatExcuseResponse($queryType, $data);
            case 'general':
                if ($queryType === 'greeting') {
                    return 'Hello there! Your friendly neighborhood Attendify Bot, at your service! What can I help you with today?';
                }
                // For fallback, we will now generate a SQL query
                return $this->generateSqlQuery($userQuery);
            default:
                return "Well, this is awkward. I'm not quite sure how to handle that category. My developers are probably working on it as we speak... hopefully!";
        }
    }

    /**
     * Ask the model to generate a READ-ONLY SELECT SQL query for the user's request.
     * For student users the model MUST use the placeholder `:student_id` to scope results.
     */
    public function generateSelectQuery(string $userQuery, array $userContext): ?string
    {
        $userRole = $userContext['user_role'] ?? 'unknown';
        $studentNote = '';
        if ($userRole === 'student') {
            $studentNote = "\nMUST use the parameter placeholder :student_id to scope results to the logged-in student. Do NOT inline or return raw student ids.";
        }
        if ($userRole === 'teacher') {
            $studentNote = "\nMUST use the parameter placeholder :teacher_id to scope results to the logged-in teacher. Do NOT inline or return raw teacher ids.";
        }

        $schema = "users(id,name,email,role,telegram_user_id,telegram_chat_id),\n" .
                  "students(id,student_id,name,email,year,course,section,phone,is_active),\n" .
                  "teachers(id,user_id,teacher_id,first_name,last_name,email,phone,department),\n" .
                  "class_models(id,name,subject,schedule_time,schedule_days,room,teacher_id),\n" .
                  "attendance_records(id,attendance_session_id,student_id,status,marked_at,marked_by,notes),\n" .
                  "attendance_sessions(id,teacher_id,class_id,session_name,session_date,start_time,end_time,status,notes,qr_code),\n" .
                  "excuse_requests(id,student_id,attendance_session_id,reason,attachment_path,status,submitted_at)
                  ";

        $prompt = "You are an expert SQL generator. Generate a READ-ONLY SQL SELECT query to answer the user's question based on the provided schema. " .
                  "STRICTLY PROHIBIT any destructive SQL (INSERT, UPDATE, DELETE, DROP, ALTER, TRUNCATE, CREATE). " .
                  "Return only the SQL statement and nothing else." . $studentNote . "\n\nSchema:\n{$schema}\n\nUser Question: {$userQuery}";

        $prevStream = $this->stream;
        $this->stream = false;
        $response = $this->sendRequest('generate', ['prompt' => $prompt]);
        $this->stream = $prevStream;

        if ($response instanceof \Psr\Http\Message\StreamInterface) {
            $body = (string)$response;
            $lines = array_filter(array_map('trim', explode("\n", $body)));
            $decodedResponses = [];
            foreach ($lines as $line) {
                $decoded = json_decode($line, true);
                if (json_last_error() === JSON_ERROR_NONE) {
                    $decodedResponses[] = $decoded;
                }
            }
            $response = $decodedResponses ?: $body;
        }

        if ($response && is_array($response) && !empty($response[0]['response'])) {
            $fullResponse = array_reduce($response, function ($carry, $item) {
                return $carry . ($item['response'] ?? '');
            }, '');
            return trim($fullResponse);
        }

        return null;
    }

    /**
     * Very conservative check to ensure SQL is read-only and (for students) uses the required placeholder.
     * This is not a full-proof parser — for production use a real SQL parser/whitelist should be used.
     */
    public function isSafeReadOnlySql(string $sql, array $userContext = []): bool
    {
        if (empty($sql)) {
            return false;
        }

        // Single statement and must start with SELECT
        if (!preg_match('/^\s*select\b/i', $sql)) {
            return false;
        }

        // Forbid modification keywords and statement separators
        if (preg_match('/\b(insert|update|delete|drop|alter|truncate|create|replace|merge)\b/i', $sql) || strpos($sql, ';') !== false) {
            return false;
        }

        // If the user is a student, require the placeholder :student_id to be present
        if (($userContext['user_role'] ?? '') === 'student') {
            if (stripos($sql, ':student_id') === false) {
                return false;
            }
            // Also require a WHERE clause (basic check)
            if (!preg_match('/\bwhere\b/i', $sql)) {
                return false;
            }
        }

        // If the user is a teacher, require the placeholder :teacher_id to be present
        if (($userContext['user_role'] ?? '') === 'teacher') {
            if (stripos($sql, ':teacher_id') === false) {
                return false;
            }
            if (!preg_match('/\bwhere\b/i', $sql)) {
                return false;
            }
        }

        // Basic allowed table check (scan FROM and JOIN clauses)
        $allowedTables = ['users','students','teachers','class_models','attendance_records','attendance_sessions','excuse_requests','class_student','classes'];
        preg_match_all('/\bfrom\s+`?([a-z0-9_]+)`?|\bjoin\s+`?([a-z0-9_]+)`?/i', $sql, $matches);
        $found = array_filter(array_merge($matches[1] ?? [], $matches[2] ?? []));
        foreach ($found as $tbl) {
            $tbl = strtolower($tbl);
            if (!in_array($tbl, $allowedTables, true)) {
                return false;
            }
        }

        return true;
    }

    private function formatAttendanceResponse(string $queryType, $data): string
    {
        $scope = $data['scope'] ?? 'your';
        $period = isset($data['period']) ? str_replace('_', ' ', $data['period']) : 'the specified period';

        switch ($queryType) {
            case 'rate':
                $rateRaw = $data['attendance_rate'] ?? 0;
                $rate = number_format((float)$rateRaw, 2);
                return "Alright, crunching the numbers... and voilà! The attendance rate {$scope} for {$period} is a spectacular {$rate}%.";
            case 'count_presents':
                $count = $data['present_count'] ?? 0;
                return "Huzzah! I've counted {$count} presents recorded {$scope} during {$period}. Keep up the great work!";
            case 'count_absences':
                $count = $data['absence_count'] ?? ($data['absent_count'] ?? 0);
                return "Oh dear. It looks like there are {$count} absences recorded {$scope} during {$period}. Let's try to get that number down!";
            case 'count_lates':
                $count = $data['late_count'] ?? 0;
                return "Tick-tock! I found {$count} lates recorded {$scope} during {$period}. Every minute counts!";
            case 'list_absences':
            case 'list_records':
                if (empty($data['records']) || !is_array($data['records'])) {
                    return "Success! I searched high and low and found... zero records {$scope} for {$period}. A clean slate!";
                }
                $response = "Okay, here are the records I dug up {$scope} for {$period}:\\n";
                foreach ($data['records'] as $record) {
                    // Support object or associative array
                    $createdAt = $record->created_at ?? ($record['created_at'] ?? null);
                    $studentName = $record->student_name ?? ($record['student_name'] ?? 'Unknown');
                    $status = $record->status ?? ($record['status'] ?? 'unknown');
                    try {
                        $date = $createdAt ? Carbon::parse($createdAt)->format('F j, Y') : 'an unknown date';
                    } catch (\Exception $e) {
                        $date = 'an unknown date';
                    }
                    $response .= "- {$studentName} was {$status} on {$date}\\n";
                }
                return $response;
            case 'summary':
                $present = $data['present_count'] ?? ($data['present'] ?? 0);
                $absent = $data['absent_count'] ?? ($data['absence_count'] ?? ($data['absence'] ?? 0));
                $late = $data['late_count'] ?? 0;
                return "Here is the grand summary of attendance {$scope} for {$period}:\\n- Present and accounted for: {$present}\\n- Playing hide and seek (Absent): {$absent}\\n- Fashionably late: {$late}";
            default:
                return "I've got the attendance data, but my circuits are a bit scrambled on how to show it to you. Ask me in a different way, perhaps?";
        }
    }

    private function formatClassResponse(string $queryType, $data): string
    {
        switch ($queryType) {
            case 'list_all':
            case 'list_details':
                if (empty($data['classes'])) {
                    return "It seems you're not enrolled in any classes! Either that or they're playing hide and seek. And winning.";
                }
                $response = "Behold! Your magnificent list of classes:\\n";
                foreach ($data['classes'] as $class) {
                    $response .= "- {$class->name}";
                    if (isset($class->subject)) {
                        $response .= " ({$class->subject})";
                    }
                    // support schedule_days (array) or schedule (string)
                    if (isset($class->schedule) && !empty($class->schedule)) {
                        if (is_array($class->schedule)) {
                            $days = implode(', ', $class->schedule);
                        } else {
                            $days = $class->schedule;
                        }
                        $response .= " on {$days} at {$class->schedule_time}";
                    }
                    if (isset($class->room)) {
                        $response .= " in room {$class->room}";
                    }
                    $response .= "\\n";
                }
                return $response;
            case 'rank_classes':
                if (empty($data['classes'])) {
                    return "I tried to rank the classes for {$data['period']}, but it seems there's no data to rank. Maybe they're all perfectly tied?";
                }
                $metric = $data['metric'] === 'absences' ? 'absences' : 'attendance rate';
                $response = "Let the games begin! Here are the top classes by {$metric} for {$data['period']}:\\n";
                foreach ($data['classes'] as $class) {
                    $value = $data['metric'] === 'absences' ? (int)$class->metric_value : number_format($class->metric_value, 2) . '%';
                    $response .= "- {$class->name}: {$value}\\n";
                }
                return $response;
            default:
                return "I have some class data, but I'm not quite sure how to arrange it for you. Could you rephrase your request?";
        }
    }

    private function formatExcuseResponse(string $queryType, $data): string
    {
        $scope = $data['scope'] ?? 'your';
        $status = $data['status'] ?? 'all';
        $count = $data['count'] ?? 0;

        if ($count === 0) {
            return "Great news! There are absolutely zero {$status} excuse requests {$scope}. Nothing to see here!";
        }

        $response = "I've found {$count} {$status} excuse request(s) {$scope}. Here are the latest details:\\n";
        if (!empty($data['records'])) {
            foreach ($data['records'] as $excuse) {
                $date = Carbon::parse($excuse->created_at)->format('F j, Y');
                $response .= "- For {$excuse->student_name} on {$date} ({$excuse->status})\\n";
            }
        }
        return $response;
    }

    public function generateSqlQuery(string $userQuery): string
    {
        $schema = <<<SCHEMA
        **users**
        - id
        - name
        - email
        - role
        - telegram_user_id
        - telegram_chat_id

        **students**
        - id
        - student_id
        - name
        - email
        - year
        - course
        - section
        - phone
        - is_active

        **teachers**
        - id
        - user_id
        - teacher_id
        - first_name
        - last_name
        - email
        - phone
        - department

        **class_models**
        - id
        - name
        - subject
        - schedule_time
        - schedule_days
        - room
        - teacher_id

        **attendance_records**
        - id
        - attendance_session_id
        - student_id
        - status
        - marked_at

        **excuse_requests**
        - id
        - student_id
        - attendance_session_id
        - reason
        - status
        - submitted_at
        SCHEMA;

        $prompt = "You are an expert SQL generator. Your task is to generate a read-only SQL query to answer the user's
         question based on the provided database schema.\n\n**IMPORTANT RULE:** You are strictly prohibited from 
         generating any queries that modify the database. This includes, but is not limited to, `UPDATE`, `DELETE`,
          `INSERT`, `DROP`, `ALTER`, `TRUNCATE`. You can only generate `SELECT` queries. Any attempt to generate a 
          destructive query will be rejected.\n\nBased on the following database schema, please generate a SQL query 
          that answers the user's question. Only return the SQL query, with no additional text or explanations.\n\nSchema:\n{$schema}\n\nUser Question: {$userQuery}";

        $prevStream = $this->stream;
        $this->stream = false;
        $response = $this->sendRequest('generate', ['prompt' => $prompt]);
        $this->stream = $prevStream;

        if ($response instanceof \Psr\Http\Message\StreamInterface) {
            $body = (string)$response;
            $lines = array_filter(array_map('trim', explode("\n", $body)));
            $decodedResponses = [];
            foreach ($lines as $line) {
                $decoded = json_decode($line, true);
                if (json_last_error() === JSON_ERROR_NONE) {
                    $decodedResponses[] = $decoded;
                }
            }
            $response = $decodedResponses ?: $body;
        }

        if ($response && is_array($response) && !empty($response[0]['response'])) {
            $fullResponse = array_reduce($response, function ($carry, $item) {
                return $carry . ($item['response'] ?? '');
            }, '');
            return trim($fullResponse);
        }

        return "I'm sorry, I couldn't generate a SQL query for that question.";
    }
}