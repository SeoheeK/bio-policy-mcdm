## MinIO (분산 모드) - Helm values 템플릿

온프레미스에서 “S3 호환 객체 스토리지”는 MinIO를 권고합니다.

---

## 1) 설치(Helm)

```bash
helm repo add minio https://charts.min.io/
helm repo update

helm install bems-minio minio/minio \
  --namespace bems-storage \
  --create-namespace \
  -f k8s-onprem/03-data-services/minio/values.yaml
```

---

## 2) 접속/버킷
- 서비스: `bems-minio`(ClusterIP, 필요 시 Ingress/NodePort 별도 구성)
- 기본 버킷: `bems-data-lake`(values에서 생성)

