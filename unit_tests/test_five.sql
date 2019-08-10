

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
