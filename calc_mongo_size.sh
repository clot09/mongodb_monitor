#!/bin/bash



export sql_dir="/data/test/scripts/mongodb_size/"

mysqlbin=/usr/bin/mysql
mysqlpath=/usr/bin
mysql_all="mysql -u xxx -pxxx"
mysql_read="mysql -u xxx -pxxx"
dbuser=dba_monitor
dbpass=xxx
dwhost=172.17.10.68
dwname=xxx
dwport=3401
osport=23245
mysqldumpbin=/usr/bin/mysqldump
mongo_user="dba_monitor"
mongo_pwd="xxx"
mongo_bin="mongo --authenticationDatabase=admin"

export calc_date=`date +%Y%m%d`



echo  ${sql_bin}
cd ${sql_dir}


function calc_mongo_size (){
  export ip=$1
  export dbport=$2
  export dbname=$3
  export db_info=`${mongo_bin} ${dbname} -u ${mongo_user} -p ${mongo_pwd}  --host ${ip}   --eval 'printjson(db.runCommand({dbStats:1,scale:1024*1024*1024}))'`
  export data_size=`echo ${db_info} |awk -F ',' '{print $5F}'|awk -F ':' '{print $2F}'|sed 's/[[:space:]]//g'`
  export store_size=`echo ${db_info} |awk -F ',' '{print $6F}'|awk -F ':' '{print $2F}'|sed 's/[[:space:]]//g' `
  export ind_size=`echo ${db_info}|awk -F ',' '{print $9F}'|awk -F ':' '{print $2F}'|sed 's/[[:space:]]//g' `
  export db_size_compress=`echo "scale=4;(${store_size} + ${ind_size})"|bc|sed 's/[[:space:]]//g' `
  export sql_val="insert into mongodb_size values ( '${ip}','${dbport}','${dbname}',${db_size_compress},${data_size},'${calc_date}',current_timestamp) ; "
  cd ${sql_dir}
  echo ${sql_val}>>mongo_size.sql
}


for dblist in `/usr/bin/mysql $dwname -u${dbuser}   -p${dbpass}  -P${dwport} -h${dwhost} -N -e "select distinct ip,dbport,dbname  from serverlist where status=3;"  | tr "\t" ":"`
do
	{
		mo_ip=` echo ${dblist} | cut -d: -f1`
		mo_port=` echo ${dblist} | cut -d: -f2`
		mo_name=` echo ${dblist} | cut -d: -f3`
		calc_mongo_size ${mo_ip} ${mo_port} ${mo_name}
	}
done

