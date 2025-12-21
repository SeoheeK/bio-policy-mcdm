# Neo4j 메트릭 수집(내장 Prometheus endpoint)

Neo4j 5는 별도 exporter 없이 **내장 Prometheus endpoint**를 활성화할 수 있습니다.

## 설정(이미 템플릿 반영)

`infra/neo4j/conf/neo4j.core*.conf.template`에 아래가 포함되어 있습니다.

- `server.metrics.prometheus.enabled=true`
- `server.metrics.prometheus.endpoint=0.0.0.0:2004`

## Prometheus

`infra/monitoring/prometheus/prometheus.yml`에 `job_name: neo4j`로 추가되어 있습니다.

