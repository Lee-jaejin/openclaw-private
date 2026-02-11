/**
 * Model Router Plugin
 *
 * Automatically routes requests to the most appropriate model
 * based on task classification (coding, reasoning, general).
 */

export interface ModelConfig {
  coding: string;
  reasoning: string;
  general: string;
}

export interface RouterOptions {
  models?: Partial<ModelConfig>;
  debug?: boolean;
}

const DEFAULT_MODELS: ModelConfig = {
  coding: "ollama/starcoder2:15b",
  reasoning: "ollama/phi4:14b",
  general: "ollama/gpt-oss:20b",
};

// Keywords for task classification
const CODING_KEYWORDS = [
  // English
  "code",
  "function",
  "bug",
  "debug",
  "refactor",
  "implement",
  "class",
  "method",
  "variable",
  "error",
  "compile",
  "syntax",
  "api",
  "endpoint",
  "database",
  "query",
  "test",
  "unit test",
  // Korean
  "코드",
  "함수",
  "버그",
  "디버그",
  "리팩토링",
  "구현",
  "클래스",
  "메서드",
  "변수",
  "에러",
  "컴파일",
  "문법",
];

const REASONING_KEYWORDS = [
  // English
  "why",
  "analyze",
  "compare",
  "explain",
  "reason",
  "logic",
  "think",
  "evaluate",
  "pros and cons",
  "trade-off",
  "decision",
  "strategy",
  // Korean
  "왜",
  "분석",
  "비교",
  "설명",
  "이유",
  "논리",
  "생각",
  "평가",
  "장단점",
  "트레이드오프",
  "결정",
  "전략",
];

export type TaskType = "coding" | "reasoning" | "general";

/**
 * Classify the task type based on message content
 */
export function classifyTask(message: string): TaskType {
  const lowerMessage = message.toLowerCase();

  // Check for coding keywords
  if (CODING_KEYWORDS.some((kw) => lowerMessage.includes(kw.toLowerCase()))) {
    return "coding";
  }

  // Check for reasoning keywords
  if (REASONING_KEYWORDS.some((kw) => lowerMessage.includes(kw.toLowerCase()))) {
    return "reasoning";
  }

  return "general";
}

/**
 * Select the appropriate model based on message content
 */
export function selectModel(
  message: string,
  options: RouterOptions = {}
): string {
  const models = { ...DEFAULT_MODELS, ...options.models };
  const taskType = classifyTask(message);

  if (options.debug) {
    console.log(`[model-router] Task type: ${taskType}`);
    console.log(`[model-router] Selected model: ${models[taskType]}`);
  }

  return models[taskType];
}

/**
 * Create a model router with custom configuration
 */
export function createModelRouter(options: RouterOptions = {}) {
  const models = { ...DEFAULT_MODELS, ...options.models };

  return {
    selectModel: (message: string) => selectModel(message, options),
    classifyTask,
    models,
  };
}

// Export default router
export default createModelRouter();
