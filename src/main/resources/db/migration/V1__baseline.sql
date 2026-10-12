-- mysqldump -uroot -pssafy --no-data --skip-comments mydb 결과를 정리한 파일
-- 기존 DB: baseline-on-migrate로 "적용된 것으로 기록"만 되고 실행되지 않음
-- 새 DB  : 실제로 실행되어 기존과 같은 구조를 재현함
CREATE TABLE `users` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `name` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
