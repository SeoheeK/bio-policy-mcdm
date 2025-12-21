# 요구사항 산출물

이 폴더는 BEMS 구축 프로젝트의 **요구사항 원문**과, 원문에서 파생된 **요구사항 ID 카탈로그(추출본)**를 보관합니다.

## 파일 목록

- **요구사항 정의서 원문 (v1.0)**: `requirements-spec-v1.0.md`
- **요구사항 ID 카탈로그 (CSV)**: `requirements-catalog.csv`
- **요구사항 ID 카탈로그 (XLSX)**: `requirements-catalog.xlsx`

## 카탈로그 컬럼 정의

- **id**: 요구사항 ID (SR/FR/NFR/DR/IR/CONST)
- **type**: 상위 유형 (SR, FR, NFR, DR, IR, CONST)
- **group**: 중분류(예: FR의 M1/M2/…/COM, NFR의 PERF/AVAIL/SEC/…)
- **number**: 3자리 일련번호
- **title**: 요구사항 제목(콜론 뒤 텍스트)
- **raw_tags**: 원문 괄호 태그(예: `P0, Must have`, `Critical`)
- **priority_p**: P0~P3 (있을 경우)
- **moscow**: Must/Should/Could/Won't (있을 경우)
- **severity**: Critical/High/Medium/Low (있을 경우)
- **section_path**: 원문 내 섹션 경로(Heading 기반)
- **source_file**: 파싱 대상 원문 파일 경로

## 재생성 방법

```bash
python3 scripts/export_requirements.py
```

## 참고(개수 차이)

원문 9.1 표의 합계(192)와 추출 결과 총 개수는 **정의/집계 범위(SR/NFR/DR/IR/CONST 포함 여부, Future Consideration 포함 여부)**에 따라 달라질 수 있습니다.  
필요 시, 프로젝트 표준에 맞춰 “집계 대상 유형”을 확정한 뒤 스크립트에 필터 옵션을 추가하는 방식으로 맞춰드릴 수 있습니다.

