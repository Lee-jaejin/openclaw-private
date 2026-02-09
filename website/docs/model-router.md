---
id: model-router
title: Model Router
sidebar_position: 8
---

# Model Router Plugin

Multi-LLM routing plugin for task-based model selection.

## Model Mapping

| Task Type | Model | Trigger Keywords |
|-----------|-------|------------------|
| **coding** | CodeLlama 34B | code, function, bug, debug |
| **reasoning** | Llama 3.3 70B | why, analyze, compare, logic |
| **general** | Llama 3.3 | all other requests |

## Usage

```typescript
import { selectModel, classifyTask } from "@openclaw-private/model-router";

// Select model based on message
const model = selectModel("Find the bug in this code");
// => "ollama/codellama:34b"

// Classify task only
const taskType = classifyTask("Why does this work that way?");
// => "reasoning"
```

## Korean Language Support

The router supports Korean keywords:

```typescript
// Korean coding keywords
const model = selectModel("이 코드에서 버그를 찾아줘");
// => "ollama/codellama:34b"

// Korean reasoning keywords
const model = selectModel("왜 이렇게 동작하는지 분석해줘");
// => "ollama/llama3.3:70b"
```

## Custom Configuration

```typescript
import { createModelRouter } from "@openclaw-private/model-router";

const router = createModelRouter({
  models: {
    coding: "ollama/codellama:13b", // lighter model
    reasoning: "ollama/llama3.3:latest", // instead of 70B
  },
  debug: true, // enable debug logging
});

const model = router.selectModel("Implement this function");
```

## Keywords Reference

### Coding Keywords

English: `code`, `function`, `bug`, `debug`, `refactor`, `implement`, `class`, `method`, `variable`, `error`, `compile`, `syntax`, `api`, `endpoint`, `database`, `query`, `test`, `unit test`

Korean: `코드`, `함수`, `버그`, `디버그`, `리팩토링`, `구현`, `클래스`, `메서드`, `변수`, `에러`, `컴파일`, `문법`

### Reasoning Keywords

English: `why`, `analyze`, `compare`, `explain`, `reason`, `logic`, `think`, `evaluate`, `pros and cons`, `trade-off`, `decision`, `strategy`

Korean: `왜`, `분석`, `비교`, `설명`, `이유`, `논리`, `생각`, `평가`, `장단점`, `트레이드오프`, `결정`, `전략`

## Build

```bash
cd plugins/model-router
npm install
npm run build
```

## Integration with OpenClaw

The model router can be integrated with OpenClaw's plugin system:

```json
{
  "plugins": {
    "model-router": {
      "enabled": true,
      "config": {
        "models": {
          "coding": "ollama/codellama:34b",
          "reasoning": "ollama/llama3.3:70b",
          "general": "ollama/llama3.3:latest"
        }
      }
    }
  }
}
```
