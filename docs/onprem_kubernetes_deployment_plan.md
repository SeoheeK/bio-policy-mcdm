## 온프레미스 환경 Kubernetes 배포 구성 재설계(확정판 초안)

본 문서는 “AWS 미사용(온프레미스)” 전제를 기준으로, 기존 `k8s/` 템플릿을 **온프레미스 운영 가능한 형태로 전환**한 설계/배포 가이드입니다.

---

## 1. 전환 요약

### 1.1 Before/After
- **Before(AWS 전제)**: EKS + RDS/ElastiCache/MSK + S3 + Secrets Manager + ACM/Route53
- **After(온프레미스)**: Self-managed Kubernetes(kubeadm 권장) + PostgreSQL/Redis/Kafka 자체 구축 + MinIO/Ceph + Sealed Secrets/Vault + cert-manager + 내부 DNS

### 1.2 핵심 결정(Phase 1 권고)
- **Kubernetes 설치**: kubeadm + containerd + Calico(CNI)
- **스토리지**: Rook-Ceph(블록/RBD 기본, 필요 시 CephFS)
- **Ingress**: NGINX Ingress Controller
  - 외부 진입은 **NodePort + 하드웨어 LB 포워딩** 또는 **MetalLB**
- **인증서**: cert-manager(+ Let’s Encrypt) *(외부 DNS/공인 도메인/HTTP-01 가능 여부 확인 필요)*
- **Secret**: Sealed Secrets(Phase 1-2), Vault(Phase 3 검토)
- **HPA**: Phase 1-2는 CPU/메모리 기반(단순화), Phase 3에 KEDA 검토

---

## 2. 리포지토리 산출물 구조(온프레미스 확정판)

`k8s-onprem/` 디렉토리에 온프레미스 전용 산출물을 정리합니다.

```
k8s-onprem/
  00-prerequisites/        # 하드웨어/네트워크 요구사항(문서)
  01-cluster-setup/         # kubeadm/Calico 설치 가이드(문서/설정)
  02-storage/               # Rook-Ceph 설치/StorageClass
  03-data-services/         # Postgres/Redis/Kafka/MinIO(Operator/Helm 기준)
  04-application/           # BEMS API/Worker/Ingress/HPA/NetworkPolicy
  05-monitoring/            # kube-prometheus-stack + ServiceMonitor/Rule
  06-security/              # Sealed Secrets / 인증서 / 런북
```

---

## 3. 즉시 수정해야 하는 운영 포인트(중요)

### 3.1 ConfigMap의 `${VAR}` 치환 문제
- Kubernetes `envFrom(ConfigMap)`는 `${PASSWORD}` 같은 문자열 치환을 하지 않습니다.
- 따라서 DSN은:
  - (권고) Deployment `env.value`에서 `$(VAR)`로 조합하거나
  - 앱에서 host/port/user/password를 조합해야 합니다.

### 3.2 `/metrics` 외부 노출 금지(원칙)
- Prometheus는 ServiceMonitor로 내부 수집
- 디버깅은 port-forward 또는 내부 Ingress+VPN+Auth로 분리

---

## 4. 데이터 서비스(온프레미스) 권고 배포 방식

> 실제 CRD/Operator 매니페스트는 환경마다 차이가 커서 “Helm/Operator 설치 + CR” 형태로 운영하는 것을 권고합니다.

- PostgreSQL: Zalando Postgres Operator(또는 CloudNativePG)
- Redis: Sentinel(Helm/Operator)
- Kafka: Strimzi Operator
- Object Storage: MinIO(Helm/Operator) + Ceph(Rook) 스토리지

---

## 5. 다음 단계(2주)
- 온프레미스 인프라 결정서(IDR) 확정:
  - kubeadm vs Rancher
  - 외부 진입(하드웨어 LB 포워딩 vs MetalLB)
  - Let’s Encrypt 사용 가능 여부(외부에서 HTTP-01 접근 가능?) → 불가 시 내부 CA로 전환
- `k8s-onprem/04-application`에 네임스페이스 분리(bems-prod/bems-data/bems-storage) 확정 및 NetworkPolicy 최종화

