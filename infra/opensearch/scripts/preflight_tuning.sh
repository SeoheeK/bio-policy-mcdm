#!/usr/bin/env bash
set -euo pipefail

## OpenSearch 노드 사전 튜닝(모든 노드에서 1회)
## - vm.max_map_count
## - swap off
## - THP 비활성화(권장)
## - ulimit 힌트

if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

# 1) vm.max_map_count
sysctl -w vm.max_map_count=262144
grep -q "vm.max_map_count" /etc/sysctl.conf || echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# 2) swap off
swapoff -a || true
sed -i.bak '/\sswap\s/s/^/#/' /etc/fstab || true

# 3) THP 비활성화(가능한 경우)
if [[ -d /sys/kernel/mm/transparent_hugepage ]]; then
  echo never > /sys/kernel/mm/transparent_hugepage/enabled || true
  echo never > /sys/kernel/mm/transparent_hugepage/defrag || true
fi

cat <<'EOF'
✅ preflight_tuning 완료

추가 권장(수동 확인):
- ulimit -n 65535 이상
- systemd 서비스 LimitNOFILE/LimitNPROC 설정(템플릿 포함)
- 방화벽: 9200/9300 노드 간 통신 허용
EOF

