# bio-policy-mcdm

## 문서

- **요구사항 정의서 v1.0 (2025-12-17)**: `docs/requirements/requirements-spec-v1.0.md`
- **요구사항 ID 카탈로그 (CSV/XLSX)**: `docs/requirements/requirements-catalog.csv`, `docs/requirements/requirements-catalog.xlsx`
- **추적성 매트릭스 템플릿 (요구사항↔설계↔테스트)**: `docs/traceability/traceability-matrix-template.csv`, `docs/traceability/traceability-matrix-template.xlsx`

## 산출물 재생성

아래 스크립트는 요구사항 정의서 마크다운을 파싱하여 CSV/엑셀 산출물을 재생성합니다.

```bash
python3 scripts/export_requirements.py
```