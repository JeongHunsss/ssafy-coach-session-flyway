# "제 로컬에선 잘 되는데요?"를 줄이는 Flyway 실습

싸피 15기 코치세션 **Flyway 사용법** 실습 레포입니다.
빈 DB에 V1을 적용하는 것부터 체크섬 오류, 버전 충돌, 기존 DB에 붙이는 Baseline까지 **단계별 브랜치**로 따라갈 수 있습니다.

> 핵심 한 문장: **Git은 코드의 변경 이력을, Flyway는 각 DB의 적용 이력을 관리합니다.**

---

## 목차

1. [준비물](#준비물)
2. [실습 시작하기](#실습-시작하기)
3. [브랜치 한눈에 보기](#브랜치-한눈에-보기)
4. [단계별 설명](#단계별-설명)

---

## 준비물

| 항목 | 버전 / 비고 |
|------|-------------|
| JDK | 17 이상 (없으면 Gradle이 JDK 17을 자동으로 내려받습니다) |
| MySQL 8 | **로컬에 설치된 MySQL** 로컬 MySQL이 없으면 Docker로 대신 띄울 수 있습니다 → [MySQL 준비](#2-mysql-준비) |
| IDE | IntelliJ, VS Code 등 아무거나 |
| DB 클라이언트 | MySQL Workbench, DBeaver 등. 이력 테이블과 테이블 구조를 확인할 때 씁니다 |

프로젝트 구성

- Spring Boot 3.5 / Gradle / Spring Data JPA / MySQL 8
- 엔티티는 `User` 하나뿐인 최소 구성입니다.

```
src/main/
├── java/com/ssafy/flyway/
│   ├── FlywayDemoApplication.java
│   └── user/User.java
└── resources/
    ├── application.yml
    └── db/migration/          ← 마이그레이션 파일 위치 (Spring Boot 기본 경로)
```

> JDBC URL에 `createDatabaseIfNotExist=true`를 붙여 두어서, `mydb`를 직접 만들지 않아도 됩니다.

---

## 실습 시작하기

### 1. 레포 받기

```bash
git clone https://github.com/JeongHunsss/ssafy-coach-session-flyway.git
```

```bash
cd ssafy-coach-session-flyway
```

### 2. MySQL 준비

**로컬 MySQL이 있다면 (기본)** — MySQL이 실행 중인지만 확인하면 됩니다. `mydb`는 앱이 알아서 만듭니다.

> 이미 `mydb`가 있고 안에 테이블이 있다면, 깨끗한 상태에서 시작하도록 `DROP DATABASE IF EXISTS mydb;`로 먼저 초기화하세요.

**로컬 MySQL이 없다면 (선택)** — Docker로 띄웁니다. 레포의 `docker-compose.yml`이 같은 접속 정보(`root` / `ssafy`, 3306)로 MySQL 8을 띄워줍니다.

```bash
docker compose up -d
```

> 로컬 MySQL이 이미 3306 포트를 쓰고 있으면 컨테이너가 뜨지 않습니다. 둘 중 **하나만** 쓰세요.

### 3. step1 브랜치로 이동

```bash
git switch step1
```

### 4. 애플리케이션 실행

IDE에서 `FlywayDemoApplication`을 실행하거나, 터미널에서 실행합니다.

```bash
./gradlew bootRun
```

> Windows CMD/PowerShell에서는 `gradlew.bat bootRun` 또는 `.\gradlew bootRun`

이 앱은 웹 서버가 아니라 **"뜰 때 마이그레이션이 도는지"만 보는 용도**입니다. 로그를 확인한 뒤 `Ctrl + C`로 종료하세요.

### 5. 다음 단계로

```bash
git switch step2
```

브랜치를 바꾸고 → 실행하고 → 로그와 DB를 확인하는 것을 반복합니다.

> **⚠️ IntelliJ로 실행한다면 — 브랜치를 바꿀 때마다 Gradle을 다시 로드하세요**
>
> 이 레포는 브랜치마다 `build.gradle`이 다릅니다. (step0만 Flyway 의존성이 없음)
> IntelliJ는 **마지막으로 Gradle을 로드했을 때의 의존성**으로 실행하기 때문에, `git switch` 후 다시 로드하지 않으면 이전 브랜치의 의존성으로 실행됩니다.
>
> - `git switch` 후 오른쪽 위에 뜨는 **코끼리 아이콘(Load Gradle Changes)** 을 누르거나 `Ctrl + Shift + O`
> - 다시 로드하지 않으면 생기는 일
>   - **step0인데 Flyway가 실행됨** → 빈 `flyway_schema_history`가 생겨서 step7에서 오류가 안 나고 V2가 그냥 적용됨
>   - **step1~9인데 Flyway가 실행 안 됨** → 로그에 Flyway 관련 줄이 하나도 없고 `Schema-validation: missing column [...]` (JPA validate 오류)로 실패
>
> 터미널에서 `./gradlew bootRun`으로 실행하면 매번 현재 `build.gradle`을 읽으므로 이 문제가 없습니다.

> **⚠️ 꼭 지켜주세요**
> - **step1 → step6 (→ step9)은 순서대로** 진행하세요. 같은 DB에 이력이 쌓이면서 진행되는 구조입니다.
> - 이전 단계로 돌아가거나 처음부터 다시 하고 싶으면 DB 클라이언트에서 `DROP DATABASE IF EXISTS mydb;`로 DB를 초기화하세요. 다음 실행 때 빈 `mydb`가 자동으로 다시 만들어집니다.
> - `step0` 브랜치는 Flyway가 없는 **"도입 전" 상태**로, step7 Baseline 실습용입니다. **실습은 step1부터** 시작하세요. step1 전에 step0을 실행하면 `ddl-auto: update`가 테이블을 만들어버려서 step1이 실패합니다. (이 상황은 step7에서 일부러 재현합니다. [step0은 왜 있나요?](#step0--flyway-도입-전))

---

## 브랜치 한눈에 보기

| 브랜치 | 내용 | 실행 결과 |
|--------|------|-----------|
| `step0` | Flyway 도입 전. `ddl-auto: update` (step7 준비용, 실습은 step1부터) | ✅ (JPA가 테이블 생성) |
| `step1` | Flyway 설정 + `V1__init.sql` | ✅ V1 적용 → 재실행 시 "up to date" |
| `step2` | `V2__add_user_nickname.sql` | ✅ V2만 적용 |
| `step3` | 이미 적용된 V1을 수정 | ❌ **체크섬 오류** |
| `step4` | V1 원복 + `V3__add_user_phone.sql` | ✅ V3만 적용 |
| `step5` | 두 사람이 각자 V4를 만들어 머지 | ❌ **버전 중복 오류** |
| `step6` | 나중에 머지된 쪽을 V5로 변경 | ✅ V4, V5 적용 |
| `step7` | 이미 테이블이 있는 DB에 Flyway만 붙임 | ❌ **non-empty schema 오류** |
| `step8` | `V1__baseline.sql` + `baseline-on-migrate` | ✅ V1은 기록만, V2부터 실행 |
| `step9` | (step6 다음) `dev` 프로필에서만 테스트 데이터 INSERT | ✅ 기본 실행엔 없음, dev 실행 시에만 데이터 들어감 |

step1→step6은 step0 위에, step7→step8은 따로 step0 위에 커밋을 하나씩 쌓은 구조라서, 단계별 변경 내용은 이렇게 볼 수 있습니다.

```bash
git diff step1 step2
```

---

## 단계별 설명

### step0 — Flyway 도입 전

대부분의 팀이 쓰고 있는 상태입니다. `application.yml`에 `ddl-auto: update`만 있고, 엔티티를 보고 JPA가 테이블을 알아서 만듭니다.

- 편하지만 **뭘 바꿨는지 기록이 남지 않고**, 컬럼 삭제·이름 변경은 반영되지 않습니다.

**step1부터 시작하는데 step0은 왜 있나요?**

1. **step7·step8(Baseline 실습)에서 "이미 테이블이 있는 DB"를 만들 때 씁니다.**
   step0을 한 번 실행하면 JPA가 `users` 테이블을 만들어 줍니다. "`ddl-auto: update`로 개발하다가 Flyway를 붙이려는" 여러분 프로젝트와 같은 상태입니다.
2. **모든 브랜치의 공통 시작점입니다.** 프로젝트 뼈대가 여기 있고, step1과 step7이 모두 여기서 갈라집니다.
   ```
   step0 ─┬─ step1 → step2 → step3 → step4 → step5 → step6 → step9   (빈 DB에서 시작하는 실습 + 환경별 테스트 데이터)
          └─ step7 → step8                                           (기존 DB에 붙이는 Baseline 실습)
   ```

그래서 **step1~step6 실습만 한다면 step0은 실행할 필요가 없습니다.** 오히려 step1 전에 실행하면 테이블이 미리 생겨서 step1이 실패하니 주의하세요.

---

### step1 — Flyway 붙이고 V1 적용하기

**바뀐 것**

`build.gradle`

```gradle
implementation 'org.flywaydb:flyway-core'
implementation 'org.flywaydb:flyway-mysql'   // MySQL을 쓰면 필수
```

> Spring Boot 4.x라면 `flyway-core` 대신 `org.springframework.boot:spring-boot-starter-flyway`를 넣어야 합니다. `flyway-core`만 넣으면 **에러 없이 마이그레이션이 아예 안 돕니다.**

`application.yml`

```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: validate      # create / update 아님!
  flyway:
    enabled: true             # 기본값이 true라 생략 가능
```

- **DB를 바꾸는 건 Flyway, JPA는 검사만** 하는 역할 분담입니다.

`src/main/resources/db/migration/V1__init.sql`

```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL
);
```

파일 이름 규칙: `V` + `버전` + `__`(**밑줄 두 개**) + `설명` + `.sql`

**해보기**

1. 실행합니다. 로그에 이렇게 뜹니다.
   ```
   Migrating schema `mydb` to version "1 - init"
   Successfully applied 1 migration to schema `mydb`, now at version v1
   ```
2. DB에서 이력 테이블을 확인합니다.
   ```sql
   SELECT version, description, success FROM mydb.flyway_schema_history;
   ```
   `users` 테이블과 함께 `flyway_schema_history`가 생기고, V1이 기록돼 있습니다.
3. **한 번 더 실행합니다.** 이번엔 이렇게 뜹니다.
   ```
   Schema `mydb` is up to date. No migration necessary.
   ```
   **아무 일도 안 일어나는 게 포인트**입니다. V1을 이미 돌렸다는 걸 Flyway가 기억하고 있어서 다시 실행하지 않습니다.

---

### step2 — V2로 컬럼 추가하기

**바뀐 것**

- `V1__init.sql`은 **건드리지 않고** 새 파일을 추가합니다.

  `V2__add_user_nickname.sql`
  ```sql
  ALTER TABLE users ADD COLUMN nickname VARCHAR(50);
  ```
- `User` 엔티티에 `nickname` 필드 추가

**해보기**

1. 실행하면 **V1은 건너뛰고 V2만** 적용됩니다.
   ```
   Migrating schema `mydb` to version "2 - add user nickname"
   Successfully applied 1 migration to schema `mydb`, now at version v2
   ```
2. 이력 테이블이 두 줄이 됐는지 확인합니다.

**보너스 — validate가 일하는 장면**

엔티티에만 필드를 추가하고 마이그레이션 파일은 안 만들면 어떻게 될까요? `User`에 아무 필드나 하나 추가하고 실행해보세요.

```java
private String address;
```

```
Schema-validation: missing column [address] in table [users]
```

서버가 뜨지 않습니다. **마이그레이션 파일을 깜빡하면 배포 전에 로컬에서 바로 알 수 있다**는 뜻입니다. 확인했으면 추가한 필드를 지우고 다음 단계로 가세요.

---

### step3 — 일부러 깨뜨리기: 체크섬 오류

> ❌ 이 브랜치는 **실행하면 실패하는 게 정상**입니다.

**바뀐 것**

이미 적용된 `V1__init.sql`에 컬럼을 슬쩍 추가했습니다.

```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20)          -- ← 추가
);
```

**해보기**

실행하면 이런 오류로 서버가 뜨지 않습니다.

```
Migration checksum mismatch for migration version 1
-> Applied to database : 1234567890
-> Resolved locally    : -987654321
Either revert the changes to the migration, or run repair to update the schema history.
```

**왜 이럴까요?**

- Flyway는 파일을 실행할 때 내용의 **체크섬**(요약값)을 이력 테이블에 같이 기록합니다.
  ```sql
  SELECT version, checksum FROM mydb.flyway_schema_history;
  ```
- 다음 실행 때 파일의 체크섬을 다시 계산해서 비교하고, 다르면 멈춥니다.
- 이미 적용된 파일을 고쳐도 **내 DB는 안 바뀝니다** (이미 실행이 끝났으니까요). 그런데 팀원이 새로 DB를 만들면 고쳐진 버전이 실행되죠. 그 순간 **내 DB와 팀원 DB가 달라집니다.** Flyway는 이걸 막으려고 오류를 냅니다.

> **절대 하지 마세요**
> - **`repair`**: 체크섬을 지금 파일 기준으로 덮어써서 **오류만 없앱니다.** 내 DB엔 phone이 없는데 파일엔 있는 상태가 그대로 남아, 제일 찾기 어려운 상태가 됩니다.
> - **`clean`**: 스키마의 **모든 테이블을 삭제**합니다. 기본으로 막혀 있으니(`clean-disabled: true`) 풀지 마세요.

---

### step4 — 올바르게 복구하기

**바뀐 것**

- `V1__init.sql`을 **원래대로 되돌렸습니다.**
- 변경은 **새 파일로** 만듭니다.

  `V3__add_user_phone.sql`
  ```sql
  ALTER TABLE users ADD COLUMN phone VARCHAR(20);
  ```
- `User` 엔티티에 `phone` 필드 추가

**해보기**

실행하면 V3만 적용되고 정상으로 돌아옵니다.

```
Successfully applied 1 migration to schema `mydb`, now at version v3
```

> **실습 정리: 새 변경은 새 파일로. 이미 돌린 파일은 건드리지 않는다.**

---

### step5 — 팀에서 깨뜨리기: 같은 버전 번호 충돌

> ❌ 이 브랜치는 **실행하면 실패하는 게 정상**입니다.

**상황**

A와 B가 같은 날 각자 브랜치를 팠습니다. 둘 다 최신이 V3인 걸 보고 다음 번호로 V4를 잡았어요.

```
A 브랜치: V4__add_user_profile_image.sql
B 브랜치: V4__add_user_bio.sql
```

**파일명이 다르니 Git에서는 충돌이 안 나고** 둘 다 조용히 머지됩니다. 이 브랜치가 그 머지된 상태입니다.

**해보기**

```
Found more than one migration with version 4
Offenders:
-> .../db/migration/V4__add_user_bio.sql (SQL)
-> .../db/migration/V4__add_user_profile_image.sql (SQL)
```

Flyway 입장에서는 **V4가 두 개**라서 어느 것도 실행하지 않고 멈춥니다.

---

### step6 — 버전 충돌 해결하기

**바뀐 것**

나중에 머지된 B의 파일을 V5로 이름을 바꿨습니다.

```
V4__add_user_profile_image.sql
V5__add_user_bio.sql          ← V4에서 변경
```

**해보기**

실행하면 V4, V5가 순서대로 적용됩니다.

```
Migrating schema `mydb` to version "4 - add user profile image"
Migrating schema `mydb` to version "5 - add user bio"
Successfully applied 2 migrations to schema `mydb`, now at version v5
```

**생각해볼 것 — 이름을 바꾸는 것도 위험할 수 있습니다**

B가 자기 로컬에서 이미 `V4__add_user_bio.sql`을 적용해뒀다면, B의 이력 테이블엔 "V4 = add user bio"로 기록돼 있습니다. 파일이 V5가 되면 B의 로컬 DB는 꼬이고, 결국 DB를 지우고 다시 만들어야 합니다.

그래서 팀이 크면 **타임스탬프 버전**을 쓰기도 합니다.

```
V20260914_1030__add_email.sql
V20260914_1042__add_phone.sql
```

| 상황 | 추천 |
|------|------|
| 팀 2~3명, 마이그레이션이 가끔 | **V1, V2, V3** — 단순하고 읽기 쉬움 |
| 팀 5명 이상, 브랜치를 동시에 많이 팜 | **타임스탬프** — 번호 충돌이 거의 없음 |

- 타임스탬프는 늦게 머지된 **오래된 파일**이 이미 적용된 버전보다 낮으면 오류가 납니다 (`spring.flyway.out-of-order: true`로 허용 가능하지만 팀에서 결정할 것).
- 어느 방식이든 **프로젝트 시작할 때 정하고 끝까지 유지하세요.**

> **step3과 step5의 원인은 같습니다. 이미 적용된 마이그레이션을 건드렸기 때문입니다.**
> 내용을 수정하든, 이름을 바꾸든, 지우든 다 같은 문제입니다. **적용된 건 그대로 두고, 새로 추가한다.**

---

### step7 — 이미 테이블이 있는 DB에 붙이기: 실패

> ❌ 이 브랜치는 **실행하면 실패하는 게 정상**입니다.
> step7, step8은 `step0`에서 갈라져 나온 **별도 시나리오**입니다. step6까지 쓰던 DB는 초기화하고 시작하세요.

**상황 만들기** — "`ddl-auto: update`로 개발하던 프로젝트"를 재현합니다.

먼저 `mydb`를 지웁니다.

```sql
DROP DATABASE IF EXISTS mydb;
```

```bash
git switch step0
```

```bash
./gradlew bootRun
```

`step0`에서 실행하면 `mydb`가 새로 만들어지고 JPA가 `users` 테이블을 만듭니다. 테이블 목록을 확인합니다.

```sql
SHOW TABLES FROM mydb;
```

**`users` 하나만** 있어야 합니다. `flyway_schema_history`도 보인다면 IntelliJ가 이전 브랜치의 Flyway 의존성으로 실행한 것입니다. [Gradle을 다시 로드](#5-다음-단계로)하고 DB 초기화부터 다시 하세요. (이력 테이블이 이미 있으면 step7에서 오류가 나지 않습니다.)

확인했으면 step7로 이동합니다. IntelliJ라면 **Gradle 다시 로드**도 잊지 마세요.

```bash
git switch step7
```

**바뀐 것**

`step0`에 step1과 같은 Flyway 설정만 붙였습니다. (`V1__init.sql` 없이 `V2__add_user_nickname.sql`만 있음)

**해보기**

```
Found non-empty schema(s) `mydb` but no schema history table.
Use baseline() or set baselineOnMigrate to true to initialize the schema history table.
```

Flyway가 "테이블은 있는데 이력 테이블이 없네? 어디까지 적용된 DB인지 모르겠다" 하고 멈춥니다. **오류 메시지가 이미 답을 알려주고 있습니다.**

---

### step8 — Baseline으로 해결하기

**Baseline이란?** "이 DB는 이미 V1까지 적용된 상태로 치자"고 기준점을 잡는 것입니다.

**바뀐 것**

1단계 — 현재 스키마를 **구조만** 덤프해서 V1으로 만듭니다.

```bash
mysqldump -uroot -pssafy --no-data --skip-comments mydb > V1__baseline.sql
```

> - `mysqldump`가 없다고 나오면 MySQL 설치 폴더(`C:\Program Files\MySQL\MySQL Server 8.0\bin`)에서 실행하세요. Workbench의 **Server → Data Export**에서 "Dump Structure Only"로 내보내도 됩니다.
> - Docker로 띄웠다면 `docker exec flyway-demo mysqldump -uroot -pssafy --no-data --skip-comments mydb > V1__baseline.sql`
> - Windows PowerShell의 `>`는 파일을 UTF-16으로 저장해서 Flyway가 못 읽을 수 있습니다. **Git Bash나 CMD에서** 실행하세요.

덤프에는 `DROP TABLE IF EXISTS`, `/*!40101 SET ... */` 같은 줄도 들어 있습니다. 이런 줄은 지우고 **`CREATE TABLE`만 남겨서** `V1__baseline.sql`로 넣었습니다. (이미 Flyway를 쓰던 DB라면 `flyway_schema_history`도 빼야 합니다.)

2단계 — 기존 DB에는 baseline 설정

```yaml
spring:
  flyway:
    baseline-on-migrate: true
    baseline-version: 1
```

3단계 — 앞으로의 변경은 V2부터 (`V2__add_user_nickname.sql`)

**해보기**

1. step7에서 쓰던 DB 그대로 실행합니다.
   ```
   Creating Schema History table `mydb`.`flyway_schema_history` with baseline ...
   Successfully baselined schema with version: 1
   Migrating schema `mydb` to version "2 - add user nickname"
   ```
   이력 테이블을 보면 V1은 `<< Flyway Baseline >>`으로 **기록만** 되고, V2는 실제로 실행됐습니다.
2. 이제 **빈 DB**에서도 돌려봅니다. `mydb`를 지우고,
   ```sql
   DROP DATABASE IF EXISTS mydb;
   ```
   다시 실행하면 이번엔 `V1__baseline.sql`이 **실제로 실행**되어 같은 구조가 재현됩니다.

| 상황 | V1 파일이 | 결과 |
|------|----------|------|
| 기존 DB (테이블 있음) | 실행 안 됨, 기록만 | 기존 구조 그대로 유지 |
| 새 DB (비어 있음) | 실행됨 | 기존과 똑같은 구조로 재현 |

**같은 파일 하나로 두 경우가 모두 해결됩니다.**

> **주의** — `V1__baseline.sql`이 실제 DB 상태와 정말 같은지 꼭 확인하세요. 여기서 어긋나면 새 환경을 만들 때 구조가 달라집니다.

---

### step9 — 개발 환경에서만 테스트 데이터 넣기

> step9는 **step6 다음 단계**입니다. step6까지 진행한 DB에서 그대로 이어가도 되고, 빈 DB에서 바로 시작해도 됩니다.
> step7·step8을 실행한 DB라면 `DROP DATABASE IF EXISTS mydb;`로 초기화하고 시작하세요.

**상황**

개발할 때는 매번 회원가입부터 하기 귀찮으니 테스트 계정이 미리 들어 있으면 좋겠죠. 그런데 이 INSERT가 **운영 DB에 들어가면 사고**입니다.

- 테이블 구조처럼 **모든 환경에 똑같이 있어야 하는 것** → `db/migration`
- 테스트 데이터처럼 **개발 환경에만 있어야 하는 것** → `db/seed` (별도 폴더)

로 나누고, **프로필에 따라 Flyway가 읽는 폴더(`locations`)를 다르게** 합니다.

**바뀐 것**

```
src/main/resources/
├── application.yml          ← 공통(운영 기준): db/migration 만 읽음
├── application-dev.yml      ← dev 프로필: db/migration + db/seed 읽음
└── db/
    ├── migration/           ← V1 ~ V5 (모든 환경)
    └── seed/
        └── R__insert_test_users.sql   ← 개발 환경 전용 테스트 데이터
```

`application.yml` (기본값 = 운영 기준)

```yaml
spring:
  flyway:
    locations: classpath:db/migration
```

`application-dev.yml`

```yaml
spring:
  flyway:
    locations: classpath:db/migration, classpath:db/seed
```

`db/seed/R__insert_test_users.sql`

```sql
INSERT INTO users (id, email, name, nickname, phone) VALUES
    (1, 'kim@ssafy.com',  '김싸피', 'kimssafy',  '010-1111-1111'),
    (2, 'lee@ssafy.com',  '이싸피', 'leessafy',  '010-2222-2222'),
    (3, 'park@ssafy.com', '박싸피', 'parkssafy', '010-3333-3333') AS new
ON DUPLICATE KEY UPDATE
    email = new.email, name = new.name, nickname = new.nickname, phone = new.phone;
```

**왜 V가 아니라 R(Repeatable)인가요?**

- 테스트 데이터를 `V6__insert_test_users.sql`로 만들면, **개발 DB에는 V6이 있고 운영 DB에는 없는** 상태가 됩니다. 나중에 진짜 V6 마이그레이션을 만들 때 버전이 꼬입니다.
- **R은 버전 번호가 없어서** 공통 마이그레이션의 번호에 끼어들지 않습니다. 아직 안 돌린 V가 모두 끝난 **뒤에** 실행되니, 테이블이 다 만들어진 다음에 데이터가 들어갑니다.
- R은 **파일 내용이 바뀔 때마다 다시 실행**됩니다. 테스트 계정을 추가·수정하면 다음 실행 때 자동으로 반영돼요. 대신 여러 번 실행돼도 문제없도록 `ON DUPLICATE KEY UPDATE`처럼 **중복에 안전하게** 써야 합니다.

**해보기**

1. **운영처럼(기본 프로필)** 실행합니다.
   ```bash
   ./gradlew bootRun
   ```
   테스트 데이터는 들어가지 않습니다. (step6에서 이어왔다면 `up to date`, 빈 DB라면 V1~V5만 적용)
   ```sql
   SELECT COUNT(*) FROM mydb.users;
   ```
   → `0`

2. **개발 환경(dev 프로필)** 으로 실행합니다.
   ```bash
   ./gradlew bootRun --args='--spring.profiles.active=dev'
   ```
   > Windows PowerShell: `.\gradlew bootRun --args="--spring.profiles.active=dev"`
   > IntelliJ: Run Configuration의 **Active profiles**에 `dev` 입력

   ```
   Migrating schema `mydb` with repeatable migration "insert test users"
   ```
   이번엔 `users`에 3명이 들어가고, 이력 테이블에 version이 비어 있는(`NULL`) R 마이그레이션이 한 줄 생깁니다.
   ```sql
   SELECT installed_rank, version, description, type FROM mydb.flyway_schema_history;
   ```

3. (선택) `R__insert_test_users.sql`에 한 명을 추가하고 dev로 다시 실행해 보세요. 내용(체크섬)이 바뀌었으니 R이 **다시 실행**됩니다. V 파일이었다면 체크섬 오류가 났을 상황이죠.

> **주의 — 한 DB를 dev와 운영 프로필로 번갈아 쓰지 마세요**
> dev로 R을 적용한 DB를 기본 프로필로 다시 실행하면, 운영 설정에는 `db/seed` 폴더가 없어서 `Detected applied migration not resolved locally: insert test users` 오류가 납니다.
> 원래 개발 DB와 운영 DB는 **서로 다른 DB**이니 실제로는 생기지 않는 상황입니다. 실습 중에 생기면 DB를 초기화하세요.

> **다른 방법도 있습니다**
> - `spring.flyway.placeholders`로 SQL 안에서 환경별 값을 바꾸거나, `afterMigrate.sql` 콜백으로 매 실행마다 데이터를 넣는 방법도 있습니다.
> - 마이그레이션이 아니라 Spring의 `data.sql` + 프로필로 넣는 팀도 있습니다. 어느 쪽이든 **"운영에 들어가면 안 되는 SQL은 운영 설정에서 아예 안 읽히게"** 하는 게 핵심입니다.

---

## 참고 문서

- [Flyway 시작하기](https://documentation.red-gate.com/flyway/getting-started-with-flyway)
- [Versioned Migrations](https://documentation.red-gate.com/fd/versioned-migrations-273973333.html)
- [Spring Boot + Flyway 설정 레퍼런스](https://docs.spring.io/spring-boot/how-to/data-initialization.html)
