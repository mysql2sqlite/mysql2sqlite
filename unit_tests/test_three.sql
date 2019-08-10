-- # big bit field num
-- # big bit field num with overflow
-- # big bit field num with potential overflow, but zeros


CREATE TABLE "map" (
  "ID" int(10) NOT NULL,
  "f" int(11) NOT NULL,
  "direct" bit(1) NOT NULL DEFAULT 1,
  "t" int(11) NOT NULL
);
insert into "map" ("ID", "f", "t") values (5, 6, 7);
insert into "map" ("ID", "f", "direct", "t") values (55, 66, 99, 77);

