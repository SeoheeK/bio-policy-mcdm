## Redis (Sentinel) - Bitnami Helm values 템플릿

온프레미스에서 Redis HA는 “Sentinel 활성화” 구성을 권고합니다.

---

## 1) 설치(Helm)

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm install bems-redis bitnami/redis \
  --namespace bems-data \
  -f k8s-onprem/03-data-services/redis/values.yaml
```

---

## 2) 접속 정보
- Helm 차트가 생성한 Secret(릴리즈명 기준)을 확인하세요.

