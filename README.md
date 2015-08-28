# mysql2sqlite

Converts MySQL dump to SQLite3 compatible dump (including MySQL `KEY xxxxx` statements from the `CREATE` block).

After dumping the MySQL DB somehow (e.g.
~~~~
mysqldump --skip-extended-insert --compact [options]... DB_name
~~~~
or
~~~~
mysqldump --no-data -u root -pmyPassword myDB
~~~~
), run just
~~~~
mysql2sqlite.sh dump_mysql.sql | sqlite3 mysqlite3.db
~~~~

## Development

The script is POSIX-compliant and depends only on *sh* and *awk* (tested with gawk, original awk, and the lightning fast mawk).

It's based on the newest fork (https://gist.github.com/bign8/9055981/05e65fd90c469c5eaa730823910c0c5f9de40ab4) of the original `mysql2sqlite.sh` (https://gist.github.com/esperlu/943776/be469f0a0ab8962350f3c5ebe8459218b915f817) with the following patches:

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
* **Currently** we're waiting for response about licensing - if @esperlu agrees to MIT or not in the discussion thread under the [original gist](https://gist.github.com/esperlu/943776), because there is no other way how to contact him.
