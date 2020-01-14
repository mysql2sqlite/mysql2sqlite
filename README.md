# mysql2sqlite

Converts MySQL dump to SQLite3 compatible dump (including MySQL `KEY xxxxx` statements from the `CREATE` block).

## Usage

1. Dump MySQL DB

    ~~~~
    mysqldump --skip-extended-insert --compact [options]... DB_name > dump_mysql.sql
    # or
    #mysqldump --no-data -u root -pmyPassword [options]... DB_name > dump_mysql.sql
    ~~~~

1. Convert the dump to SQLite3 DB

    ~~~~
    ./mysql2sqlite dump_mysql.sql | sqlite3 mysqlite3.db
    ~~~~

(both `mysql2sqlite` and `sqlite3` might write something to stdout and stderr - e.g. `memory` coming from `PRAGMA journal_mode = MEMORY;` is not harmful)

## Development

The script is written in *awk* (tested with gawk, but should work with original awk, and the lightning fast mawk) and shall be fully POSIX compliant.

It's originally based on the newest fork (https://gist.github.com/bign8/9055981/05e65fd90c469c5eaa730823910c0c5f9de40ab4) of the original `mysql2sqlite.sh` (https://gist.github.com/esperlu/943776/be469f0a0ab8962350f3c5ebe8459218b915f817) with the following patches:

* fix the non-standard `COMMENT` field statement removal
* ignore `CREATE DATABASE` statements (`USE` statements were already ignored)
* add support for multiple-record `INSERT INTO VALUES`
* revise support for lower-case SQL statements
* fix `AUTO_INCREMENT` handling
* trim hexadecimal values longer than 16 characters and issue a warning about it
* add identifier case sensitivity warning in case `IF NOT EXISTS` or `TEMPORARY` has been detected (on unix sqlite3 treats temporary table name `FILES` the same as `files`; in other words, sqlite3 doesn't issue any warning about cross-collisions between `TABLE` and `TEMPORARY TABLE` identifiers)
* replace `COLLATE xxx_xxxx_xx` statements with `COLLATE BINARY` (https://gist.github.com/4levels/0d5da65bf9d70479fbe3/d0ac3d295dc5e2f72411ad06c07a22931368a1b7)
* handle `CONSTRAINT FOREIGN KEY` (https://gist.github.com/BastienDurel/7f413d13d7b858aef31c/922be110d011b9da340ae545372214b597ad7b84)

Feel free to **contribute** (preferably by issuing a pull request)!

## License

MIT

## History

* @esperlu created initial version in 2011 as gist on GitHub
* many different contributors forked the gist and made wildly varying changes, because @esperlu stopped working on it and didn't respond
* @dumblob took over in Aug 2015 and applied the most important patches from all the forks as well as many his own patches tested on Drupal DB
* @dumblob added the MIT license under assumption, that the original gist was released into public domain, because despite significant changes, it wasn't clean room engineering.
* 2016-05-11 17:32 UTC+2 [@esperlu declared](https://github.com/dumblob/mysql2sqlite/issues/2 ) MIT as a fitting license (also retrospectively) and the [original gist](https://gist.github.com/esperlu/943776 ) as deprecated.
