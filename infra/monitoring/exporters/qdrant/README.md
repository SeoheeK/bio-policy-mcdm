# Qdrant 메트릭 수집

Qdrant는 별도 exporter 없이 **내장 Prometheus 메트릭 엔드포인트**를 제공합니다.

## Prometheus

- 대상: `http://<qdrant-host>:6333/metrics`

이미 `infra/monitoring/prometheus/prometheus.yml`에 `job_name: qdrant`로 추가되어 있습니다.

