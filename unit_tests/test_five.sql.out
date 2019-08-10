PRAGMA synchronous = OFF;
PRAGMA journal_mode = MEMORY;
BEGIN TRANSACTION;
CREATE TABLE `AAAA` (
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT
,  `llll` varchar(10) NOT NULL
,  `rrrr` timestamp NULL DEFAULT current_timestamp
,  `ssss` timestamp NULL DEFAULT NULL 
,  `tttt` varchar(1) DEFAULT 'A'
,  UNIQUE (`id`)
,  CONSTRAINT `bbbb_fk` FOREIGN KEY (`bbbb`) REFERENCES `category` (`id`)
);
CREATE INDEX "idx_AAAA_bbbb_fk" ON "AAAA" (`bbbb`);
END TRANSACTION;
