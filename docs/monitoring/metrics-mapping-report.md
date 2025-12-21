## 운영 스택 기반 적용 가능 버전 정리 및 변경 보고

### 1) 확인 결과(리포지토리 기준)
- 현재 리포지토리(HEAD)에는 **배포/운영 스택을 판별할 수 있는 파일(Helm values, K8s manifests, Terraform, exporter 설정 등)이 존재하지 않습니다.**
  - 트래킹 파일: `README.md`만 존재
- 따라서 “단일 스택 확정(예: Kong만/NGINX만/Istio만)”을 전제로 한 **1개 PromQL 세트로 고정하는 것은 불가**합니다.

### 2) 대응 방식(바로 적용 가능한 형태로 확장)
운영 현장에서 가장 흔한 조합을 기준으로, **스택별로 알림을 분리**하여 “존재하는 메트릭이 있을 때만” 동작하도록 구성했습니다.

- **Ingress/Gateway**
  - NGINX Ingress Controller: `nginx_ingress_controller_requests`, `nginx_ingress_controller_request_duration_seconds_bucket`
  - Istio Envoy: `istio_requests_total`, `istio_request_duration_milliseconds_bucket`
  - Kong: `kong_http_status` 또는 `kong_http_requests_total` (환경별 exporter 차이 대응)
- **Kubernetes**
  - kube-state-metrics: `kube_pod_container_status_waiting_reason`, `kube_pod_container_status_restarts_total`, `kube_deployment_status_replicas_available`, `kube_deployment_spec_replicas`
- **DB/Cache**
  - postgres_exporter: `pg_stat_activity_count`, `pg_settings_max_connections`
  - redis_exporter: `redis_keyspace_hits_total`, `redis_keyspace_misses_total`
- **Search**
  - opensearch exporter 계열: `opensearch_cluster_health_status{color="red"}`
  - elasticsearch exporter 계열: `elasticsearch_cluster_health_status{color="red"}`
- **Messaging**
  - kafka_exporter: `kafka_consumergroup_lag`
  - kminion: `kminion_kafka_consumergroup_lag`
- **Security Probe**
  - blackbox-exporter: `probe_ssl_earliest_cert_expiry`
- **App Custom**
  - 예시: `bems_auth_login_fail_total` (실제 구현 메트릭명으로 교체 필요)

### 3) 산출물(문서/운영에 바로 붙이기)
- PrometheusRule YAML: `docs/monitoring/prometheus-rules-bems.yaml`
  - 스택별 그룹으로 분리되어 있어 **해당 메트릭이 없는 경우 알림이 자동으로 비활성(빈 벡터)** 됩니다.

### 4) 이전 초안 대비 변경점(핵심)
- **게이트웨이/Ingress 메트릭을 “job 정규식” 기반에서 “실제 통용 메트릭명” 기반으로 분리**
  - (기존) `http_requests_total{job=~"..."}`
  - (변경) NGINX/Istio/Kong 각각의 대표 메트릭으로 분기
- **Istio 지연 메트릭 단위를 ms → s로 변환**(p95 비교를 초 단위로 통일)
  - `istio_request_duration_milliseconds_bucket / 1000`
- **OpenSearch exporter 다양성 대응**: OpenSearch/Elasticsearch health metric 둘 다 지원
- **Kafka lag 다양성 대응**: `kafka_exporter`와 `kminion`을 별도 알림으로 제공
- **나눗셈 안전성**: 일부 비율 계산에 `clamp_min()`을 적용(0으로 나누기 방지)

### 5) “진짜 현재 운영 스택에 1:1로 고정”하려면 필요한 입력(최소)
리포지토리 안에 아래 중 하나만 있어도 단일 세트로 정밀 고정 가능합니다.
- `values.yaml`(kube-prometheus-stack / ingress / istio / kong 등)
- Prometheus scrape 설정(대상 job/labels)
- exporter 설치 목록(helm release 목록 또는 manifest)

