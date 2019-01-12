#安装proxy
if [ $ID = 'proxy' ]
then
    HOSTNAME=`hostname`
    mysql_root_password=2wsx%RDX
    mysql_zabbix_password=2abbixProxyDB
    yum install -y mariadb-server zabbix-proxy-mysql zabbix-get
    cp /etc/zabbix/zabbix_proxy.conf /etc/zabbix/zabbix_proxy.conf_bak
    systemctl start mariadb
    mysqladmin -u root password "2wsx%RDX";
    mysql -uroot -p$mysql_root_password  -e "create database zabbix_proxy character set utf8;grant all privileges on zabbix_proxy.* to zabbix@localhost identified by '2abbixProxyDB';flush privileges;"
    zcat /usr/share/doc/zabbix-proxy-mysql-3.0.24/schema.sql.gz | mysql -uroot -p$mysql_root_password zabbix_proxy
	sed -i -e s/Server=127.0.0.1/Server=10.9.1.22/g /etc/zabbix/zabbix_proxy.conf
	sed -i -e '/ListenPort=/ a\ListenPort=10051' /etc/zabbix/zabbix_proxy.conf
	sed -i -e '/ConfigFrequency=3600/ a\ConfigFrequency=120' /etc/zabbix/zabbix_proxy.conf
	sed -i -e '/DataSenderFrequency=1/ a\DataSenderFrequency=5' /etc/zabbix/zabbix_proxy.conf
	sed -i -e '/Timeout=3/ a\Timeout=10' /etc/zabbix/zabbix_proxy.conf
	sed -i -e "s/^Hostname=Zabbix server/Hostname=$HOSTNAME/g" /etc/zabbix/zabbix_proxy.conf
	sed -i -e '/DBPassword=/ a\DBPassword=2abbixProxyDB' /etc/zabbix/zabbix_proxy.conf
	echo "zabbix          ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
    systemctl start zabbix-proxy
    systemctl status zabbix-proxy


	sed -i -e '/ListenPort=10051/ a\ListenPort=10051' /etc/zabbix/zabbix_proxy.conf
	sed -i -e '/Timeout=3/ a\Timeout=10' /etc/zabbix/zabbix_proxy.conf
	sed -i -e '/DBSocket=/tmp/mysql.sock/ a\DBSocket=/data/mysql/tmp/mysql.sock' /etc/zabbix/zabbix_proxy.conf
	sed -i -e '/ConfigFrequency=3600/ a\ConfigFrequency=120' /etc/zabbix/zabbix_proxy.conf
	sed -i -e '/DataSenderFrequency=1/ a\DataSenderFrequency=60' /etc/zabbix/zabbix_proxy.conf
	sed -i -e '/LogSlowQueries=0/ a\LogSlowQueries=3000' /etc/zabbix/zabbix_proxy.conf
	sed -i -e '/DBPassword=/ a\DBPassword=2abbixProxyDB' /etc/zabbix/zabbix_proxy.conf
	sed -i -e "s/^Hostname=Zabbix server/Hostname=$HOSTNAME/g" /etc/zabbix/zabbix_proxy.conf
	echo "zabbix          ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
    sh /data/zabbix/start_proxy.sh
    ps -ef | grep zabbix | grep -v grep        
        
fi