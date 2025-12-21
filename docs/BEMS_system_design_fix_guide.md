## BEMS 시스템 설계 문제점 해결 및 운영 준비 가이드 (v1.0)

| 항목 | 내용 |
|---|---|
| 문서명 | BEMS 시스템 설계 문제점 해결 및 운영 준비 가이드 |
| 버전 | 1.0 |
| 작성일 | 2025-12-21 |
| 대상 | AI 기반 바이오정책 인텔리전스 및 BEMS |

---

## 0. 이 문서의 적용 범위/전제

- 본 문서는 “설계서에 포함된 예시 코드/운영 설계”를 **실제 구현·운영 가능한 수준으로 끌어올리기 위한 보완 가이드**입니다.
- **중요**: 기존 설계서에서 AWS(S3/Pinecone 등)를 전제로 했는데, 본 가이드 예시에는 **MinIO/Qdrant**가 등장합니다. 이는 “로컬/온프레/개발 환경 대체재”로 쓰는 경우가 많으므로,
  - **prod**: AWS(S3, Pinecone 등) 중심
  - **dev/stage**: MinIO/Qdrant로 대체
  같은 식으로 “환경별 선택”을 명시하거나, 아예 한쪽으로 통일해야 합니다.

---

## 1. 즉시 수정 필요한 코드 결함 해결

### 1.1 SD 모델 예시 수정(필수)

#### 발견된 문제(원 설계서 예시)
- `pd.DataFrame` 반환인데 `import pandas as pd` 누락
- `results_集合`/`results_集합` 등 변수명 불일치(즉시 런타임 에러)

#### 수정안(적용 가능 버전)
아래 코드는 **파일 존재 확인, 모델 로드 예외 처리, 몬테카를로 결과 통계 산출**까지 포함합니다.

> 운영 팁: PySD 모델 로드는 무겁습니다. 워커 프로세스 단위로 모델을 “미리 로드”하고, 요청마다 재로드는 피하세요.

```python
# modules/simulation/bioeconomy_model.py

import logging
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import numpy as np
import pandas as pd
import pysd

logger = logging.getLogger(__name__)


class BioeconomySDModel:
    """바이오경제 시스템 다이내믹스 모델"""

    def __init__(self, model_path: str):
        self.model_path = Path(model_path)
        if not self.model_path.exists():
            raise FileNotFoundError(f"Model file not found: {model_path}")

        try:
            self.model = pysd.load(str(self.model_path))
            logger.info("Successfully loaded SD model: %s", model_path)
        except Exception:
            logger.exception("Failed to load SD model")
            raise

    def simulate(
        self,
        params: Dict[str, float],
        time_step: float = 0.25,
        initial_time: float = 0.0,
        final_time: float = 10.0,
        return_columns: Optional[List[str]] = None,
    ) -> pd.DataFrame:
        """시뮬레이션 실행"""
        try:
            # PySD는 run()에 params를 넘기면 내부적으로 세팅됨(개별 set_components 반복 불필요)
            timestamps = list(np.arange(initial_time, final_time + time_step, time_step))
            results = self.model.run(
                params=params,
                initial_condition="current",
                return_columns=return_columns,
                return_timestamps=timestamps,
            )
            logger.info("Simulation completed: %s time steps", len(results))
            return results
        except Exception:
            logger.exception("Simulation failed")
            raise

    def monte_carlo(
        self,
        param_distributions: Dict[str, Dict[str, float]],
        n_runs: int = 1000,
        **kwargs,
    ) -> Tuple[pd.DataFrame, pd.DataFrame]:
        """Monte Carlo 시뮬레이션"""
        all_results: List[pd.DataFrame] = []

        for run in range(n_runs):
            sampled_params = self._sample_parameters(param_distributions)
            result = self.simulate(params=sampled_params, **kwargs).reset_index()
            # PySD 결과는 index가 time인 경우가 많아 reset_index()로 time 컬럼을 보장
            result["run_number"] = run
            all_results.append(result)

            if (run + 1) % 100 == 0:
                logger.info("Completed %s/%s runs", run + 1, n_runs)

        combined_results = pd.concat(all_results, ignore_index=True)
        statistics = self._calculate_statistics(combined_results)
        return combined_results, statistics

    def _sample_parameters(self, param_distributions: Dict[str, Dict[str, float]]) -> Dict[str, float]:
        sampled: Dict[str, float] = {}

        for param_name, dist_config in param_distributions.items():
            dist_type = dist_config["type"]

            if dist_type == "normal":
                value = np.random.normal(dist_config["mean"], dist_config["std"])
            elif dist_type == "uniform":
                value = np.random.uniform(dist_config["min"], dist_config["max"])
            elif dist_type == "lognormal":
                value = np.random.lognormal(dist_config["mean"], dist_config["std"])
            else:
                raise ValueError(f"Unsupported distribution type: {dist_type}")

            sampled[param_name] = float(value)

        return sampled

    def _calculate_statistics(self, results: pd.DataFrame) -> pd.DataFrame:
        # time 컬럼명은 reset_index() 이후 'time' 또는 'index'일 수 있어 방어적으로 처리 권고
        time_col = "time" if "time" in results.columns else ("index" if "index" in results.columns else None)
        if time_col is None:
            raise ValueError("Time column not found in simulation results")

        value_columns = [c for c in results.columns if c not in ["run_number", time_col]]

        final_time = results[time_col].max()
        final_results = results[results[time_col] == final_time]

        statistics = {}
        for col in value_columns:
            statistics[col] = {
                "mean": final_results[col].mean(),
                "std": final_results[col].std(),
                "min": final_results[col].min(),
                "max": final_results[col].max(),
                "percentile_5": final_results[col].quantile(0.05),
                "percentile_25": final_results[col].quantile(0.25),
                "percentile_50": final_results[col].quantile(0.50),
                "percentile_75": final_results[col].quantile(0.75),
                "percentile_95": final_results[col].quantile(0.95),
            }

        return pd.DataFrame(statistics).T
```

---

### 1.2 RiskAnalyzer 예시 완성(필수)

#### 발견된 문제(원 설계서 예시)
- `mean = ...`가 남아 있어 실행 불가
- 변동성/하방리스크 정의가 불명확(지표별 스케일 차이 고려 필요)

#### 수정안(적용 가능 버전)
아래 코드는 **지표별 분포에서 시나리오(5/50/95%), VaR/CVaR, 종합 리스크 점수**를 산출합니다.

```python
# modules/dss/risk_analyzer.py

import logging
from typing import Dict, List

import numpy as np
import pandas as pd

logger = logging.getLogger(__name__)


class RiskAnalyzer:
    """정책 대안의 리스크 분석"""

    def __init__(self):
        self.risk_weights = {
            "volatility": 0.3,
            "downside_risk": 0.4,
            "uncertainty": 0.3,
        }

    def analyze(
        self,
        simulation_results: pd.DataFrame,
        scenarios: List[str] = ["worst", "expected", "best"],
    ) -> Dict[str, Dict]:
        """
        Args:
            simulation_results: 필수 컬럼: run_number, time, indicator_name, value
        """
        required = {"run_number", "time", "indicator_name", "value"}
        missing = required - set(simulation_results.columns)
        if missing:
            raise ValueError(f"Missing required columns: {sorted(missing)}")

        results: Dict[str, Dict] = {}
        final_time = simulation_results["time"].max()
        final_data = simulation_results[simulation_results["time"] == final_time]

        for indicator in final_data["indicator_name"].unique():
            values = final_data[final_data["indicator_name"] == indicator]["value"]
            results[indicator] = self._analyze_indicator(values, scenarios)

        return results

    def _analyze_indicator(self, values: pd.Series, scenarios: List[str]) -> Dict:
        mean = float(values.mean())
        std = float(values.std())

        scenario_values = {
            "worst": float(values.quantile(0.05)),
            "expected": float(values.quantile(0.50)),
            "best": float(values.quantile(0.95)),
        }

        volatility = (std / mean) if mean != 0 else 0.0

        downside_values = values[values < mean]
        downside_risk = (
            float(np.sqrt(((downside_values - mean) ** 2).mean()))
            if len(downside_values) > 0
            else 0.0
        )

        var_95 = float(mean - values.quantile(0.05))
        cvar_95 = float(mean - values[values <= values.quantile(0.05)].mean())

        uncertainty = (
            float((values.quantile(0.95) - values.quantile(0.05)) / mean)
            if mean != 0
            else 0.0
        )

        risk_score = self._calculate_risk_score(
            volatility=volatility,
            downside_risk_normalized=(downside_risk / mean) if mean != 0 else 0.0,
            uncertainty=uncertainty,
        )

        return {
            "mean": mean,
            "std": std,
            "scenarios": {k: scenario_values[k] for k in scenarios if k in scenario_values},
            "volatility": float(volatility),
            "downside_risk": float(downside_risk),
            "var_95": float(var_95),
            "cvar_95": float(cvar_95),
            "uncertainty": float(uncertainty),
            "risk_score": float(risk_score),
            "risk_level": self._get_risk_level(risk_score),
        }

    def _calculate_risk_score(self, volatility: float, downside_risk_normalized: float, uncertainty: float) -> float:
        # 경험적 정규화(프로젝트별 캘리브레이션 필요)
        volatility_score = min(volatility * 200.0, 100.0)          # 0.5 이상이면 100
        downside_score = min(downside_risk_normalized * 200.0, 100.0)
        uncertainty_score = min(uncertainty * 100.0, 100.0)        # 1.0 이상이면 100

        return (
            volatility_score * self.risk_weights["volatility"]
            + downside_score * self.risk_weights["downside_risk"]
            + uncertainty_score * self.risk_weights["uncertainty"]
        )

    def _get_risk_level(self, risk_score: float) -> str:
        if risk_score < 20:
            return "very_low"
        if risk_score < 40:
            return "low"
        if risk_score < 60:
            return "medium"
        if risk_score < 80:
            return "high"
        return "very_high"
```

---

### 1.3 Airflow 동기/비동기 처리 개선(권고)

#### 핵심 원칙
- Airflow task는 “오케스트레이션”에 집중: **크롤링/파싱은 워커(큐)로 위임**이 운영 안정성이 높습니다.
- 다만 단기적으로 task에서 직접 실행해야 한다면, **동기 함수로 감싸고** 코루틴 여부만 안전하게 처리합니다.

#### 추가로 빠진 스키마/필드(주의)
가이드 예시에는 `information_sources.next_crawl_at`, `crawling_failures`가 등장합니다.
기존 DB 설계서에 없으므로 다음 중 하나가 필요합니다.
- (선호) 스키마 확장: `information_sources(next_crawl_at TIMESTAMP)` 및 `crawling_failures` 테이블 추가
- (대안) `last_crawled_at`+`crawl_frequency`로 계산하고 별도 컬럼 없이 스케줄링

---

### 1.4 Circuit Breaker(Python) 설계 보완(권고)

제공한 CircuitBreaker는 “기능 예시”로 적절하지만, 운영에서는 아래가 추가로 필요합니다.
- 비동기 지원(Async) 버전
- fallback/timeout/retry 정책과 함께(특히 외부 API, OpenSearch, LLM)
- 상태/카운터를 **메트릭으로 노출**(OPEN 전환 횟수, HALF_OPEN 성공률 등)

---

## 2. 운영 관점 설계 보완(필수 체크)

### 2.1 설정/시크릿(중요)
가이드 예시의 `settings.py`에는 아래 운영 위험이 있습니다.
- **DSN/비밀번호/액세스키가 코드 기본값으로 존재** → 반드시 제거(placeholder만)
- `ALLOWED_HOSTS=["*"]`, `CORS_ORIGINS=["*"]` → prod에서는 금지(허용 도메인만)
- `SECRET_KEY="change-me-in-production"` → prod에서는 배포 차단 수준으로 강제(미설정 시 기동 실패)

권고 패턴:
- DSN/키/비밀번호는 **환경변수 + Secret Manager**로만 주입
- prod에서 위험한 기본값이 있으면 **애플리케이션이 기동하지 않도록** fail-fast

---

## 3. 메트릭 및 관측성 표준 정의(운영 필수)

### 3.1 메트릭 라벨 카디널리티(필수 수정 포인트)
현재 예시의 `endpoint=request.url.path`는 `/documents/{id}`처럼 **id가 붙는 경로에서 라벨 폭발**이 발생합니다.

권고:
- FastAPI에서 route template을 사용: `request.scope["route"].path` (예: `/documents/{id}`)
- 또는 endpoint를 “핵심 엔드포인트 그룹”으로 매핑(예: `/documents/*`)

### 3.2 metrics.py 예시의 즉시 오류(필수)
- `track_time()`에서 `asyncio.iscoroutinefunction`을 사용하는데 **`import asyncio`가 누락**되어 있습니다.

---

## 4. 배치 및 이벤트 처리 내구성 설계(운영 필수)

### 4.1 최소 요구사항(요약)
- **Idempotency(중복 처리 방지)**: `document_id`/`message_id` 기반 **unique constraint + upsert** + 애플리케이션 레벨 멱등성 키
- **Retry 정책**: 지수 백오프 + 최대 재시도 + 재시도 간격(즉시/지연) 분리
- **Poison 메시지 격리**: DLQ 라우팅 + 원인 분류(파서/포맷/권한/외부 장애)
- **Outbox/Inbox 패턴(권고)**: DB 트랜잭션과 이벤트 발행/소비의 일관성 확보

---

### 4.2 Idempotency 패턴

#### 4.2.1 설계 시 주의점(운영에서 자주 터지는 부분)
- Redis `get()`은 보통 **bytes**를 반환하므로 JSON 파싱 전 **decode**가 필요합니다.
- “processing” 같은 문자열을 저장하면, 이후 `json.loads()`에서 실패합니다.  
  → **상태/결과를 하나의 JSON으로 저장**하거나, **lock key와 result key를 분리**하세요.
- 멱등/쿼터는 “체크 후 세팅”이 레이스가 생깁니다.  
  → 중요 경로는 (가능하면) **Lua 스크립트**로 원자 처리 권고.

#### 4.2.2 IdempotencyManager(개선판: 상태/결과 JSON + bytes 디코딩)

```python
# common/idempotency.py

import hashlib
import json
import logging
from datetime import datetime
from typing import Any, Dict, Optional

from redis import Redis

logger = logging.getLogger(__name__)


class DuplicateRequestError(Exception):
    pass


class IdempotencyManager:
    """
    멱등성 키로 (1) 처리 중 락, (2) 결과 캐시를 동일 key(JSON)로 관리하는 단순 패턴.
    - value 예시:
      {"status":"processing","created_at":"..."}
      {"status":"completed","completed_at":"...","result":{...}}
    """

    def __init__(self, redis_client: Redis, ttl: int = 86400):
        self.redis = redis_client
        self.ttl = ttl

    def generate_key(self, operation: str, params: Dict[str, Any]) -> str:
        sorted_params = json.dumps(params, sort_keys=True, separators=(",", ":"))
        hash_input = f"{operation}:{sorted_params}"
        key_hash = hashlib.sha256(hash_input.encode("utf-8")).hexdigest()
        return f"idempotency:{operation}:{key_hash}"

    def get(self, key: str) -> Optional[Dict[str, Any]]:
        raw = self.redis.get(key)
        if raw is None:
            return None
        if isinstance(raw, (bytes, bytearray)):
            raw = raw.decode("utf-8", errors="replace")
        return json.loads(raw)

    def acquire(self, key: str) -> bool:
        payload = {"status": "processing", "created_at": datetime.utcnow().isoformat()}
        return bool(self.redis.set(key, json.dumps(payload), ex=self.ttl, nx=True))

    def complete(self, key: str, result: Dict[str, Any], ttl: Optional[int] = None) -> None:
        payload = {
            "status": "completed",
            "completed_at": datetime.utcnow().isoformat(),
            "result": result,
        }
        self.redis.set(key, json.dumps(payload), ex=ttl or self.ttl)

    def delete(self, key: str) -> None:
        self.redis.delete(key)
```

#### 4.2.3 사용 패턴(문서 처리 예시)

```python
class DocumentProcessor:
    def __init__(self, idempotency_manager: IdempotencyManager):
        self.idempotency = idempotency_manager

    async def process_document(self, document_id: str, force: bool = False) -> Dict[str, Any]:
        key = self.idempotency.generate_key("document_process", {"document_id": document_id})

        if not force:
            state = self.idempotency.get(key)
            if state and state.get("status") == "completed":
                return state["result"]
            if state and state.get("status") == "processing":
                raise DuplicateRequestError(f"Document {document_id} is already being processed")

            if not self.idempotency.acquire(key):
                state = self.idempotency.get(key)
                if state and state.get("status") == "completed":
                    return state["result"]
                raise DuplicateRequestError(f"Document {document_id} is already being processed")

        try:
            result = await self._do_process(document_id)
            self.idempotency.complete(key, result)
            return result
        except Exception:
            # 실패 시 재시도 허용 정책(즉시 재시도 가능하도록 키 삭제)
            self.idempotency.delete(key)
            raise
```

---

### 4.3 DLQ(Dead Letter Queue) 설계

#### 4.3.1 Kafka DLQ 패턴(운영 보완 포인트)
- 컨슈머 루프 안에서 `await asyncio.sleep()`로 지연 재시도를 구현하면 **컨슈머 처리량이 급락**합니다.  
  → 권고: **retry topic(예: `topic.retry`)**로 즉시 재발행하고, 별도 워커가 지연/재큐잉.
- 재발행 성공 후 커밋(수동 커밋)으로 “유실 없이 중복만 허용” 방향을 택합니다.

#### 4.3.2 Saga 패턴(상세) 적용 시 권고
- 문서 파이프라인(원문 저장 + 메타 저장 + 인덱싱)은 강한 일관성(Saga)보다 **Outbox + 비동기 재시도**가 운영에 적합한 경우가 많습니다.
- OpenSearch 인덱싱 실패는 “보상 삭제”보다 “재시도/백필”이 운영 비용이 낮습니다.

---

## 5. 데이터 거버넌스 정책(운영 필수)
### 5.1 필수 항목(요약)
- 데이터 분류(공개/내부/민감/제한) 및 저장소별 보관기간
- 문서 원문(S3/MinIO), 로그(OpenSearch/ELK), LLM 입력/출력의 보관 원칙
- 감사로그(다운로드/보고서 생성/권한변경)는 삭제 불가 또는 WORM(권고)

### 5.2 PII 처리(필수 보완)
- 해시 salt/secret을 코드에 하드코딩 금지(Secret Manager에서 주입)
- 이메일 정규식은 `[A-Z|a-z]` 대신 `[A-Za-z]` 권고(`|` 포함 오류 방지)

---

## 6. 성능 및 비용 가드레일(운영 필수)
### 6.1 필수 항목(요약)
- 시뮬레이션: `n_runs`, 기간, 동시 실행 수 상한 + 사용자/역할별 쿼터
- LLM: 호출 빈도 제한 + 토큰 상한 + 비용 메트릭/예산 알림(월간/주간)
- 검색(OpenSearch): 결과 크기 제한, timeout, circuit breaker 적용

### 6.2 Budget Circuit Breaker(주의: Async 불일치)
- LLM 클라이언트에서 `await circuit_breaker.call(...)` 형태를 쓰려면, 서킷 브레이커가 **async 지원**을 제공해야 합니다.
- async 미지원 서킷 브레이커를 그대로 쓰면 런타임에서 의도대로 동작하지 않습니다(구현 시 AsyncCircuitBreaker 또는 호출 구조 변경 필요).

---

## 7. Kubernetes 배포 구성(최소 운영 요건)
- readiness/liveness/startup probe
- requests/limits 필수
- HPA(큐 lag 또는 RPS 기반 권고)
- PDB + 다중 AZ 스케줄링(affinity)
- NetworkPolicy 기본 deny + 필요한 egress만 허용
- ServiceMonitor/PodMonitor로 메트릭 스크랩 표준화

---

## 8. 운영 검증 시나리오(Go/No-Go)
- Observability: request_id 전파(게이트웨이→서비스→DB/큐), trace 연결 확인
- Pipeline: 포맷 오류/중복 문서/poison 메시지 유입 시 DLQ/재처리 검증
- Simulation: 최대 부하(동시 요청/큰 n_runs)에서 큐잉·타임아웃·자원 격리 검증
- Security: 권한 없는 다운로드 차단, presigned URL TTL, SSRF 차단, 감사로그 누락 여부 점검

