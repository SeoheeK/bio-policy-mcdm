## Kafka (Strimzi) - Operator 설치 + Kafka CR 템플릿

온프레미스 Kafka는 **Strimzi Operator** 기반 구성을 권고합니다.

---

## 1) Operator 설치(Helm)

```bash
helm repo add strimzi https://strimzi.io/charts/
helm repo update

helm install strimzi-kafka-operator strimzi/strimzi-kafka-operator \
  --namespace bems-data
```

CRD 설치 확인:

```bash
kubectl api-resources | grep kafka.strimzi
```

---

## 2) Kafka 클러스터 생성

```bash
kubectl apply -f k8s-onprem/03-data-services/kafka/kafka.yaml
```

부트스트랩 서비스 확인:

```bash
kubectl -n bems-data get svc | grep kafka-kafka-bootstrap
```

