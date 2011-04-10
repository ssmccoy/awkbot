-- MySQL dump 9.11
--
-- Host: localhost    Database: awkbot
-- ------------------------------------------------------
-- Server version	4.0.23_Debian-1-log

--
-- Table structure for table `karma`
--

CREATE TABLE `karma` (
  `nick` varchar(100) NOT NULL default '',
  `karma` int(11) default NULL,
  PRIMARY KEY  (`nick`)
) TYPE=MyISAM;

--
-- Dumping data for table `karma`
--

INSERT INTO `karma` VALUES ('tag',5);
INSERT INTO `karma` VALUES ('awkbot',0);
INSERT INTO `karma` VALUES ('xmb',1);
INSERT INTO `karma` VALUES ('paul',11);

--
-- Table structure for table `qna`
--

CREATE TABLE `qna` (
  `question` varchar(100) default NULL,
  `answer` varchar(255) default NULL
) TYPE=MyISAM;

--
-- Dumping data for table `qna`
--

INSERT INTO `qna` VALUES ('is','is I use it\r');
INSERT INTO `qna` VALUES ('paul','the man');
INSERT INTO `qna` VALUES ('tag','the author');
INSERT INTO `qna` VALUES ('awk','the tool used to write me');
INSERT INTO `qna` VALUES ('mysql','the RDBM I use, just because tag is too lazy to write a pg.awk too.');
INSERT INTO `qna` VALUES ('mysql_quote','something tag really needs to add to mysql.awk');
INSERT INTO `qna` VALUES ('xmb','the guy with incompatible libraries');
INSERT INTO `qna` VALUES ('mysql.awk','http://www.blisted.org/svn/modules/mysql.awk/ until tag writes documentation');

CREATE TABLE `paste` (
    paste_id int(11),
    nick     varchar(20) not null,
    subject  varchar(80) not null,
    language varchar(15) not null default 'awk',
    content  text
) TYPE=MyISAM;

CREATE TABLE `status` (
    `running` boolean not null default false,
    `connected` boolean not null default false,
    `livefeed` varchar(120) default null,
    `started` timestamp not null default current_timestamp
);

INSERT INTO `status` (running, livefeed) VALUES (FALSE, NULL);

-- Make status a table with only one record, always
-- Mysql is ghetto like that... we can't raise errors, we have to actually just
-- create one with an invalid statement...

DELIMITER / 

CREATE TRIGGER t_status_final BEFORE INSERT ON status
FOR EACH ROW
BEGIN
    DECLARE temp integer;
    SELECT `INSERT is not allowed` INTO temp FROM status;
END;
/

CREATE TRIGGER t_status_final_d BEFORE DELETE ON status
FOR EACH ROW
BEGIN
    DECLARE temp integer;
    SELECT `DELETE is not allowed` INTO temp FROM status;
END;
/

DELIMITER ;
