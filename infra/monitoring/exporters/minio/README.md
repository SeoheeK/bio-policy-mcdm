# MinIO 메트릭 수집

MinIO는 별도 exporter 없이 **내장 Prometheus 메트릭 엔드포인트**를 제공합니다.

## Prometheus scrape 경로(대표)

- Cluster: `/minio/v2/metrics/cluster`
- Node: `/minio/v2/metrics/node`

## 인증

운영에서 Prometheus가 접근 가능하도록 다음 중 하나를 선택합니다.

- **A안(간단)**: MinIO에 `MINIO_PROMETHEUS_AUTH_TYPE=public` 설정(내부망에서만)
- **B안(권장)**: 인증 토큰/리버스프록시/ACL로 접근 제어 후 Prometheus에 인증 헤더 추가

현재 템플릿의 `prometheus.yml`은 A안을 전제로 추가되어 있습니다.

