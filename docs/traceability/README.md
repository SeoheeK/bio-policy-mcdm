# 추적성(Traceability) 산출물

이 폴더는 “요구사항 ↔ 설계 ↔ 테스트” 연결을 관리하기 위한 **추적성 매트릭스 템플릿**을 보관합니다.

## 파일 목록

- **추적성 매트릭스 템플릿 (CSV)**: `traceability-matrix-template.csv`
- **추적성 매트릭스 템플릿 (XLSX)**: `traceability-matrix-template.xlsx`

## 템플릿 사용 방법(권장)

- **requirement_id / requirement_title**: 자동 추출값(수정하지 않음)
- **linked_requirement_ids**: 원문 8.1(이해관계자→기능) 매핑이 있는 경우 자동 사전 입력됨
- **design_artifact_id / design_artifact_link**: 설계 산출물(예: ADR, 아키텍처 다이어그램, API 명세, DB 스키마, JIRA 에픽/스토리) 연결
- **test_case_id / test_type / test_link**: 테스트 케이스(예: TC-Mx-xxx), 테스트 유형, 테스트 문서/자동화 링크 연결
- **owner / status / notes**: 담당/상태/비고

## 재생성 방법

```bash
python3 scripts/export_requirements.py
```

