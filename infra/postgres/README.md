# PostgreSQL 15 HA (Patroni + etcd + HAProxy/PgBouncer)

온프레미스 PostgreSQL 15.5를 **Patroni + etcd**로 자동 페일오버 구성하고, 애플리케이션은 **단일 접속 엔드포인트**(HAProxy 또는 PgBouncer)로 연결하도록 구성합니다.

## 목표 구성(요약)

- PostgreSQL 노드(예: 2대)
  - `10.10.21.10` (node1)
  - `10.10.21.11` (node2)
- etcd(3대 권장, DCS)
  - `10.10.21.70`, `10.10.21.71`, `10.10.21.72`
- Patroni REST API
  - 각 DB 노드 `:8008`
- 단일 접속 엔드포인트(선택)
  - **HAProxy**: Primary용 5432, Read-only용 5433 라우팅
  - **PgBouncer**: 커넥션 풀링 (HAProxy 앞/뒤 어디든 가능, 보통 HAProxy 뒤)
  - **VIP(옵션)**: Keepalived로 HAProxy 또는 PgBouncer에 VIP 부여

## 빠른 적용 순서(권장)

1. etcd 3노드 구성 (`etcd/`)
2. PostgreSQL + Patroni 설치/설정 (`patroni/`, `scripts/`)
3. HAProxy 구성(Primary/Replica 라우팅) (`haproxy/`)
4. (선택) PgBouncer 적용(트랜잭션 풀 모드) (`pgbouncer/`)
5. (선택) VIP(Keepalived)로 단일 IP 제공 (`keepalived/`)

## 보안

- 모든 비밀번호/토큰은 환경변수로 주입하세요. 샘플: `../secrets/env.example`
- TLS는 운영 환경에서 강력 권장(본 템플릿은 “구동 우선”이며 TLS 확장은 별도 문서화)

