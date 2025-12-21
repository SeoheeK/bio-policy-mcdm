# OpenSearch 메트릭 수집(Exporter)

OpenSearch는 Elasticsearch 계열 메트릭 모델과 유사하므로, 온프레미스에서는 보통 `elasticsearch_exporter`로 수집합니다.

## 구성

- Exporter 포트: `9114/tcp`
- 대상(OpenSearch): `https://10.10.21.50:9200` (예시)

## 산출물

- `conf/opensearch_exporter.env.example`
- `systemd/opensearch_exporter.service`
- `scripts/install_opensearch_exporter.sh`

