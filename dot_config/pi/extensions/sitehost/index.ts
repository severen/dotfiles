import type {
  ExtensionAPI,
  ProviderModelConfig,
} from "@earendil-works/pi-coding-agent";

type ChatModelConfig = Extract<ProviderModelConfig, { type?: "chat" }>;

// SiteHost AI Platform: https://kb.sitehost.nz/ai-platform/the-api
const BASE_URL = "https://ai.sitehost.nz/v1";

/**
 * A regular expression that matches the IDs of models that Pi can't chat with,
 * so that model discovery can skip them. Because `/v1/models` also lists
 * embedding and reranking models and returns only IDs, the model name is the
 * only way to tell them apart.
 */
const NON_CHAT = /embed|rerank/i;

const DEFAULT_CONFIG: Omit<ChatModelConfig, "id" | "name"> = {
  input: ["text"],
  reasoning: false,
  contextWindow: 128000,
  maxTokens: 16384,
  cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
  // Add an `X-Session-ID` header containing the session ID to each API request
  // so that that subsequent requests in the same session are routed to the same
  // backend. Doing so ensures that the prompt cache can be reused.
  compat: {
    sendSessionAffinityHeaders: true,
    sessionAffinityFormat: "openrouter",
  },
};

const CONFIGS: Record<string, Partial<ChatModelConfig>> = {
  "deepseek/DeepSeek-V4.1-Flash": {
    name: "DeepSeek V4.1 Flash (SiteHost NZ)",
    input: ["text", "image"],
    reasoning: true,
    contextWindow: 1048576,
    maxTokens: 131072,
    cost: { input: 0.68, output: 7.55, cacheRead: 0.12, cacheWrite: 0 },
    // DeepSeek accepts none, low, high, xhigh, and max, and rejects medium.
    thinkingLevelMap: {
      off: "none",
      minimal: null,
      low: "low",
      medium: null,
      high: "high",
      xhigh: "xhigh",
      max: "max",
    },
  },
  "Qwen/Qwen3.8-27B": {
    name: "Qwen 3.8 27B (SiteHost NZ)",
    input: ["text", "image"],
    reasoning: true,
    contextWindow: 262144,
    maxTokens: 32768,
    cost: { input: 0.28, output: 2.62, cacheRead: 0.04, cacheWrite: 0 },
    // Qwen 3.8 accepts low, medium and xhigh, and rejects anything else.
    thinkingLevelMap: {
      off: "none",
      minimal: null,
      low: "low",
      medium: "medium",
      high: null,
      xhigh: "xhigh",
      max: null,
    },
  },
};

export default function (pi: ExtensionAPI) {
  pi.registerProvider("sitehost", {
    name: "SiteHost AI",
    baseUrl: BASE_URL,
    api: "openai-completions",
    models: Object.keys(CONFIGS).map(toModel),

    async refreshModels({ signal, credential }) {
      // If not logged in yet, just return the models we know already.
      if (credential?.type !== "api_key") {
        return Object.keys(CONFIGS).map(toModel);
      }

      const res = await fetch(`${BASE_URL}/models`, {
        headers: { Authorization: `Bearer ${credential.key}` },
        signal,
      });
      if (!res.ok) {
        throw new Error(`SiteHost /v1/models failed: HTTP ${res.status}`);
      }

      const { data } = (await res.json()) as { data: Array<{ id: string }> };
      return data
        .map((m) => m.id)
        .filter((id) => !NON_CHAT.test(id))
        .map(toModel);
    },
  });
}

function toModel(id: string): ChatModelConfig {
  return { id, name: id, ...DEFAULT_CONFIG, ...CONFIGS[id] };
}
