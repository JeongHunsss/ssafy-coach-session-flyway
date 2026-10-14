-- 개발 환경(dev 프로필)에서만 실행되는 테스트 데이터
-- R(Repeatable): 버전 번호 없이, 파일 내용이 바뀔 때마다 다시 실행됩니다.
-- 여러 번 실행돼도 안전하도록 ON DUPLICATE KEY UPDATE로 작성합니다.
INSERT INTO users (id, email, name, nickname, phone) VALUES
    (1, 'kim@ssafy.com',  '김싸피', 'kimssafy',  '010-1111-1111'),
    (2, 'lee@ssafy.com',  '이싸피', 'leessafy',  '010-2222-2222'),
    (3, 'park@ssafy.com', '박싸피', 'parkssafy', '010-3333-3333') AS new
ON DUPLICATE KEY UPDATE
    email = new.email, name = new.name, nickname = new.nickname, phone = new.phone;
