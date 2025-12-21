## 03-data-services (온프레미스) - 설치 + CR/values 템플릿

이 디렉토리는 온프레미스에서 “클러스터 내부 데이터 서비스”를 운영하기 위한 **설치 가이드 + 적용 가능한 템플릿**을 제공합니다.

### 네임스페이스
- `bems-data`: PostgreSQL/Redis/Kafka
- `bems-storage`: MinIO

먼저 네임스페이스가 없으면 생성:

```bash
kubectl apply -f k8s-onprem/04-application/namespaces.yaml
```

---

## 1) PostgreSQL (CloudNativePG 권고)
- 경로: `postgresql/`
- 설치: Helm(Operator) + Cluster CR

---

## 2) Redis (Sentinel, Bitnami Helm 권고)
- 경로: `redis/`
- 설치: Helm + values.yaml

---

## 3) Kafka (Strimzi Operator)
- 경로: `kafka/`
- 설치: Helm(Operator) + Kafka CR

---

## 4) MinIO (분산 모드, Helm)
- 경로: `minio/`
- 설치: Helm + values.yaml

