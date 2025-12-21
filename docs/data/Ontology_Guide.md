## 온톨로지(초안) 적용 가이드

본 문서는 `docs/data/ontology_draft.ttl`(Draft v0.1)을 **지식그래프(M4) 및 데이터 표준**에 적용하기 위한 운영 가이드이다.

---

## 1. 설계 원칙

- **최소 공통 모델(MVP)**: “정책-수단-행위자-기술-예산-성과-지표-관측값” 연결을 우선 제공
- **추적성(Traceability)**: 분석/권고 결과는 **근거(Evidence)**와 연결되어야 함
- **버전관리**: 클래스/관계/정의 변경은 `owl:versionInfo` 업데이트 및 변경이력 문서화
- **확장성**: Phase 2 이후 RDF/OWL 정교화 또는 Neo4j 스키마 확장 가능

---

## 2. 핵심 엔티티/관계(요약)

### 2.1 엔티티(클래스)

- `bems:PolicyDocument`: 정책 문서(원문 URL/제목/발행일 등)
- `bems:Policy`: 정책/전략(목표/범위)
- `bems:PolicyInstrument`: 정책 수단(예산/규제/인센티브 등)
- `bems:Organization`: 부처/기관/기업/대학
- `bems:Technology`: 기술/도메인(레드/그린/화이트 등)
- `bems:Program` / `bems:Project`: 프로그램/과제
- `bems:BudgetLine`: 예산 항목
- `bems:Indicator` / `bems:Observation`: 지표/관측값(기간/값/단위)
- `bems:Evidence`: 관측/분석의 근거(출처/방법/신뢰도)

### 2.2 관계(예시)

- 문서→정책: `bems:documentsPolicy`
- 조직→정책: `bems:implementsPolicy`
- 정책→수단: `bems:usesInstrument`
- 프로그램→과제: `bems:hasProject`
- 과제→성과: `bems:producesOutput`
- 성과→기술: `bems:relatesToTechnology`
- 예산→프로그램/과제: `bems:fundsProgram`, `bems:fundsProject`
- 수단→지표 영향: `bems:affectsIndicator`
- 지표→관측값: `bems:hasObservation`
- 관측값→근거: `bems:hasEvidence`

---

## 3. Neo4j 매핑 가이드(권장)

RDF를 직접 운용하지 않더라도, 아래처럼 **라벨/관계**로 매핑하여 운영할 수 있다.

### 3.1 라벨(예시)

- `PolicyDocument`, `Policy`, `PolicyInstrument`, `Organization`, `Technology`
- `Program`, `Project`, `BudgetLine`, `Indicator`, `Observation`, `Evidence`

### 3.2 관계 타입(예시)

- `DOCUMENTS_POLICY` (PolicyDocument→Policy)
- `IMPLEMENTS` (Organization→Policy)
- `USES_INSTRUMENT` (Policy→PolicyInstrument)
- `TARGETS_TECH` (Policy/Program→Technology)
- `HAS_PROJECT` (Program→Project)
- `PRODUCES` (Project→Output)
- `RELATES_TO_TECH` (Output→Technology)
- `FUNDS_PROGRAM` / `FUNDS_PROJECT`
- `AFFECTS_INDICATOR` (PolicyInstrument→Indicator)
- `HAS_OBSERVATION` (Indicator→Observation)
- `HAS_EVIDENCE` (Observation→Evidence)

### 3.3 관측값(Observation) 권장 속성

- `value`(number), `unit`(string), `timePeriodStart`(date), `timePeriodEnd`(date)
- `granularityKey`(string): 예) `country=KOR|tech=white|period=2025M12`
- `source`/`methodNote`/`confidenceScore`는 Evidence로 분리 권장

---

## 4. 지표 사전(Indicator Dictionary)와의 정합성

- `bems:Indicator`의 `dcterms:identifier`는 `Indicator_Dictionary.csv`의 `indicator_id`와 **동일**해야 한다.
- 지표 정의 변경 시:
  - 지표 사전에서 **새 버전 행 추가**
  - 온톨로지 스키마 변경이 필요한 경우에만 `owl:versionInfo` 증가

---

## 5. 확장 포인트(Phase 2~3)

- **다국어/다국가**: 국가코드(ISO-3166), 기관코드, 기술 분류체계(IPC/MeSH/KSIC) 연계
- **정책 이벤트**: `bems:Event`를 활용해 “발표/시행/개정” 시점과 영향 지연(lag) 모델링
- **설명가능성(XAI)**: `bems:Evidence`에 모델버전/피처 중요도 요약/검증자 정보를 추가

