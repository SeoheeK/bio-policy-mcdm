// Replica Set 초기화 및 사용자 생성 스크립트(Primary에서 실행)
//
// 사용 예:
//   mongosh --host 10.10.21.20:27017 < init_replicaset_and_users.js
//
// 환경변수(필수):
//   MONGO_ADMIN_PASSWORD
//   MONGO_APP_PASSWORD

const adminPwd = process.env.MONGO_ADMIN_PASSWORD;
const appPwd = process.env.MONGO_APP_PASSWORD;

if (!adminPwd || !appPwd) {
  throw new Error("환경변수 MONGO_ADMIN_PASSWORD, MONGO_APP_PASSWORD 를 설정하세요.");
}

// 1) Replica Set 초기화
try {
  rs.status();
  print("Replica Set은 이미 초기화되어 있습니다.");
} catch (e) {
  print("Replica Set 초기화를 수행합니다...");
  rs.initiate({
    _id: "bems-replica-set",
    members: [
      { _id: 0, host: "10.10.21.20:27017", priority: 2 },
      { _id: 1, host: "10.10.21.21:27017", priority: 1 },
      { _id: 2, host: "10.10.21.22:27017", priority: 1 },
    ],
  });
}

// 2) 관리자 사용자 생성
db = db.getSiblingDB("admin");
const existingAdmin = db.getUser("admin");
if (!existingAdmin) {
  print("admin 사용자 생성...");
  db.createUser({
    user: "admin",
    pwd: adminPwd,
    roles: [{ role: "root", db: "admin" }],
  });
} else {
  print("admin 사용자는 이미 존재합니다.");
}

// 3) 애플리케이션 사용자 생성
db = db.getSiblingDB("bems_documents");
const existingApp = db.getUser("bems_app");
if (!existingApp) {
  print("bems_app 사용자 생성...");
  db.createUser({
    user: "bems_app",
    pwd: appPwd,
    roles: [{ role: "readWrite", db: "bems_documents" }],
  });
} else {
  print("bems_app 사용자는 이미 존재합니다.");
}

print("✅ 완료");

