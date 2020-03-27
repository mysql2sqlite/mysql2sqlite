#!/bin/sh

# define newline char as a constant
readonly NL='
'

# This function checks if given command is available on the system.
# It will terminate the script if command is not found.
assert_cmd_available() {
  type "$1" >/dev/null 2>&1 || {
    printf 'ERR command "%s" not available\n' "$1" >&2
    exit 1
  }
}

# This function simply run the given query on given database
# It will print the result
# params: 
#     1. the SQL query (as string)
#     2. the .sqlite file to use as database for the query
#     3. strict mode (as boolean). When in stric mode, a trailing '_' will be added to result to avoid
#        trailing newlines to be truncated. It will be the caller's responsibility to remove this trailing underscore
#
query() {
  [ $# -eq 3 ] || printf 'USAGE: query <query> <dbfilename> <strict>\n'
  query="$1"
  db="$2"
  strict="$3"
  result="$(
    printf '%s' "$query" | sqlite3 "$db" 2>&1;
    if [ "$strict" = true ]; then 
      printf '_'
    fi
  )"
  printf "%s" "$result"
}

# This function will execute given query on given database, and compare the result of this query with given string
# It will print an error and terminate the script if the result does not match given string
# params: 
#     1. the SQL query (as string)
#     2. the expected result of the query (as string)
#     3. the .sqlite file to use as database for the query
#
assert_query() {
  [ $# -eq 3 ] || printf 'USAGE: assert_query <query> <expected> <dbfilename>\n'
  query="$1"
  expected="$2"
  db="$3"
  result="$(query "$query" "$db" true)"   # we need to use stric mode to avoid losing newlines at the end of text fields
  # remove trailing underscore and the last newline
  result=${result%_}
  result=${result%"$NL"}
  # compare expected value with retrieved value
  if [ "$result" != "$expected" ]; then
    printf '\nFAILURE:\n\tQuery failed on %s\n\t    query\t"%s"\n\t    expected\t"%s"\n\t    but got\t"%s"\n' "$db" "$query" "$expected" "$result" >&2
    exit 1
  fi
}

# mandatory binaries, needed to run tests
readonly M2S="./mysql2sqlite"
readonly S="sqlite3"
readonly X="xxd"
readonly H="md5sum"
readonly B64="base64"

assert_cmd_available "$M2S"
assert_cmd_available "$S"
assert_cmd_available "$X"
assert_cmd_available "$H"
assert_cmd_available "$B64"


# Convert SQL dump into sqlite script, and execute this script with sqlite3 to create a valid database file.
# NB: dump was produced using `sudo mysqldump --skip-extended-insert --hex-blob --compact --single-transaction testtypes > unit_tests/dump.sql`
#     To add tests in this dump, just import it into your MySQL instance and re-run the command above.
readonly UT="./unit_tests"
readonly OUT_SCRIPT="$UT/test_dump.sqlite"
readonly OUT_DATABASE="$UT/test_db.sqlite"

rm -- "$OUT_SCRIPT" 2> /dev/null
rm -- "$OUT_DATABASE" 2> /dev/null
"$M2S" "$UT/dump.sql" > "$OUT_SCRIPT"

# create sqlite database using generated sqlite script
"$S" "$OUT_DATABASE" < "$OUT_SCRIPT"

# Test data types conversion
# No tests for Spatial and JSON data types, as they require an extension of Sqlite

# numeric
assert_query "SELECT tinyint, smallint, mediumint, int, bigint FROM testnumeric;" \
             "127|32767|8388607|2147483647|9223372036854775807" \
             "$OUT_DATABASE"
assert_query "SELECT decimal, float, double FROM testnumeric;" \
             "988888888888888832|-1.17549e-38|-2.2250738585072e-308" \
             "$OUT_DATABASE"
assert_query "SELECT HEX(bit) FROM testnumeric;" \
             "FFFFFFFF" \
             "$OUT_DATABASE"

# datetime
assert_query "SELECT * FROM testdatetime;" \
             "2020-03-24|838:59:59|9999-12-31 23:59:59|2038-01-19 02:14:07|2155" \
             "$OUT_DATABASE"

# strings
assert_query "SELECT char, varchar, \`set\`, enum FROM teststring;" \
             "Z|a varchar for test that can be 0x2D char long|c|MAYBE" \
             "$OUT_DATABASE"
assert_query "SELECT text FROM teststring;" \
             "text field content Lorem ipsum parabellum rectum et toutletoutim$NL We can also add some quotes ' double quotes '' doublequote \" and double doublequote \"\"$NL Why not some escape \\' \\'' \\\" \\\"\"$NL And some hexa 0xBAD$NL$NL Now its done$NL" \
             "$OUT_DATABASE"
assert_query "SELECT HEX(binary), HEX(varbinary) FROM teststring;" \
             "2B|61207661726368617220666F72207465737420746861742063616E20626520307832442063686172206C6F6E67" \
             "$OUT_DATABASE"
assert_query "SELECT HEX(blob) FROM teststring;" \
             "74657874206669656C6420636F6E74656E74204C6F72656D20697073756D207061726162656C6C756D2072656374756D20616E6420746F75746C65746F7574696D" \
             "$OUT_DATABASE"

# Test mutiple inserts
assert_query "SELECT id, name, weight FROM testmultirows WHERE id=1;" \
             "1|Greg|125" \
             "$OUT_DATABASE"
assert_query "SELECT id, name, weight FROM testmultirows WHERE id=2;" \
             "2|Mireille|52" \
             "$OUT_DATABASE"

# Test that blobs and text in base64 format are not corrupted
# A picture was inserted into database as a binary blob, and the same picture was inserted as base64 text :
# data is retrieved from database, then dumped in 2 files (to ease debug in case of failure), and then
# files hash are compared to ensure that they are identical
i=1
while [ "$i" -le 2 ]; do
  out_picblob="$UT/test_picture_blob.png"
  picblob="$(query 'SELECT HEX(picture) FROM testmultirows WHERE id='$i';' $OUT_DATABASE false)"  # no need for strict mode because hex cannot contain \n
  printf "%s" "$picblob" | "$X" -r -p > "$out_picblob"
  md5blob="$($H $out_picblob | awk '{ print $1 }')"

  out_picb64="$UT/test_picture_base64.png"
  picb64="$(query 'SELECT base64picture FROM testmultirows WHERE id='$i';' $OUT_DATABASE false)"  # no need for strict mode because base64 cannot contain \n
  printf "%s" "$picb64" | "$B64" -d > "$out_picb64"
  md5b64="$($H $out_picb64 | awk '{ print $1 }')"

  # compare blob's md5 with md5 of empty file, then with md5 of base64 file
  if [ "$md5blob" = "d41d8cd98f00b204e9800998ecf8427e" ]; then
    printf '\nFAILURE:\n\tPicture %d was erased (BLOB is empty)\n' "$i" >&2
    exit 1
  fi
  if [ "$md5blob" != "$md5b64" ]; then
    printf '\nFAILURE:\n\tPicture %d got corrupted, either as BLOB or as base64 TEXT\n\t    picture from blob   dumped at  %s\n\t    picture from base64 dumped at  %s\n' "$i" "$OUT_picblob" "$OUT_picb64" >&2
    exit 1
  fi
  i=$(( i + 1 ))
done


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
