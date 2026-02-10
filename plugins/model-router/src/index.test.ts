import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { classifyTask, selectModel, createModelRouter } from "./index.js";
import type { RouterOptions } from "./index.js";

describe("classifyTask", () => {
  describe("coding keywords (English)", () => {
    const codingInputs = [
      "Fix the bug in login",
      "Write a function to sort arrays",
      "Refactor this class",
      "Debug the compile error",
      "Implement the API endpoint",
      "Write a unit test for this method",
      "The database query is slow",
    ];

    for (const input of codingInputs) {
      it(`"${input}" → coding`, () => {
        assert.equal(classifyTask(input), "coding");
      });
    }
  });

  describe("coding keywords (Korean)", () => {
    const codingInputs = [
      "이 코드 수정해줘",
      "함수 하나 만들어줘",
      "버그 찾아줘",
      "디버그 좀 해줘",
      "리팩토링 필요해",
      "이 클래스 구현해줘",
      "변수 이름 바꿔줘",
      "에러 원인이 뭐야",
    ];

    for (const input of codingInputs) {
      it(`"${input}" → coding`, () => {
        assert.equal(classifyTask(input), "coding");
      });
    }
  });

  describe("reasoning keywords (English)", () => {
    const reasoningInputs = [
      "Why does this happen?",
      "Analyze the performance",
      "Compare these two approaches",
      "Explain how it works",
      "Evaluate the pros and cons",
      "What's the best strategy?",
      "Help me make a decision",
    ];

    for (const input of reasoningInputs) {
      it(`"${input}" → reasoning`, () => {
        assert.equal(classifyTask(input), "reasoning");
      });
    }
  });

  describe("reasoning keywords (Korean)", () => {
    const reasoningInputs = [
      "왜 이렇게 되는 거야?",
      "분석 좀 해줘",
      "두 가지 비교해줘",
      "설명해줘",
      "장단점이 뭐야",
      "전략을 세워줘",
    ];

    for (const input of reasoningInputs) {
      it(`"${input}" → reasoning`, () => {
        assert.equal(classifyTask(input), "reasoning");
      });
    }
  });

  describe("general (no keyword match)", () => {
    const generalInputs = [
      "Hello",
      "Tell me a joke",
      "What time is it?",
      "안녕하세요",
      "오늘 날씨 어때?",
      "번역해줘",
    ];

    for (const input of generalInputs) {
      it(`"${input}" → general`, () => {
        assert.equal(classifyTask(input), "general");
      });
    }
  });

  it("is case-insensitive", () => {
    assert.equal(classifyTask("DEBUG this"), "coding");
    assert.equal(classifyTask("ANALYZE this"), "reasoning");
  });

  it("coding takes priority over reasoning", () => {
    // "code" (coding) + "explain" (reasoning) → coding wins
    assert.equal(classifyTask("Explain this code"), "coding");
  });
});

describe("selectModel", () => {
  it("returns default coding model", () => {
    assert.equal(selectModel("Fix the bug"), "ollama/codellama:34b");
  });

  it("returns default reasoning model", () => {
    assert.equal(selectModel("Analyze this"), "ollama/llama3.3:70b");
  });

  it("returns default general model", () => {
    assert.equal(selectModel("Hello"), "ollama/llama3.3:latest");
  });

  it("uses custom models when provided", () => {
    const options: RouterOptions = {
      models: { coding: "ollama/codellama:13b" },
    };
    assert.equal(selectModel("Fix the bug", options), "ollama/codellama:13b");
  });

  it("falls back to defaults for unspecified custom models", () => {
    const options: RouterOptions = {
      models: { coding: "ollama/codellama:13b" },
    };
    // reasoning not overridden → default
    assert.equal(selectModel("Analyze this", options), "ollama/llama3.3:70b");
  });
});

describe("createModelRouter", () => {
  it("returns router with selectModel, classifyTask, models", () => {
    const router = createModelRouter();
    assert.equal(typeof router.selectModel, "function");
    assert.equal(typeof router.classifyTask, "function");
    assert.ok(router.models);
    assert.equal(router.models.coding, "ollama/codellama:34b");
    assert.equal(router.models.reasoning, "ollama/llama3.3:70b");
    assert.equal(router.models.general, "ollama/llama3.3:latest");
  });

  it("merges custom models with defaults", () => {
    const router = createModelRouter({
      models: { general: "ollama/llama3.2:latest" },
    });
    assert.equal(router.models.general, "ollama/llama3.2:latest");
    assert.equal(router.models.coding, "ollama/codellama:34b");
  });

  it("selectModel routes correctly", () => {
    const router = createModelRouter();
    assert.equal(router.selectModel("Fix the bug"), "ollama/codellama:34b");
    assert.equal(router.selectModel("왜 그래?"), "ollama/llama3.3:70b");
    assert.equal(router.selectModel("Hello"), "ollama/llama3.3:latest");
  });
});
