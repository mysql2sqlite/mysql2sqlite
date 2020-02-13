#!/bin/sh

M2S=./mysql2sqlite
S=sqlite3

type "$S" >/dev/null 2>&1 || {
  printf 'ERR command "%s" not available\n' "$S" >&2
  exit 1
}

[ -r "$M2S" ] || {
  printf 'ERR file "%s" not found\n' "$M2S" >&2
  exit 1
}

# FIXME
printf 'ERR Unit testing not yet fully implemented\n' >&2
exit 1

# Hex numbers with 15, 16, and 17 characters

cat <<\SQL
INSERT INTO `cache` (`cid`, `data`, `expire`, `created`, `headers`, `serialized`) VALUES
('ctools_plugin_files:ctools:style_bases', 0x613a313a7b733a3, 0, 1440573529, '', 1),
('ctools_plugin_files:ctools:content_types', 0xa343a226e6f64652, 0, 1440573529, '', 1);
INSERT INTO `cache` (`cid`, `data`, `expire`, `created`, `headers`, `serialized`) VALUES
('theme_registry:my_theme', 0x613a3234353a7b733, 0, 1440572933, '', 1);
SQL

# WARN Potential case sensitivity issues... for each line

# Bit Fields

cat <<\SQL
CREATE TABLE "bit_type" (
  "a" int(10) unsigned NOT NULL AUTO_INCREMENT,
  "b" bit(1) NOT NULL DEFAULT b'1',
  "c" bit(8) NOT NULL DEFAULT B'11111111',
  "d" BIT(4) NOT NULL DEFAULT b'1010',
  "e" BIT(4) NOT NULL DEFAULT B'00111111110000111',
  "f" int(10) unsigned NOT NULL AUTO_INCREMENT,
);
SQL

# big bit field num
# big bit field num with overflow
# big bit field num with potential overflow, but zeros

cat <<\SQL
CREATE TABLE "map" (
  "ID" int(10) NOT NULL,
  "f" int(11) NOT NULL,
  "direct" bit(1) NOT NULL DEFAULT 1,
  "t" int(11) NOT NULL
);
insert into "map" ("ID", "f", "t") values (5, 6, 7);
insert into "map" ("ID", "f", "direct", "t") values (55, 66, 99, 77);
SQL

cat <<\SQL
CREATE TABLE "map" (
  "ID" int(10) NOT NULL,
  "f" int(11) NOT NULL,
  "direct" bit(1) NOT NULL DEFAULT 199,
  "t" int(11) NOT NULL
);
insert into "map" ("ID", "f", "t") values (5, 6, 7);
insert into "map" ("ID", "f", "direct", "t") values (55, 66, 99, 77);
SQL

cat <<\SQL
DROP TABLE IF EXISTS `AAAA`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `AAAA` (
  `id` bigint(10) NOT NULL AUTO_INCREMENT COMMENT 'PK.',
  `llll` varchar(10) NOT NULL COMMENT 'Some Comment',
  `rrrr` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created date',
  `ssss` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT 'Modified Date. Some Comment',
  `tttt` varchar(1) DEFAULT 'A' COMMENT 'Some Comment',
  PRIMARY KEY (`id`),
  UNIQUE KEY `aaaa_pk` (`id`) COMMENT 'PK Index',
  KEY `bbbb_fk` (`bbbb`) COMMENT 'Index for FK, Reference Category',
  CONSTRAINT `bbbb_fk` FOREIGN KEY (`bbbb`) REFERENCES `category` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `AAAA`
--

LOCK TABLES `AAAA` WRITE;
/*!40000 ALTER TABLE `AAAA` DISABLE KEYS */;
/*!40000 ALTER TABLE `AAAA` ENABLE KEYS */;
UNLOCK TABLES;
SQL

cat <<\SQL
/*!50100 PARTITION BY RANGE (YEAR(date))
(PARTITION p6 VALUES LESS THAN (2012) ENGINE = InnoDB,
 PARTITION p7 VALUES LESS THAN (2013) ENGINE = InnoDB)
SQL

cat <<\SQLin
CREATE TABLE `CCC`(
  `created` datetime DEFAULT current_timestamp(),
  `updated` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
);
SQLin

cat <<\SQLout
PRAGMA synchronous = OFF;
PRAGMA journal_mode = MEMORY;
BEGIN TRANSACTION;
CREATE TABLE `CCC`(
  `created` datetime DEFAULT current_timestamp
,  `updated` datetime DEFAULT current_timestamp 
);
END TRANSACTION;
SQLout


cat <<\SQL
CREATE TABLE `scimag` (
  `ID` int(15) unsigned NOT NULL AUTO_INCREMENT,
  `DOI` varchar(200) NOT NULL,
  PRIMARY KEY (`ID`) USING BTREE,
  UNIQUE KEY `DOIUNIQUE` (`DOI`) USING BTREE,
);
SQL

cat <<\SQLin
CREATE TABLE `scimag` (
  `TEXTFIELD` text DEFAULT (_utf8mb3'text_value'),
);
SQLin

cat <<\SQLout
PRAGMA synchronous = OFF;
PRAGMA journal_mode = MEMORY;
BEGIN TRANSACTION;
CREATE TABLE `scimag` (
  `TEXTFIELD` text DEFAULT ('text_value')
);
END TRANSACTION;
SQLout
