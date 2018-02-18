-- MySQL dump 9.11
--
-- Host: localhost    Database: score
-- ------------------------------------------------------
-- Server version	4.0.24_Debian-10-log

--
-- Table structure for table `agents`
--

CREATE DATABASE example;

USE example;

CREATE TABLE `agents` (
  `ID` int(11) NOT NULL auto_increment,
  `Name` tinytext,
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;

--
-- Dumping data for table `agents`
--

INSERT INTO `agents` VALUES (1,'Andrew Dougherty');

--
-- Table structure for table `dependencies`
--

CREATE TABLE `dependencies` (
  `ID` int(11) NOT NULL auto_increment,
  `Child` int(11) default NULL,
  `Parent` int(11) default NULL,
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;

--
-- Dumping data for table `dependencies`
--


--
-- Table structure for table `events`
--

CREATE TABLE `events` (
  `ID` int(11) NOT NULL auto_increment,
  `AgentID` int(11) default NULL,
  `Date` datetime default NULL,
  `Event` tinytext,
  `Score` tinytext,
  `Count` int(11) default NULL,
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM;
