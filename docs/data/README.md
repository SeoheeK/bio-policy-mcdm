## 데이터 표준 패키지

### 파일 목록

- **지표 사전**
  - `docs/data/Indicator_Dictionary.csv`
  - `docs/data/Indicator_Dictionary_Guide.md`
- **온톨로지(초안)**
  - `docs/data/ontology_draft.ttl`
  - `docs/data/Ontology_Guide.md`

### 사용 원칙(요약)

- `Indicator_Dictionary.csv`는 지표 정의의 **단일 기준**이다.
- 지표 ID(`indicator_id`)는 온톨로지의 `bems:Indicator dcterms:identifier`와 **동일**해야 한다.
- 정의/산식/모집단 변경은 **새 버전**으로 발행하고 적용일을 기록한다.

