## PostgreSQL (CloudNativePG) - 설치 + Cluster CR 템플릿

온프레미스에서는 PostgreSQL을 “순수 StatefulSet”로 직접 HA 구성하기보다, **Operator(CloudNativePG)**를 권고합니다.

---

## 1) Operator 설치(Helm)

```bash
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update

helm install cnpg cnpg/cloudnative-pg \
  --namespace cnpg-system --create-namespace
```

---

## 2) Cluster 생성

> 스토리지 클래스는 Rook-Ceph의 `rook-ceph-block`(RBD) 기준입니다.

```bash
kubectl apply -f k8s-onprem/03-data-services/postgresql/cluster.yaml
```

접속 정보 Secret 확인:

```bash
kubectl -n bems-data get secret bems-postgres-app -o yaml
```

