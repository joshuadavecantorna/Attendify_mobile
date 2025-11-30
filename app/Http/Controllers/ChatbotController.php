<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\StreamedResponse;
use Inertia\Inertia;
use Inertia\Response;
use App\Services\UserContextBuilder;
use App\Services\RetrievalPlanner;
use App\Services\AIComposer;
use App\Services\OllamaService;
use App\Services\AIQueryService;

class ChatbotController extends Controller
{
    protected UserContextBuilder $contextBuilder;
    protected RetrievalPlanner $retrievalPlanner;
    protected AIComposer $composer;
    protected OllamaService $ollamaService;
    protected AIQueryService $aiQueryService;

    public function __construct(
        UserContextBuilder $contextBuilder,
        RetrievalPlanner $retrievalPlanner,
        AIComposer $composer,
        OllamaService $ollamaService,
        AIQueryService $aiQueryService
    ) {
        $this->contextBuilder = $contextBuilder;
        $this->retrievalPlanner = $retrievalPlanner;
        $this->composer = $composer;
        $this->ollamaService = $ollamaService;
        $this->aiQueryService = $aiQueryService;
    }

    /**
     * Return AI service health status.
     */
    public function status()
    {
        try {
            $health = $this->ollamaService->healthCheck();
            return response()->json(['ai' => $health], 200);
        } catch (\Exception $e) {
            Log::error('ChatbotController::status error', ['error' => $e->getMessage()]);
            return response()->json(['ai' => ['ok' => false, 'error' => 'health check failed']], 503);
        }
    }

    /**
     * Display the chatbot view.
     */
    public function index(): Response
    {
        return Inertia::render('Chatbot/Index');
    }

    /**
     * Handle a user query and return a standard response using the Hybrid AI pipeline.
     */
    public function queryRequest(Request $request)
    {
        $request->validate([
            'message' => 'required|string|max:2000',
        ]);

        $user = Auth::user();
        if (!$user) {
            return response()->json(['error' => 'Unauthenticated.'], 401);
        }

        $userQuery = $request->input('message');

        try {
            // 1. Static cached user context
            $cachedContext = $this->contextBuilder->build($user->id);

            // Validate access: ensure role-derived identifiers exist
            if (($cachedContext['role'] ?? null) === 'student' && empty($cachedContext['student_id'])) {
                return response()->json(['error' => 'Student context missing or access denied.'], 403);
            }
            if (($cachedContext['role'] ?? null) === 'teacher' && empty($cachedContext['teacher_id'])) {
                return response()->json(['error' => 'Teacher context missing or access denied.'], 403);
            }

            // 2. Dynamic retrieval plan + results
            $retrieval = $this->retrievalPlanner->planAndExecute($userQuery, $cachedContext);

            // 3. Compose final prompt for the AI model
            $prompt = $this->composer->compose($cachedContext, $retrieval, $userQuery);

            // 4. Send to Ollama synchronously and return response
            $resp = $this->ollamaService->generate($prompt, false);

            // Normalize response to string
            $output = null;
            if (is_array($resp)) {
                $parts = array_map(function ($p) {
                    if (is_array($p) && isset($p['response'])) return $p['response'];
                    if (is_string($p)) return $p;
                    return json_encode($p);
                }, $resp);
                $output = implode('', $parts);
            } elseif (is_string($resp)) {
                $output = $resp;
            } elseif (is_object($resp) && method_exists($resp, '__toString')) {
                $output = (string) $resp;
            } else {
                $output = json_encode($resp);
            }

            // If the model returned raw JSON, code, or numeric sequences, prefer to render
            // a friendly natural-language response using the retrieval results or by asking
            // the model to rephrase into plain cheerful English.
            $decoded = json_decode($output, true);
            $looksStructured = (json_last_error() === JSON_ERROR_NONE && $decoded !== null);
            // Detect outputs that are purely numeric sequences or simple JSON-like arrays/objects
            $looksNumericSequence = preg_match('/^[0-9,\s\[\]\{\}\":]+$/', trim($output));
            $containsCodeFence = (stripos($output, '```') !== false) || (strpos($output, '`') !== false && preg_match('/`[^`]+`/', $output));
            $containsJsonLike = (strpos($output, '{') !== false && strpos($output, '}') !== false) || (strpos($output, '[') !== false && strpos($output, ']') !== false);

            if ($looksStructured || $looksNumericSequence || $containsCodeFence || $containsJsonLike) {
                // Map retrieval intent to a reasonable query type for formatting
                $intent = $retrieval['intent'] ?? 'general';
                switch ($intent) {
                    case 'attendance':
                        $qType = 'summary';
                        break;
                    case 'schedule':
                        $qType = 'list_details';
                        break;
                    case 'teacher':
                        $qType = 'list_details';
                        break;
                    case 'subjects':
                        $qType = 'list_all';
                        break;
                    default:
                        $qType = 'fallback';
                        break;
                }

                try {
                    $friendly = $this->ollamaService->formatResponse($intent, $qType, $retrieval['results'] ?? $decoded, $userQuery);
                    if (!empty($friendly)) {
                        $output = $friendly;
                    }
                } catch (\Exception $e) {
                    Log::warning('Failed to format structured response: ' . $e->getMessage());
                }
            }

            // If output still looks technical (contains backticks, JSON-like braces, or code fences), ask the model
            // to rephrase into cheerful plain-language before returning to the user.
            $stillLooksTechnical = (stripos($output, '```') !== false)
                || preg_match('/\{\s*"[a-z0-9_]+"\s*:\s*/i', $output)
                || preg_match('/^\s*\[\s*[0-9\s,]+\s*\]/', trim($output));

            if ($stillLooksTechnical) {
                try {
                    $rewritten = $this->ollamaService->generateGenericResponse($userQuery, $output);
                    if (!empty($rewritten)) {
                        $output = $rewritten;
                    }
                } catch (\Exception $e) {
                    Log::warning('Failed to rephrase technical output: ' . $e->getMessage());
                }
            }

            return response()->json([
                'reply' => $output,
                'retrieval' => $retrieval['plan'] ?? null,
            ]);
        } catch (\Exception $e) {
            Log::error('ChatbotController::queryRequest error', ['error' => $e->getMessage(), 'trace' => $e->getTraceAsString()]);
            return response()->json(['error' => 'Internal server error'], 500);
        }
    }


    /**
     * Handle a user query and stream the response using the Hybrid AI pipeline.
     */
    public function streamChat(Request $request)
    {
        set_time_limit(120);

        $request->validate(['query' => 'required|string|max:2000']);

        $user = Auth::user();
        if (!$user) {
            return response()->json(['error' => 'Unauthenticated.'], 401);
        }

        $userQuery = $request->input('query');

        try {
            $cachedContext = $this->contextBuilder->build($user->id);

            // Validate access before streaming
            if (($cachedContext['role'] ?? null) === 'student' && empty($cachedContext['student_id'])) {
                return new StreamedResponse(function () {
                    echo json_encode(['error' => 'Student context missing or access denied.']);
                });
            }
            if (($cachedContext['role'] ?? null) === 'teacher' && empty($cachedContext['teacher_id'])) {
                return new StreamedResponse(function () {
                    echo json_encode(['error' => 'Teacher context missing or access denied.']);
                });
            }

            $retrieval = $this->retrievalPlanner->planAndExecute($userQuery, $cachedContext);
            $prompt = $this->composer->compose($cachedContext, $retrieval, $userQuery);

            $streamSource = $this->ollamaService->streamGenerate($prompt);
            $generator = is_callable($streamSource) ? $streamSource() : $streamSource;

            $response = new StreamedResponse(function () use ($generator) {
                try {
                    foreach ($generator as $chunk) {
                        $out = is_string($chunk) ? $chunk : json_encode($chunk);
                        echo $out;
                        @ob_flush();
                        @flush();
                    }
                } catch (\Throwable $e) {
                    Log::error('ChatbotController::streamChat iteration error', ['error' => $e->getMessage()]);
                    echo json_encode(['error' => 'Streaming failed.']);
                }
            });

            $response->headers->set('Content-Type', 'text/event-stream');
            $response->headers->set('Cache-Control', 'no-cache');
            $response->headers->set('X-Accel-Buffering', 'no');

            return $response;
        } catch (\Exception $e) {
            Log::error('ChatbotController::streamChat error', ['error' => $e->getMessage(), 'trace' => $e->getTraceAsString()]);
            return new StreamedResponse(function () {
                echo json_encode(['error' => 'Internal server error']);
            });
        }
    }

    private function sendStreamChunk(string $chunk)
    {
        echo "data: " . json_encode(['response' => $chunk]) . "\n\n";
    }

    private function executeParameterizedQuery(string $sql, array $bindings = []): array
    {
        $pdo = \Illuminate\Support\Facades\DB::getPdo();
        try {
            $stmt = $pdo->prepare($sql);

            // PDO expects parameter array keys without leading colon
            $params = [];
            foreach ($bindings as $k => $v) {
                $name = ltrim($k, ':');
                $params[$name] = $v;
            }

            $stmt->execute($params);
            $results = $stmt->fetchAll(\PDO::FETCH_OBJ);
            return $results ?: [];
        } catch (\Exception $e) {
            Log::error('Query execution failed: ' . $e->getMessage(), ['sql' => $sql]);
            return [];
        }
    }

    private function _getUserContext(): array
    {
        $user = Auth::user();
        $context = [
            'user_id' => $user->id,
            'user_name' => $user->name,
            'user_role' => $user->role,
        ];

        if ($user->role === 'student' && $user->student) {
            $context['student_id'] = $user->student->id;
        } elseif ($user->role === 'teacher' && $user->teacher) {
            $context['teacher_id'] = $user->teacher->id;
        }

        return $context;
    }
}