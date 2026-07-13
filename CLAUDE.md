# CLAUDE.md

CodeBlack_iOS 프로젝트 작업 규칙. Claude/에이전트는 이 규칙을 무조건 따른다.

## Git 워크플로 (필수)

- **이슈 생성 금지.** GitHub Issue를 만들지 않는다.
- **PR 생성 금지.** Pull Request를 만들지 않는다. 브랜치를 파서 PR로 병합하는 흐름을 쓰지 않는다.
- **무조건 `main`에 직접 커밋한다.** 별도 feature 브랜치를 만들지 않는다.
- **커밋하면 즉시 푸시한다.** `git commit` 후 항상 `git push origin main`을 같이 실행한다. 커밋만 하고 푸시를 미루지 않는다.

### 표준 커밋 절차

```bash
git add -A
git commit -m "<메시지>"
git push origin main
```

## 원칙

- 작업이 끝나면 위 절차대로 main에 커밋 + 푸시까지 한 번에 완료한다.
- 커밋 메시지는 무엇을/왜 바꿨는지 명확히 쓴다.
- 승인을 구걸하지 않는다. 규칙 범위 내 작업은 바로 실행한다.
