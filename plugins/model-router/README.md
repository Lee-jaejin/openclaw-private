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

## Build

```bash
cd plugins/model-router
npm install
npm run build
```

---

## 한국어 (Korean)

### 모델 매핑
- **coding**: CodeLlama 34B - 코드, 함수, 버그, 디버그
- **reasoning**: Llama 3.3 70B - 왜, 분석, 비교, 논리
- **general**: Llama 3.3 - 기타 모든 요청
