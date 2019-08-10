PRAGMA synchronous = OFF;
PRAGMA journal_mode = MEMORY;
BEGIN TRANSACTION;
CREATE TABLE "map" (
  "ID" integer NOT NULL
,  "f" integer NOT NULL
,  "direct" integer NOT NULL DEFAULT 199
,  "t" integer NOT NULL
);
insert into "map" ("ID", "f", "t") values (5, 6, 7);
insert into "map" ("ID", "f", "direct", "t") values (55, 66, 99, 77);
END TRANSACTION;
