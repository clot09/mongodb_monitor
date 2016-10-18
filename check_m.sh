
#!/bin/bash


mysqlbin=/usr/bin/mysql
mysqlpath=/usr/bin
mysql_all="mysql -u dba_monitor -p xxxx"
mysql_read="mysql -u dba_monitor -p xxx"
dbuser=dba_monitor
dbpass=xxx
dwhost=192.168.1.22
dwname=test
dwport=3407

scpuser=root
mysqldumpbin=/usr/bin/mysqldump
maildrss=clot09@gmail.com
export mongo_admin="mongo --authenticationDatabase=admin"

export user=admin
export password=admin





function check_master_status() {
	export ip=$1
	export port=$2
	export role=$3
	if [[ $3 -eq 1 ]];then
		echo "check master status"
		for line in `${mongo_admin} -u ${user} -p ${password} --host ${ip} --port ${port} --eval 'printjson(rs.status())'| grep health|awk -F ':' '{print $NF}'|sed 's/,//g' `
		do
			{
			#	sum_h=0
				if [[ ${line}  != "1"  ]]; then
					echo  "health is not equal to 1 ,the member may have some problem;"
					export is_h=1
				#	exit 0;
				else
					echo "member status is health"
					export is_h=0
				fi
			}
			let sum_h+=is_h
		done
		#echo ${sum_h}
		if [[ ${sum_h}  -eq 0 ]]; then
			export stat=`${mongo_admin} -u ${user} -p ${password} --host ${ip} --port ${port} --eval 'printjson(db.runCommand({ isMaster: 1 }))'|grep ismaster `
			export is_role=`${mongo_admin} -u ${user} -p ${password} --host ${ip} --port ${port} --eval 'printjson(db.runCommand({ isMaster: 1 }))'|grep ismaster |awk -F ':' '{print $2F}'|sed   's/"//g'|sed 's/[[:space:]]//g'|sed 's/,//g'`
			if [[ ${is_role} = "true" ]]; then
				echo "master ${ip} : ${port} running normal"
				export m_s=1
			elif [[ ${is_role} = "false" ]]; then
				echo "master ${ip} : ${port} may chaged to secondary ,check the replicaset status"
				export m_s=2
				exit 1;
			else
				echo "please check the master and secondary mongod failover info "
				export m_s=0
				exit 1;
			fi
		fi
		for line in `${mongo_admin} -u ${user} -p ${password} --host ${ip} --port ${port} --eval 'printjson(db.runCommand({ isMaster: 1 }))'| grep uptime|awk -F ':' '{print $NF}'|sed 's/,//g' `
		do
			{
				if [[ ${line} -lt 10  ]]; then
					echo  "the member may have been restart yet;"
				fi
			}
		done
	fi
}





function check_secondary_status() {
	export ip=$1
	export port=$2
	export role=$3
	if [[ $3 -eq 2 ]]; then
		echo "check secondary status"
		if [[ ${m_s}  -eq 1 ]]; then

			export stat=`${mongo_admin} -u ${user} -p ${password} --host ${ip} --port ${port} --eval 'printjson(db.runCommand({ isMaster: 1 }))'|grep secondary `
			export is_role=`${mongo_admin} -u ${user} -p ${password} --host ${ip} --port ${port} --eval 'printjson(db.runCommand({ isMaster: 1 }))'|grep secondary |awk -F ':' '{print $2F}'|sed   's/"//g'|sed 's/[[:space:]]//g'|sed 's/,//g'`
			if [[ ${is_role} = "true" ]]; then
				echo "secondary ${ip} : ${port} running normal"
				export lag_time=`${mongo_admin} -u ${user} -p ${password} --host ${ip} --port ${port} --eval 'printjson(rs.printSlaveReplicationInfo())' |grep sec|awk '{print $1}'`
				if [ ${lag_time} -gt 10 ];then
					echo "the mongodb replication time is  ${lag_time} ,please check the secondary mongodb instance "
				fi
			#elif [[ ${is_role} = "false" ]]; then
			#	echo "secondary ${ip} : ${port} may chaged to master ,check the replicaset status"
		else
			echo "please check the secondary mongod status"
		fi
	else
		echo  "please check the replicaset running stauts "

	fi
fi

}


function check_arbiter_status() {
	echo "check arbiter status"
	export ip=$1
	export port=$2
	export role=$3
	if [[ $3 -eq 2 ]];then
		if [[ ${m_s} -eq 1 ]]; then
			export arb_line=`${mongo_admin} -u ${user} -p ${password} --host ${ip} --port ${port} --eval 'printjson(rs.conf())'|grep -n "\"arbiterOnly\" : true"|awk -F':' '{print $1}'`
			export id_line=`expr $arb_line - 2`
			export id_nu=`${mongo_admin} -u ${user} -p ${password} --host ${ip} --port ${port} --eval 'printjson(rs.conf())'|sed -n "${id_line}p"|sed 's/,//g'|sed 's/^[ \t]*//g'`
		   #echo ${id_nu}
		   export rs_line=`${mongo_admin} -u ${user} -p ${password} --host ${ip} --port ${port} --eval 'printjson(rs.status())'|grep -n "${id_nu}"|awk -F ':' '{print $1}'`
		   export stat_nu=`expr ${rs_line} + 2`
		   #echo ${stat_nu}
		   export health=`${mongo_admin} -u ${user} -p ${password} --host ${ip} --port ${port} --eval 'printjson(rs.status())'|sed -n "${stat_nu}p"|awk -F ':' '{print $NF}'|sed 's/,//g'|sed 's/[[:space:]]//g' `
		   if [ ${health} -eq 1 ]; then
		   	echo "arbiter ${ip} : arbiter running normal"
		   elif [[ "x${heath}" == 'x' ]]; then
		   	echo "  the mongod may not have arbiter"
		   else
		   	echo "the arbiter is down ,check it"
		   fi
		else
		echo 	"please check the replicaset status "
		fi

	fi
}






##check m_status
for dblist in `/usr/bin/mysql $dwname -u${dbuser}   -p${dbpass}  -P${dwport} -h${dwhost} -N -e "select distinct ip,dbport,1  from v_mongo_server;"  | tr "\t" ":"`
do
	{
		m_ip=` echo ${dblist} | cut -d: -f1`
		m_port=` echo ${dblist} | cut -d: -f2`
		role=` echo ${dblist} | cut -d: -f3`
		check_master_status ${m_ip} ${m_port} ${role}
	}
done

#check s_status
for dblist in `/usr/bin/mysql $dwname -u${dbuser}   -p${dbpass}  -P${dwport} -h${dwhost} -N -e "select distinct slave_ip,slave_port,role from v_mongo_server where role=2;"  | tr "\t" ":"`
do
	{
		m_ip=` echo ${dblist} | cut -d: -f1`
		m_port=` echo ${dblist} | cut -d: -f2`
		role=` echo ${dblist} | cut -d: -f3`
		check_secondary_status ${m_ip} ${m_port} ${role}
	}
done

##check a_status
for dblist in `/usr/bin/mysql $dwname -u${dbuser}   -p${dbpass}  -P${dwport} -h${dwhost} -N -e "select distinct slave_ip,slave_port,role from v_mongo_server where role=2;"  | tr "\t" ":"`
do
	{
		m_ip=` echo ${dblist} | cut -d: -f1`
		m_port=` echo ${dblist} | cut -d: -f2`
		role=` echo ${dblist} | cut -d: -f3`
		check_arbiter_status ${m_ip} ${m_port} ${role}
	}
done


