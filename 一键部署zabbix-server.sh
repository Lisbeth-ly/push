#!/bin/bash
#安装zabbix3.4 一键部署脚本for Centos7
src_home=`pwd`
echo -n "正在配置iptables防火墙……"
systemctl stop firewalld > /dev/null 2>&1
systemctl disable firewalld  > /dev/null 2>&1
if [ $? -eq 0 ];then
echo -n "Iptables防火墙初始化完毕！"
fi

echo -n "正在关闭SELinux……"
setenforce 0 > /dev/null 2>&1
sed -i '/^SELINUX=/s/=.*/=disabled/' /etc/selinux/config
if [ $? -eq 0 ];then
        echo -n "SELinux初始化完毕！"
fi
echo -n "正在添加zabbix用户……"
useradd -M -s /sbin/nologin zabbix && echo "OK"

#echo -n "正在配置源为192.168.20.237……"
#sed -e "s/^metalink=/#metalink=/g" \
#        -e "s/^mirrorlist=http/#mirrorlist=http/g" \
#       -e "s@^#baseurl=@baseurl=@g" \
#        -e "s@http://mirror.centos.org@http://192.168.20.237@g" \
#        -i /etc/yum.repos.d/*.repo  > /dev/null 2>&1
#if [ $? -eq 0 ];then
#        echo -n "已经配置源为192.168.20.237！"
#fi


echo -n "正在安装zabbix mariadb ……"
#rpm -ivh http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-1.el7.centos.noarch.rpm
yum install -y zabbix-server-mysql  zabbix-proxy-mysql  zabbix-web-mysql zabbix-agent mariadb* wget bash-completion
if [ $? -eq 0 ];then
        echo -n "zabbix 及mariadb 包己安装！"
fi

systemctl start mariadb
systemctl enable mariadb
if [ $? -eq 0 ];then
        echo -n "Mariadb启动完毕！"
fi

echo -n "正在为mysql的root用户设置密码……"
mysql_user_root_password="2wsx%RDX"
mysql_user_zabbix_password="Devops_zabbix"
mysqladmin -uroot -p password $mysql_user_root_password
#echo "正在执行mysql语句，创建zabbix数据库，授权zabbix访问数据库"
#mysql -e "create database zabbix character set utf8;grant all privileges on zabbix.* to zabbix@'%' identified by 'Devops_zabbix';grant all privileges on zabbix.* to zabbix@'127.0.0.1' identified by 'Devops_zabbix';grant all privileges on zabbix.* to zabbix@localhost identified by 'Devops_zabbix';flush privileges;"

echo "正在执行mysql语句，创建zabbix数据库，授权zabbix访问数据库"
mysql -uroot -p"$mysql_user_root_password" -e "create database zabbix character set utf8" && echo "创建zabbix数据库完成"
mysql -uroot -p"$mysql_user_root_password" -e "grant all privileges on zabbix.* to zabbix@localhost identified by '$mysql_user_zabbix_password'" && echo "授权zabbix本地登录数据库"
mysql -uroot -p"$mysql_user_root_password" -e "grant all privileges on zabbix.* to zabbix@'%' identified by '$mysql_user_zabbix_password'" && echo "授权任何主机本地登录数据库"

zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -pzabbix Devops_zabbix

#zabbix编译安装
echo -n "正在导入zabbix数据到mysql数据库中...."
##tar zxf ${src_home}/zabbix-3.0.4.tar.gz

cd /usr/share/doc/zabbix-server-mysql-3.4.15/
gunzip create.sql.gz
mysql -uroot -p -Dzabbix < create.sql

#mysql -uzabbix -Dzabbix Devops_zabbix < ${src_homie}/zabbix-3.0.4/database/mysql/schema.sql
#mysql -uzabbix -Dzabbix Devops_zabbix < ${src_homie}/zabbix-3.0.4/database/mysql/images.sql
#mysql -uzabbix -Dzabbix Devops_zabbix < ${src_homie}/zabbix-3.0.4/database/mysql/data.sql
if [ $? -eq 0 ];then
        echo -n "zabbix数据导入启动完毕！"
fi


echo -n "正在配置zabbix配置文件...."
cd /etc/zabbix/
sed '/# DBHost=localhost/a\DBHost=localhost' zabbix_server.conf -i
sed '/# DBPassword=/a\DBPassword=Devops_zabbix' zabbix_server.conf -i
sed '/# EnableRemoteCommands=0/a\EnableRemoteCommands=1' zabbix_agentd.conf -i
sed '/# ListenPort=10050/a\ListenPort=10050' zabbix_agentd.conf -i
sed '/# User=zabbix/a\User=zabbix' zabbix_agentd.conf -i
sed '/# AllowRoot=0/a\AllowRoot=1' zabbix_agentd.conf -i
sed '/# UnsafeUserParameters=0/a\UnsafeUserParameters=1' zabbix_agentd.conf -i
if [ $? -eq 0 ];then
        echo -n "zabbix配置完毕！"
fi

echo -n "正在启动zabbix_server and zabbix_agent...."
systemctl start zabbix-server.service
systemctl start zabbix-agent.service
systemctl enable zabbix-server.service
systemctl enable zabbix-agent.service
if [ $? -eq 0 ];then
        echo -n "zabbix-server zabbix-agent 启动完毕！"
fi

echo -n "正在进行最后的zabbix Install ,php参数修改....."


sed '/^post_max_size =/s/=.*/= 16M/' /etc/php.ini -i
sed '/^max_execution_time =/s/=.*/= 300/' /etc/php.ini -i
sed '/^max_input_time =/s/=.*/= 300/' /etc/php.ini -i
sed -i '/^;date.timezone/a\date.timezone =  Asia/Shanghai' /etc/php.ini
sed -i '/^;always_populate_raw_post_data.*/a\always_populate_raw_post_data = -1' /etc/php.ini
sed -i '/^mysqli.default_socket =/s/=.*/= \/var\/lib\/mysql\/mysql.sock/' /etc/php.ini
echo -n "正在启动httpd服务....."
systemctl start httpd
systemctl enable httpd


echo -n "正在安装中文字体支持包，解决zabbix server 乱码问题,请你耐心等待....."
yum groupinstall "fonts" -y
echo -n "使用文泉驿小黑字体"
rm /etc/alternatives/zabbix-web-font -rf
ln -s /usr/share/fonts/wqy-microhei/wqy-microhei.ttc /etc/alternatives/zabbix-web-font


echo -n "恭喜你,Zabbix 部署到此完成，如有问题，请参照脚本单独解决！！！"
echo -e -n "后续的操作:1、通过http://ip/zabbix 访问你的zabbix Web页面,下一步....一直到底。数据库密码为zabbix，web登录默认帐号密码是admin，密码是zabbix。2、你可能需要配置域名,通过域名访问Zabbix Server.... 3、你需要自己自定义或者使用系统自带模板，添加主机等等...."


yum update -y


