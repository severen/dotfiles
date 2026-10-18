import { randomUUID } from "node:crypto";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// SiteHost AI Platform: https://kb.sitehost.nz/ai-platform/the-api
const BASE_URL = "https://ai.sitehost.nz/v1";
const KEY_ENV = "SITEHOST_AI_API_KEY";

// /v1/models only returns ids, so known metadata lives here.
// Cost is per million tokens, in NZD (SiteHost bills in NZD; Pi just displays the number).
const KNOWN: Record<string, Partial<ModelDef>> = {
  // "Qwen/Qwen3.6-27B": {
  //   name: "Qwen 3.6 27B (SiteHost NZ)",
  //   input: ["text", "image"],
  //   reasoning: true,
  //   contextWindow: 262144,
  //   maxTokens: 32768,
  //   cost: { input: 0.28, output: 2.76, cacheRead: 0.04, cacheWrite: 0 },
  //   // vLLM toggles Qwen thinking via chat_template_kwargs.enable_thinking,
  //   // so Pi's thinking level (incl. "off") actually reaches the model.
  //   compat: { thinkingFormat: "qwen-chat-template" },
  // },
  "Qwen/Qwen3.8-27B": {
    name: "Qwen 3.8 27B (SiteHost NZ)",
    input: ["text", "image"],
    reasoning: true,
    contextWindow: 262144,
    maxTokens: 32768,
    cost: { input: 0.28, output: 2.76, cacheRead: 0.04, cacheWrite: 0 },
    // Qwen 3.8's template reads both enable_thinking and reasoning_effort (low, medium,
    // xhigh) as template variables, so send them together via chat_template_kwargs.
    compat: {
      thinkingFormat: "chat-template",
      chatTemplateKwargs: {
        enable_thinking: { $var: "thinking.enabled" },
        reasoning_effort: { $var: "thinking.effort", omitWhenOff: true },
        preserve_thinking: true,
      },
    },
    thinkingLevelMap: {
      minimal: null,
      low: "low",
      medium: "medium",
      high: null,
      xhigh: "xhigh",
      max: null,
    },
  },
};

// Fallback for generative models SiteHost adds later.
const DEFAULTS: Omit<ModelDef, "id" | "name"> = {
  input: ["text"],
  reasoning: false,
  contextWindow: 128000,
  maxTokens: 16384,
  cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
};

// The models endpoint also lists embedding and reranking models, which Pi can't chat with.
const NON_CHAT = /embed|rerank/i;

type ModelDef = {
  id: string;
  name: string;
  input: ("text" | "image")[];
  reasoning: boolean;
  contextWindow: number;
  maxTokens: number;
  cost: {
    input: number;
    output: number;
    cacheRead: number;
    cacheWrite: number;
  };
  compat?: Record<string, unknown>;
  thinkingLevelMap?: Record<string, string | null>;
};

// vLLM backend: Qwen's chat template has no "developer" role, and thinking is
// controlled through chat_template_kwargs (per model) rather than reasoning_effort.
// Pi only reads compat per model, so every model gets this merged under its own.
const BASE_COMPAT = {
  supportsDeveloperRole: false,
  supportsReasoningEffort: false,
};

function toModel(id: string): ModelDef {
  const known = KNOWN[id];
  return {
    id,
    name: id,
    ...DEFAULTS,
    ...known,
    compat: { ...BASE_COMPAT, ...known?.compat },
  } as ModelDef;
}

export default function (pi: ExtensionAPI) {
  pi.registerProvider("sitehost", {
    name: "SiteHost AI",
    baseUrl: BASE_URL,
    apiKey: `$${KEY_ENV}`,
    api: "openai-completions",
    // SiteHost routes to the least-loaded backend; a stable session ID pins requests
    // to one backend so its prompt cache gets reused. One ID per Pi process.
    headers: { "X-Session-ID": randomUUID() },

    // Seed list so the provider works offline / before the first refresh.
    models: Object.keys(KNOWN).map(toModel),

    async refreshModels({ signal, credential }) {
      // Pi resolves auth (auth.json from /login, then env) before calling this,
      // so prefer the credential it hands us over reading the environment ourselves.
      const key =
        (credential?.type === "api_key" ? credential.key : undefined) ??
        process.env[KEY_ENV];

      // No key yet: keep the seed list rather than failing the sync.
      if (!key) return Object.keys(KNOWN).map(toModel);

      const res = await fetch(`${BASE_URL}/models`, {
        headers: { Authorization: `Bearer ${key}` },
        signal,
      });
      if (!res.ok)
        throw new Error(`SiteHost /v1/models failed: HTTP ${res.status}`);

      const { data } = (await res.json()) as { data: Array<{ id: string }> };
      return data
        .map((m) => m.id)
        .filter((id) => !NON_CHAT.test(id))
        .map(toModel);
    },
  });
}
