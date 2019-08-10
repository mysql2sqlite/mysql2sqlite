#!/bin/sh

M2S=../mysql2sqlite
S=sqlite3

type "$S" >/dev/null 2>&1 || {
  printf 'ERR command "%s" not available\n' "$S" >&2
  exit 1
}

[ -r "$M2S" ] || {
  printf 'ERR file "%s" not found\n' "$M2S" >&2
  exit 1
}


for f in *.sql
do
 $M2S $f > $f.out
done
