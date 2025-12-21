## 7. Kubernetes 배포 구성 검토 및 수정 가이드(운영용)

아래는 사용자가 제시한 `k8s/*.yaml` 설계의 **즉시 수정 포인트(운영 장애/보안 이슈/관측성 실패)**를 “문제 → 권고 수정” 형태로 정리한 것입니다.

---

### 7.1 Namespace / ResourceQuota / LimitRange

#### 문제점
- ResourceQuota/LimitRange 자체는 좋지만, **HPA/배치 워커/대용량 시뮬레이션**을 고려하면 “노드풀 분리(워크로드 격리)”가 같이 필요합니다.

#### 권고
- `bems-api`(온라인)와 `bems-worker`(배치/시뮬레이션)의 노드풀 분리:
  - `nodeSelector`/`taints&tolerations` 적용(예: 워커는 고사양 노드)
- 워커는 OOM/CPU 스로틀에 민감하므로 **requests/limits를 실제 부하 테스트 기반으로 재산정**(초안 값은 시작점)

---

### 7.2 ConfigMap / Secret

#### 문제점(치명)
- Secret에 **실제 비밀번호/OPENAI 키**를 평문으로 적어 커밋하는 형태는 운영 사고/보안 감사에서 즉시 이슈입니다.
- ConfigMap에 DB IP를 직접 박으면, 운영 변경(장비 교체/DR) 시 전파가 어렵습니다.

#### 권고
- Secret은 **External Secrets(Secrets Manager/Parameter Store) 또는 SealedSecret** 사용을 기본으로.
- 앱 설정은 “host/port 조합”보다 **DSN 단일 값**(예: `POSTGRES_DSN`)이 운영/로테이션에 유리.

---

### 7.3 Ingress

#### 문제점(즉시 버그)
- `nginx.ingress.kubernetes.io/rewrite-target: /`는 `/v1` 프리픽스 라우팅을 **깨뜨릴 가능성이 큼**(경로가 `/`로 리라이트).
- `/metrics`를 Ingress로 노출하면(설령 “내부만” 주석을 달아도) 보안상 취약합니다. Prometheus는 **클러스터 내부 ServiceMonitor로 스크랩**하면 충분합니다.

#### 권고
- API용 Ingress에서는 `rewrite-target` 제거(또는 정교한 rewrite 적용).
- `/metrics`는 Ingress에서 제거하고, ServiceMonitor로만 수집.
  - 정말 외부로 열어야 한다면: IP allowlist + basic auth + 별도 내부 Ingress로 분리

---

### 7.4 HPA (autoscaling/v2)

#### 문제점(즉시 적용 불가)
- `Pods` metric: `http_requests_per_second`는 Kubernetes 기본/표준 메트릭이 아닙니다.
- `External` metric: `kafka_consumer_lag`도 **metrics adapter(KEDA 또는 Prometheus Adapter) 없이 동작하지 않습니다.**

#### 권고(현실적 2단계)
- 1단계(즉시 운영 가능): CPU/Memory 기반 HPA만 적용
- 2단계(권고): KEDA 또는 Prometheus Adapter 설치 후,
  - API: `bems_api_http_requests_total`의 rate를 custom metric으로 매핑
  - Worker: Kafka lag(또는 `bems_queue_lag`)를 external metric으로 매핑

---

### 7.5 NetworkPolicy

#### 문제점(자주 실패)
- `namespaceSelector.matchLabels.name=monitoring` 같은 “임의 라벨”은 실제 클러스터에서 없는 경우가 많아, 결과적으로 **트래픽이 전부 막힙니다.**
- DNS 허용을 `kube-system` namespaceSelector만으로 하면 CoreDNS pod selector가 안 맞아 실패할 수 있습니다.
- Kafka egress를 `podSelector app=kafka`로만 두면, Kafka가 다른 네임스페이스에 있으면 실패합니다.
- “외부 API(443)만 허용”은 좋지만, 운영 중 외부 의존성(예: 인증서 갱신, 패키지 다운로드)을 고려하면 **정책 범위 정의가 필요**합니다.

#### 권고(안정적인 selector)
- namespaceSelector는 가능하면 아래 라벨 사용:
  - `kubernetes.io/metadata.name: <namespace>`
- DNS 허용은 `kube-system` + podSelector(`k8s-app: kube-dns`) 조합 권고
- Kafka는 namespaceSelector + podSelector를 함께 지정 권고

---

### 7.6 ServiceMonitor / PrometheusRule

#### 문제점(자주 실패)
- kube-prometheus-stack에서 ServiceMonitor/Rule을 선택하는 라벨이 클러스터마다 다릅니다.
- `up{job="bems-api"}`는 ServiceMonitor 기반 환경에서 job 라벨이 기대와 다를 수 있어 오탐/미탐이 큼.

#### 권고
- 가용성은 `up`보다는 kube-state-metrics 기반(Deployment replicas)로 보는 것이 안정적:
  - `kube_deployment_status_replicas_available / kube_deployment_spec_replicas`
- PrometheusRule은 `bems_*` 커스텀 메트릭(앱 레벨) + kube-state-metrics(인프라 레벨)로 이원화 권고

---

## 8. 운영 검증 시나리오(추가 수정 포인트)

### 8.1 Request-ID 전파 테스트

#### 문제점(치명)
- “메트릭 라벨에 request_id 포함”은 절대 금지입니다(라벨 카디널리티 폭발).  
  request_id는 **로그/트레이스에서만** 사용해야 합니다.

#### 권고
- 메트릭은 endpoint는 반드시 템플릿 경로(`/documents/{id}`) 수준으로 정규화.
- request_id는 로그(JSON 필드) + trace span attribute로만 유지.

