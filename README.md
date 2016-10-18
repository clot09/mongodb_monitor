# check_m.sh
a shell to monitor mongodb replicaset status

##  add db config in mysql database 
- 1 first create a database in mysql that including the mongodb info
```sql
CREATE TABLE `serverlist` (
  `SerID` int(11) NOT NULL COMMENT '服务器ID，唯一标示'
  `dbname` varchar(30) NOT NULL COMMENT 'database name',
  `server_name` varchar(50) NOT NULL COMMENT '服务器名',
  `IP` char(16) NOT NULL,
  `osport` int(11) DEFAULT NULL,
  `dbport` smallint(6) DEFAULT NULL,
  `status` tinyint(4) DEFAULT NULL COMMENT '3:mongodb(-3:下架)',
  `inserttime` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '插入时间',
  `updatetime` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '插入时间',
  PRIMARY KEY (`SerID`),
  UNIQUE KEY `u_server_name` (`server_name`),
  UNIQUE KEY `u_dbname` (`IP`,`dbname`,`dbport`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8


CREATE TABLE `slave` (
  `slave_ip` char(16) NOT NULL DEFAULT '',
  `osport` int(11) DEFAULT NULL,
  `mongodb_ip` char(16) DEFAULT NULL,
  `slave_port` int(10) DEFAULT NULL,
  `master_ip` char(16) DEFAULT NULL,
  `port` int(10) DEFAULT NULL,
  `status` tinyint(4) NOT NULL,
  `role` int(5) DEFAULT NULL COMMENT '1 master 2 secondonary 3 arbiter'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_mongo_server` AS select distinct `a`.`IP` AS `ip`,`a`.`dbport` AS `dbport`,`b`.`slave_ip` AS `slave_ip`,`b`.`slave_port` AS `slave_port`,`b`.`role` AS `role` from (`serverlist` `a` join `slave` `b`) where ((`b`.`mongodb_ip` = `a`.`IP`) and (`a`.`dbport` = `b`.`port`) and (`a`.`status` = 3)) order by `a`.`IP`
```
in slave table,role 1 means master ;2 means secondary ;3 means arbiter 
in serverlist table you just need input the master server info


##   config the database info in the shell scripts 
- 1 
you should config the mysql ip,user,password in the shell scripts 
and config the mongodb monitor username,password in the shell scripts
please give the admin role to the monitor user  


# calc_mongo_size.sh
you should config the database info into the shell scirpts ,include username,passwod,dbport,ipadress

the mysql config info is like abrove

the mongodb output size is in Gb 
