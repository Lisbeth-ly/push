编译安装：

#!/bin/bash

HOSTNAME=`hostname`
checkZabbix=`ps -ef | grep zabbix | grep -v grep `
mysql_root_password=Tm7WVdKWWmxbgsN9U9HaTQ
mysql_zabbix_password=2abbixProxyDB
Proxy=172.16.230.57
#创建zabbix用户
groupadd zabbix
useradd -g zabbix zabbix

#基础环境
#刘俊刚提供
#yum install -y gcc mysql-community-devel libxml2-devel unixODBC-devel net-snmp-devel libcurl-devel libssh2-devel OpenIPMI-devel openssl-devel openldap-devel
yum install -y fping gcc make cmake php php-gd php-devel php-mysql php-bcmath php-ctytpe php-xml php-xmlreader php-xlmwriter php-session php-net-socket php-mbstring php-gettext httpd net-snmp curl curl-devel net-snmp net-snmp-devel perl-DBI libxml libxml2-devel libaio unixODBC-devel libssh2-devel OpenIPMI OpenIPMI-devel java* php-ctytpe php-xlmwriter php-net-socket libxml mysql-devel
if [ $? -eq 0 ];then
    echo "Successfully yum"
else 
    echo "Yum Failed!"
    exit 1
fi

#安装包
cd /root
wget https://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/3.2.6/zabbix-3.2.6.tar.gz

#编译安装
mkdir -p /data/zabbix
mkdir /root/zabbix_code
tar zxf zabbix-3.2.6.tar.gz -C /root/zabbix_code
cd /root/zabbix_code/zabbix-3.2.6
./configure --prefix=/data/zabbix --enable-proxy  --enable-agent  --enable-ipv6  --with-mysql --with-net-snmp  --with-libcurl  --with-openipmi  --with-unixodbc
make && make install


read -p "Please Choose agent/proxy !:" choose
ID=$choose
if [ $ID = 'agent' ]
then
    cd /data/zabbix
    cp /data/zabbix/etc/zabbix_agentd.conf /data/zabbix/etc/zabbix_agentd.conf_bak
	sed -i -e s/Server=127.0.0.1/Server=172.16.230.65/g /data/zabbix/etc/zabbix_agentd.conf
	sed -i -e s/^ServerActive=127.0.0.1/ServerActive=172.16.230.57/g /data/zabbix/etc/zabbix_agentd.conf
	sed -i -e '/Timeout=3/ a\Timeout=10' /data/zabbix/etc/zabbix_agentd.conf
	sed -i -e "s/^Hostname=Zabbix server/Hostname=$HOSTNAME/g" /data/zabbix/etc/zabbix_agentd.conf
	echo "zabbix          ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
    echo "/data/zabbix/sbin/zabbix_agentd -c /data/zabbix/etc/zabbix_agentd.conf" > /data/zabbix/start_agent.sh
    echo "kill -2 `ps -ef | grep zabbix_agentd | grep -v grep | awk '{print $2}'`" > /data/zabbix/stop_agent.sh
    chmod +x /data/zabbix/start_agent.sh
    chmod +x /data/zabbix/stop_agent.sh
    sh /data/zabbix/start_agent.sh
    ps -ef | grep zabbix | grep -v grep        
fi
if [ $ID = 'proxy' ]
then
    cd /data/zabbix
    cp /data/zabbix/etc/zabbix_proxy.conf /data/zabbix/etc/zabbix_proxy.conf_bak
    mysql -uroot -p$mysql_root_password -S /data/mysql/tmp/mysql.sock -e "create database zabbix_proxy character set utf8;grant all privileges on zabbix_proxy.* to zabbix@localhost identified by '2abbixProxyDB';flush privileges;"
    mysql -uzabbix -p$mysql_zabbix_password zabbix_proxy </data/zabbix/database/mysql/schema.sql -S /data/mysql/tmp/mysql.sock

	sed -i -e s/Server=127.0.0.1/Server=42.62.85.10/g /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e s/^ServerActive=127.0.0.1/ServerActive=172.16.230.57/g /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e '/Timeout=3/ a\Timeout=10' /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e '/ListenPort=10051/ a\ListenPort=10051' /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e '/Timeout=3/ a\Timeout=10' /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e '/DBSocket=/tmp/mysql.sock/ a\DBSocket=/data/mysql/tmp/mysql.sock' /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e '/ConfigFrequency=3600/ a\ConfigFrequency=120' /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e '/DataSenderFrequency=1/ a\DataSenderFrequency=60' /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e '/LogSlowQueries=0/ a\LogSlowQueries=3000' /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e '/DBPassword=/ a\DBPassword=2abbixProxyDB' /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e "s/^Hostname=Zabbix server/Hostname=$HOSTNAME/g" /data/zabbix/etc/zabbix_proxy.conf
	echo "zabbix          ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
    echo "/data/zabbix/sbin/zabbix_proxy -c /data/zabbix/etc/zabbix_proxy.conf" > /data/zabbix/start_proxy.sh
    echo "kill -2 `ps -ef | grep zabbix_proxy | grep -v grep | awk '{print $2}'`" > /data/zabbix/stop_proxy.sh
    chmod +x /data/zabbix/start_proxy.sh
    chmod +x /data/zabbix/stop_proxy.sh
    sh /data/zabbix/start_proxy.sh
    ps -ef | grep zabbix | grep -v grep        
        
fi



拷贝zabbixagent.tar.gz安装：
在57上：
scp /root/zabbixagent.tar.gz 172.16.230.58:/root/
58上：
#!/bin/bash
HOSTNAME=`hostname`
#localIP=`hostname -i`
localIP=10.10.108.74
checkZabbix=`ps -ef | grep zabbix | grep -v grep`

groupadd zabbix
useradd -g zabbix zabbix
yum install -y gcc mysql-community-devel libxml2-devel unixODBC-devel net-snmp-devel libcurl-devel libssh2-devel OpenIPMI-devel openssl-devel openldap-devel
if [ $? -eq 0 ];then
    echo "Successfully yum"
else
    echo "Yum Failed!"
    exit 1
fi
read -p "Please Choose agent/proxy !:" choose
ID=$choose
if [ $ID = 'agent' ]
then
host-10-10-108-74
10.10.108.74
    mkdir -p /data/zabbix
    tar -zxvf zabbixagent.tar.gz -C /data/zabbix/
    cp /data/zabbix/etc/zabbix_agentd.conf /data/zabbix/etc/zabbix_agentd.conf_bak
	sed -i -e s/Server=127.0.0.1/Server=$localIP/g /data/zabbix/etc/zabbix_agentd.conf
	sed -i -e s/^ServerActive=127.0.0.1/ServerActive=$localIP/g /data/zabbix/etc/zabbix_agentd.conf
	sed -i -e '/Timeout=3/ a\Timeout=10' /data/zabbix/etc/zabbix_agentd.conf
	sed -i -e "s/^Hostname=Zabbix server/Hostname=$HOSTNAME/g" /data/zabbix/etc/zabbix_agentd.conf
	echo "zabbix          ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
    echo "/data/zabbix/sbin/zabbix_agentd -c /data/zabbix/etc/zabbix_agentd.conf" > /data/zabbix/start_agent.sh
    echo "kill -2 `ps -ef | grep zabbix_agentd | grep -v grep | awk '{print $2}'`" > /data/zabbix/stop_agent.sh
    chmod +x /data/zabbix/start_agent.sh
    chmod +x /data/zabbix/stop_agent.sh
    sh /data/zabbix/start_agent.sh
    ps -ef | grep zabbix | grep -v grep        
fi
if [ $ID = 'proxy' ]
then
    mkdir -p /data/zabbix
    tar -zxvf zabbix_proxy.tar.gz -C /data/zabbix/
    cp /data/zabbix/etc/zabbix_proxy.conf /data/zabbix/etc/zabbix_proxy.conf_bak
    mysql -uroot -p$mysql_root_password -S /data/mysql/tmp/mysql.sock -e "create database zabbix_proxy character set utf8;grant all privileges on zabbix_proxy.* to zabbix@localhost identified by '2abbixProxyDB';flush privileges;"
    mysql -uzabbix -p$mysql_zabbix_password zabbix_proxy </data/zabbix/database/mysql/schema.sql -S /data/mysql/tmp/mysql.sock

	sed -i -e s/Server=127.0.0.1/Server=42.62.85.10/g /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e s/^ServerActive=127.0.0.1/ServerActive=$localIP/g /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e '/Timeout=3/ a\Timeout=10' /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e '/ListenPort=10051/ a\ListenPort=10051' /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e '/Timeout=3/ a\Timeout=10' /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e '/DBSocket=/tmp/mysql.sock/ a\DBSocket=/data/mysql/tmp/mysql.sock' /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e '/ConfigFrequency=3600/ a\ConfigFrequency=120' /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e '/DataSenderFrequency=1/ a\DataSenderFrequency=60' /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e '/LogSlowQueries=0/ a\LogSlowQueries=3000' /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e '/DBPassword=/ a\DBPassword=2abbixProxyDB' /data/zabbix/etc/zabbix_proxy.conf
	sed -i -e "s/^Hostname=Zabbix server/Hostname=$HOSTNAME/g" /data/zabbix/etc/zabbix_proxy.conf
	echo "zabbix          ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
    sh /data/zabbix/start_proxy.sh
    ps -ef | grep zabbix | grep -v grep        
        
fi




172.31.6.203
mkdir -p /data/zabbix
tar -zxvf zabbixagent.tar.gz -C /data/zabbix/
sed -i -e s/Server=127.0.0.1/Server=172.16.230.65/g /data/zabbix/etc/zabbix_agentd.conf
sed -i -e s/^ServerActive=127.0.0.1/ServerActive=172.16.230.65/g /data/zabbix/etc/zabbix_agentd.conf
sed -i -e '/Timeout=3/ a\Timeout=10' /data/zabbix/etc/zabbix_agentd.conf
sed -i -e "s/^Hostname=Zabbix server/Hostname=$HOSTNAME/g" /data/zabbix/etc/zabbix_agentd.conf
echo "zabbix          ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
sh /data/zabbix/start_agent.sh
ps -ef | grep zabbix | grep -v grep



