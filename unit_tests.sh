#!/bin/sh

M2S=./mysql2sqlite
S=sqlite3
X=xxd
M=md5sum
B64=base64

type "$S" >/dev/null 2>&1 || {
  printf 'ERR command "%s" not available\n' "$S" >&2
  exit 1
}

type "$X" >/dev/null 2>&1 || {
  printf 'ERR command "%s" not available\n' "$X" >&2
  exit 1
}

type "$M" >/dev/null 2>&1 || {
  printf 'ERR command "%s" not available\n' "$M" >&2
  exit 1
}

type "$B64" >/dev/null 2>&1 || {
  printf 'ERR command "%s" not available\n' "$B64" >&2
  exit 1
}

[ -r "$M2S" ] || {
  printf 'ERR file "%s" not found\n' "$M2S" >&2
  exit 1
}

# This function simply run the given query on given database
# It will print the result
# params: 
#     1. the SQL query (as string)
#     2. the .sqlite file to use as database for the query
#
query() {
  QUERY="$1"
  DB="$2"
  RESULT=$(echo "$QUERY" | sqlite3 "$DB" 2>&1)
  printf "$RESULT"
}

# This function will execute given query on given database, and compare the result of this query with given string
# It will print an error and terminate the script if the result does not match given string
# params: 
#     1. the SQL query (as string)
#     2. the expected result of the query (as string)
#     3. the .sqlite file to use as database for the query
#
assert_query() {
  QUERY="$1"
  EXPECTED="$2"
  DB="$3"
  RESULT=$(query "$QUERY" "$DB")
  if [ "$RESULT" != "$EXPECTED" ]; then
    printf '\nFAILURE:\n\tQuery failed on %s\n\t    query\t"%s"\n\t    expected\t"%s"\n\t    but got\t"%s"\n' "$DB" "$QUERY" "$EXPECTED" "$RESULT" >&2
    exit 1
  fi
}

# Convert SQL dump into sqlite script, and execute this script with sqlite3 to create a valid database file.
# NB: dump was produced using `sudo mysqldump --skip-extended-insert --hex-blob --compact --single-transaction testtypes > unit_tests/dump.sql`
#     To add tests in this dump, just import it into your MySQL instance and re-run the command above.
UT=./unit_tests
OUT_script=$UT/test_dump.sqlite
OUT_database=$UT/test_db.sqlite
rm $OUT_script 2> /dev/null
rm $OUT_database 2> /dev/null
$M2S $UT/dump.sql > $OUT_script
# create sqlite database using generated sqlite script
cat $OUT_script | $S $OUT_database

# Test data types conversion
# No tests for Spatial and JSON data types, as they require an extension of Sqlite

# numeric
assert_query "SELECT tinyint, smallint, mediumint, int, bigint FROM testnumeric;" \
             "127|32767|8388607|2147483647|9223372036854775807" \
             $OUT_database
assert_query "SELECT decimal, float, double FROM testnumeric;" \
             "988888888888888832|-1.17549e-38|-2.2250738585072e-308" \
             $OUT_database
assert_query "SELECT HEX(bit) FROM testnumeric;" \
             "FFFFFFFF" \
             $OUT_database

# datetime
assert_query "SELECT * FROM testdatetime;" \
             "2020-03-24|838:59:59|9999-12-31 23:59:59|2038-01-19 02:14:07|2155" \
             $OUT_database

# strings
assert_query "SELECT char, varchar, \`set\`, enum FROM teststring;" \
             "Z|a varchar for test that can be 0x2D char long|c|MAYBE" \
             $OUT_database
assert_query "SELECT text FROM teststring;" \
             "text field content Lorem ipsum parabellum rectum and toutletoutim
We can also add some quotes ' double quotes '' doublequote \" and double doublequote \"\"
Why not some escape \\' \\'' \\\" \\\"\"
And some hexa 0xBAD

Now its done" \
             $OUT_database
assert_query "SELECT HEX(binary), HEX(varbinary) FROM teststring;" \
             "2B|61207661726368617220666F72207465737420746861742063616E20626520307832442063686172206C6F6E67" \
             $OUT_database
assert_query "SELECT HEX(blob) FROM teststring;" \
             "74657874206669656C6420636F6E74656E74204C6F72656D20697073756D207061726162656C6C756D2072656374756D20616E6420746F75746C65746F7574696D" \
             $OUT_database

# Test mutiple inserts
assert_query "SELECT id, name, weight FROM testmultirows WHERE id=1;" \
             "1|Greg|125" \
             $OUT_database
assert_query "SELECT id, name, weight FROM testmultirows WHERE id=2;" \
             "2|Mireille|52" \
             $OUT_database

# Test that blobs and text in base64 format are not corrupted
# A picture was inserted into database as a binary blob, and the same picture was inserted as base64 text :
# data is retrieved from database, then dumped in 2 files (to ease debug in case of failure), and then
# files hash are compared to ensure that they are identical

OUT_picblob=$UT/test_picture_blob.png
picblob=$(query "SELECT HEX(picture) FROM testmultirows WHERE id=1;" $OUT_database)
echo $picblob | $X -r -p > $OUT_picblob
md5blob=$($M $OUT_picblob | awk '{ print $1 }')

OUT_picb64=$UT/test_picture_base64.png
picb64=$(query "SELECT base64picture FROM testmultirows WHERE id=1;" $OUT_database)
echo $picb64 | $B64 -d > $OUT_picb64
md5b64=$($M $OUT_picb64 | awk '{ print $1 }')

if [ "$md5blob" != "$md5b64" ]; then
  printf '\nFAILURE:\n\tPicture got corrupted, either as BLOB or as base64 TEXT\n\t    picture from blob   dumped at  %s\n\t    picture from base64 dumped at  %s\n' "$OUT_picblob" "$OUT_picb64" >&2
  exit 1
fi


# FIXME
printf '\nERR Unit testing not yet fully implemented\n\n' >&2
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
