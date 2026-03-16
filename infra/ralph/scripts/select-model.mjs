#!/usr/bin/env node
/**
 * select-model.mjs
 * Reads the current highest-priority incomplete task from .agent/tasks.json
 * and returns the appropriate Claude model via model-router.
 *
 * Usage: node select-model.mjs <project-dir>
 * Output: model name (e.g. claude-sonnet-4-6)
 */

import { readFileSync } from "fs";
import { join } from "path";

const projectDir = process.argv[2] ?? process.cwd();

// Inline model-router logic (provider=claude) to avoid build step
const CLAUDE_MODELS = {
  coding: "claude-sonnet-4-6",
  reasoning: "claude-opus-4-6",
  general: "claude-sonnet-4-6",
};

const CODING_KEYWORDS = [
  "code","function","bug","debug","refactor","implement","class","method",
  "variable","error","compile","syntax","api","endpoint","database","query",
  "test","unit test","fix","patch","lint","type","build","deploy","script",
  "코드","함수","버그","디버그","리팩토링","구현","클래스","메서드",
  "변수","에러","컴파일","문법","테스트","빌드","배포",
];

const REASONING_KEYWORDS = [
  "why","analyze","compare","explain","reason","logic","think","evaluate",
  "pros and cons","trade-off","decision","strategy","architecture","design",
  "왜","분석","비교","설명","이유","논리","생각","평가","장단점",
  "트레이드오프","결정","전략","아키텍처","설계",
];

function classifyTask(message) {
  const lower = message.toLowerCase();
  if (CODING_KEYWORDS.some((kw) => lower.includes(kw.toLowerCase()))) return "coding";
  if (REASONING_KEYWORDS.some((kw) => lower.includes(kw.toLowerCase()))) return "reasoning";
  return "general";
}

function getTaskDescription() {
  try {
    const tasksPath = join(projectDir, ".agent", "tasks.json");
    const tasks = JSON.parse(readFileSync(tasksPath, "utf8"));

    // Find highest priority incomplete task
    const incomplete = tasks
      .filter((t) => t.status !== "completed" && t.status !== "done")
      .sort((a, b) => (a.priority ?? 999) - (b.priority ?? 999));

    if (incomplete.length === 0) return "";

    const task = incomplete[0];
    return [task.title, task.description, task.goal].filter(Boolean).join(" ");
  } catch {
    return "";
  }
}

const description = getTaskDescription();
const taskType = description ? classifyTask(description) : "general";
const model = CLAUDE_MODELS[taskType];

process.stdout.write(model);
