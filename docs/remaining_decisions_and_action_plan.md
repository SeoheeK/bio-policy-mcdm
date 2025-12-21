## 현재 남은 결정/구현 사항 및 액션 플랜(요약본)

본 문서는 사용자가 정리한 “Phase별 결정/구현 사항”을 **리포지토리 산출물(k8s 템플릿, 운영 문서)**과 연결한 실행 계획입니다.

---

## 2. 현재 남은 결정/구현 사항

### 2.1 즉시 결정 필요(Phase 1 시작 전)

#### 2.1.1 HPA 자동 스케일링 전략
- **권고(Phase 1-2)**: **옵션 C(CPU/메모리만)**으로 시작(안정화 우선)
- **확장(Phase 3)**: KEDA 도입 검토(실제 부하 패턴 기반)

**리포지토리 반영**
- Phase 1용 HPA(옵션 C): `k8s/hpa.yaml`

#### 2.1.2 Ingress Controller 선택
- **권고**: NGINX Ingress Controller

**리포지토리 반영**
- Ingress 템플릿(Rewrite 제거, /metrics 노출 제거): `k8s/ingress.yaml`

#### 2.1.3 모니터링 스택 확정
- **권고**: kube-prometheus-stack(Helm)
  - Prometheus Operator/Grafana/AlertManager/node-exporter/kube-state-metrics

**리포지토리 반영**
- ServiceMonitor: `k8s/monitoring/servicemonitor.yaml`
- PrometheusRule(통합): `k8s/monitoring/prometheus-rules.yaml`

---

### 2.2 Phase 1 중 구현 필요

#### 2.2.1 Secret 관리 전략
- **권고(Phase 1 파일럿)**: 수동 생성(kubectl) + Git 완전 제외
- **권고(Phase 2 베타)**: Sealed Secrets(또는 Vault) 기반 GitOps 정착
- **검토(Phase 3 운영)**: Vault(중앙 집중 + 감사 + 동적 시크릿) 전환

**리포지토리 반영**
- Secret 예시(커밋 금지): `k8s/secret.example.yaml`
- 온프레미스 전환 설계서(요약): `docs/onprem_kubernetes_deployment_plan.md`

#### 2.2.2 네트워크 토폴로지 확정
- **권고(Phase 1-2)**: 온프레미스 데이터 서비스(클러스터 내부) + NetworkPolicy 엄격 적용
- 즉시 작업:
  - 온프레미스 네트워크 대역/CIDR 확정(예: 192.168.100.0/24)
  - 외부 진입(하드웨어 LB 포워딩 vs MetalLB) 결정
  - NetworkPolicy egress를 “필수 목적지(내부 서비스 + 외부 HTTPS)”로 최소화

**리포지토리 반영**
- 기본 NetworkPolicy(클러스터 내부 서비스 가정): `k8s/networkpolicy.yaml`
  - 온프레미스 확정 후 네임스페이스 분리(bems-prod/bems-data/bems-storage) 버전으로 추가 분기 권고

---

### 2.3 Phase 2 중 구현 필요

#### 2.3.1 고급 Ingress 설정
- Rate Limiting / CORS / Body size / Timeout

**리포지토리 반영**
- 기본 템플릿은 `k8s/ingress.yaml`에 포함(Phase별 값 조정)

#### 2.3.2 멀티 환경 구성
- dev/staging/prod 네임스페이스 분리 + Kustomize 구조

**리포지토리 작업(다음 단계)**
- `k8s-confirmed/base` + `k8s-confirmed/overlays` 구조 생성(요청 시 확정판으로 생성)

#### 2.3.3 /metrics 내부 접근
- 기본: port-forward
- 지속 필요: 내부 Ingress + VPN + Basic Auth

**리포지토리 반영**
- 기본 원칙: `/metrics`는 Ingress로 노출하지 않음(내부 스크랩)

---

## 4. 다음 단계 액션 플랜(2주)

### 4.1 즉시 실행(2주 이내)
- 인프라 스택 확정 회의 및 **Infrastructure Decision Record(IDR)** 산출
- (온프레미스) kubeadm/Rancher 선택, 외부 진입 방식(NodePort+LB vs MetalLB) 확정
- (온프레미스) 네트워크 대역/방화벽 정책/내부 DNS 확정

### 4.2 Phase 1 시작과 함께
- (온프레미스) Kubernetes 프로비저닝(kubeadm) + Calico
- 핵심 Add-ons 설치(NGINX Ingress / kube-prometheus-stack / Sealed Secrets / cert-manager)
- 네임스페이스/기본 매니페스트 적용

