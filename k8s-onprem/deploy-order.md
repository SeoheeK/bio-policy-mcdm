## 온프레미스 배포 순서(한 번에 적용 가능한 Runbook)

대상 흐름: `k8s-onprem/02-storage` → `k8s-onprem/03-data-services` → `k8s-onprem/04-application`

> 전제: kubeadm+Calico 클러스터가 이미 구성되어 있고, `kubectl`/`helm` 사용 가능

---

## 0) 공통 사전 점검

```bash
kubectl get nodes -o wide
kubectl get ns
helm version
```

---

## 1) 스토리지: Rook‑Ceph (02-storage)

### 1.1 Rook‑Ceph 설치(Helm)

```bash
helm repo add rook-release https://charts.rook.io/release
helm repo update

helm install rook-ceph rook-release/rook-ceph \
  --namespace rook-ceph --create-namespace
```

검증:

```bash
kubectl -n rook-ceph get pods
```

### 1.2 CephCluster 생성

1) 디스크 명칭 수정(필수): `k8s-onprem/02-storage/rook-ceph/cephcluster.yaml`의 `/dev/sdb`, `/dev/sdc`

```bash
kubectl apply -f k8s-onprem/02-storage/rook-ceph/cephcluster.yaml
```

검증:

```bash
kubectl -n rook-ceph get cephcluster
```

### 1.3 RBD StorageClass 생성

```bash
kubectl apply -f k8s-onprem/02-storage/rook-ceph/cephblockpool.yaml
kubectl apply -f k8s-onprem/02-storage/rook-ceph/storageclass-rbd.yaml
```

검증:

```bash
kubectl get storageclass
```

---

## 2) 데이터 서비스 (03-data-services)

### 2.1 공통 네임스페이스 생성

```bash
kubectl apply -f k8s-onprem/04-application/namespaces.yaml
```

검증:

```bash
kubectl get ns | egrep 'bems-prod|bems-data|bems-storage'
```

### 2.2 PostgreSQL (CloudNativePG)

Operator 설치:

```bash
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update

helm install cnpg cnpg/cloudnative-pg \
  --namespace cnpg-system --create-namespace
```

Cluster 적용:

1) `k8s-onprem/03-data-services/postgresql/cluster.yaml`의 `REPLACE_ME` 변경(또는 SealedSecret로 교체)

```bash
kubectl apply -f k8s-onprem/03-data-services/postgresql/cluster.yaml
```

검증:

```bash
kubectl -n bems-data get pods | grep bems-postgres
kubectl -n bems-data get svc | grep bems-postgres-rw
```

### 2.3 Redis (Sentinel, Bitnami)

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm install bems-redis bitnami/redis \
  --namespace bems-data \
  -f k8s-onprem/03-data-services/redis/values.yaml
```

검증:

```bash
kubectl -n bems-data get pods | grep bems-redis
kubectl -n bems-data get svc | grep bems-redis-master
```

### 2.4 Kafka (Strimzi)

Operator 설치:

```bash
helm repo add strimzi https://strimzi.io/charts/
helm repo update

helm install strimzi-kafka-operator strimzi/strimzi-kafka-operator \
  --namespace bems-data
```

Kafka CR 적용:

```bash
kubectl apply -f k8s-onprem/03-data-services/kafka/kafka.yaml
```

검증:

```bash
kubectl -n bems-data get kafka
kubectl -n bems-data get pods | egrep 'kafka-kafka|kafka-zookeeper'
kubectl -n bems-data get svc | grep kafka-kafka-bootstrap
```

### 2.5 MinIO (분산 모드)

```bash
helm repo add minio https://charts.min.io/
helm repo update

helm install bems-minio minio/minio \
  --namespace bems-storage \
  --create-namespace \
  -f k8s-onprem/03-data-services/minio/values.yaml
```

검증:

```bash
kubectl -n bems-storage get pods | grep bems-minio
kubectl -n bems-storage get svc | grep bems-minio
```

---

## 3) 애플리케이션 (04-application)

### 3.1 ConfigMap/Secret 적용

```bash
kubectl apply -f k8s-onprem/04-application/configmap.yaml
```

Secret은 예시 파일을 직접 적용하지 말고(커밋 금지), 최소한 아래 중 하나로 준비하세요:
- SealedSecret로 변환 후 적용
- 운영 환경에서 `kubectl create secret ...`로 생성

테스트/로컬 환경에서만 예시 적용(권고하지 않음):

```bash
kubectl apply -f k8s-onprem/04-application/secret.example.yaml
```

### 3.2 API/Worker 배포

```bash
kubectl apply -f k8s-onprem/04-application/deployments/api.yaml
kubectl apply -f k8s-onprem/04-application/deployments/worker.yaml
```

검증:

```bash
kubectl -n bems-prod get pods
kubectl -n bems-prod get svc
```

### 3.3 HPA 적용(Phase 1-2: CPU/메모리 기반)

```bash
kubectl apply -f k8s-onprem/04-application/hpa.yaml
kubectl -n bems-prod get hpa
```

### 3.4 NetworkPolicy 적용

```bash
kubectl apply -f k8s-onprem/04-application/networkpolicy-onprem.yaml
kubectl -n bems-prod get netpol
```

---

## 4) 모니터링(선택: kube-prometheus-stack 연동)

> kube-prometheus-stack 설치 후 적용하세요.

```bash
kubectl apply -f k8s-onprem/05-monitoring/servicemonitor.yaml
```

검증:
- Prometheus Targets에서 `bems-api`, `bems-worker` 스크랩 확인

