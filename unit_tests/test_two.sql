-- Bit Fields


CREATE TABLE "bit_type" (
  "a" int(10) unsigned NOT NULL AUTO_INCREMENT,
  "b" bit(1) NOT NULL DEFAULT b'1',
  "c" bit(8) NOT NULL DEFAULT B'11111111',
  "d" BIT(4) NOT NULL DEFAULT b'1010',
  "e" BIT(4) NOT NULL DEFAULT B'00111111110000111',
  "f" int(10) unsigned NOT NULL AUTO_INCREMENT,
);

