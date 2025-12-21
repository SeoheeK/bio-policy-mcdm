## 02-storage (온프레미스) - Rook-Ceph 설치/스토리지클래스

본 디렉토리는 BEMS 온프레미스 환경에서 **Rook-Ceph**를 통해
- RBD(Block) 기반 PVC
- CephFS(Shared FS) 기반 PVC
를 제공하기 위한 “적용 가능한 템플릿”을 포함합니다.

---

## 0) 전제
- 클러스터: kubeadm + containerd + Calico
- 스토리지 노드: OSD로 사용할 디스크가 OS 디스크와 분리되어 있음(예: `/dev/sdb` 등)
- 네임스페이스: `rook-ceph` 사용

---

## 1) Rook-Ceph 설치(Helm 권고)

> 버전은 조직 표준에 맞게 고정하세요. 아래는 예시입니다.

```bash
helm repo add rook-release https://charts.rook.io/release
helm repo update

helm install rook-ceph rook-release/rook-ceph \
  --namespace rook-ceph --create-namespace
```

설치 확인:

```bash
kubectl -n rook-ceph get pods
```

---

## 2) CephCluster 생성(필수)

1) `rook-ceph/cephcluster.yaml`의 디바이스(`/dev/sdb` 등)를 실제 장비에 맞게 수정  
2) 적용:

```bash
kubectl apply -f k8s-onprem/02-storage/rook-ceph/cephcluster.yaml
```

상태 확인:

```bash
kubectl -n rook-ceph get cephcluster
kubectl -n rook-ceph get cephblockpool,cephfilesystem
```

---

## 3) Block Pool 및 StorageClass(RBD)

```bash
kubectl apply -f k8s-onprem/02-storage/rook-ceph/cephblockpool.yaml
kubectl apply -f k8s-onprem/02-storage/rook-ceph/storageclass-rbd.yaml
```

원하면 기본 StorageClass로 지정:

```bash
kubectl patch storageclass rook-ceph-block -p \
  '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

---

## 4) CephFS 및 StorageClass(공유 볼륨이 필요할 때만)

```bash
kubectl apply -f k8s-onprem/02-storage/rook-ceph/cephfilesystem.yaml
kubectl apply -f k8s-onprem/02-storage/rook-ceph/storageclass-cephfs.yaml
```

---

## 5) 운영 도구(선택)

```bash
kubectl apply -f k8s-onprem/02-storage/rook-ceph/toolbox.yaml
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph status
```

