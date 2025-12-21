# Grafana 대시보드 확장(가이드)

이 저장소는 Grafana provisioning(데이터소스/대시보드 provider)을 포함합니다.

## 자동 프로비저닝

- Datasource: `provisioning/datasources/datasource.yml`
- Dashboard provider: `provisioning/dashboards/provider.yml`

## 추천 대시보드(가져오기)

운영 편의를 위해 Grafana.com 대시보드 ID를 사용해 Import 하는 방식을 권장합니다.

- Node Exporter Full: 1860
- PostgreSQL Exporter: 9628 (또는 455)
- Redis Exporter: 11835
- MongoDB Exporter(Percona): 12079 (환경에 따라 다름)
- Elasticsearch Exporter(OpenSearch): 14191 (또는 exporter/버전에 맞는 대시보드)
- MinIO: 13502 (MinIO 대시보드)

> 환경/버전/metric 이름에 따라 일부 패널은 수정이 필요할 수 있습니다.

