# OpenSearch Security (TLS/인증) 초기화

이 폴더는 인증서 배치/생성 가이드를 제공합니다.

## 최소 요구 파일(각 노드의 /opt/opensearch/config/certs/)

- `root-ca.pem` : 루트 CA(신뢰 체인)
- `node.pem` / `node-key.pem` : 노드 인증서/키(각 노드별)
- `admin.pem` / `admin-key.pem` : securityadmin 실행용 관리자 인증서/키(초기화용)

> 인증서 Subject(CN/OU/O/...)는 `opensearch.yml`의 `plugins.security.nodes_dn`, `admin_dn`과 일치해야 합니다.

## 간단 생성(예시)

운영에서는 사내 PKI/CA를 권장합니다. 빠른 테스트를 위해서는 OpenSSL로 self-signed CA를 만들고 노드별 cert를 발급할 수 있습니다.

## Security 초기화(초기 1회)

`scripts/init_security.sh`를 Master-1 등 한 곳에서 실행하여 `securityadmin.sh`를 호출합니다.

