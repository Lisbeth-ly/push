#先申请license文件，将license文件放到/root/目录下，并更名为“license.txt”.
#!/usr/bin/bash
read -p "Please confirm if your license file exists![yes\no]:" choose
if [ $choose = "yes" ]
then
	echo "OK,Let's continue!"
fi
if [ $choose = "no" ]
then
	echo "Plecse application license document and upload the license file to the /root/ directory"
	echo "Then continue to execute this script"
	exit 1
fi
##### base #####
yum -y install wget java curl vim make cmake unzip gcc gcc-c++ sysstat lrzsz bind-utils git tmux net-tools ntpdate expect
yum clean all
yum makecache
yum -y install python-devel.x86_64 python-pip gstreamer* libwebp-devel ilmbase openexr
if [ $? -eq 0 ];then
    echo "Successfully created"
else 
    echo "Created Failed"
    exit 1
fi

##### SElinux & Fairwall & NTP #####
systemctl disable firewalld
systemctl stop firewalld
setenforce 0
sed -i 's/SELINUX=Enforcing/SELINUX=disabled/g' /etc/selinux/config
systemctl start ntpdate
chkconfig ntpdate on
systemctl start ntpd
systemctl enable ntpd
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
sysctl -p

##### Basic environment #####
#wget http://54.222.167.140:9080/install/install_all.sh && sh  install_all.sh
#wget http://54.222.167.140:9080/install/install_gpu_1.sh && sh  install_gpu_1.sh   #安装过程后会重启
#wget http://54.222.167.140:9080/install/install_gpu_2.sh && sh  install_gpu_2.sh 
#scp -r root@10.31.40.35:/tmp/install-all/ /root/

##### user #####
#groupadd work
#useradd work -g work -s /bin/bash -d /home/work
egrep "work" /etc/group >& /dev/null
if [ $? -ne 0 ]
then
    groupadd work
else
    groupdel work
    groupadd work
fi

egrep "work" /etc/passwd >& /dev/null
if [ $? -ne 0 ]
then
    useradd work -g work -s /bin/bash -d /home/work
else
    userdel -r work
    useradd work -g work -s /bin/bash -d /home/work
fi
if [ $? -eq 0 ];then
    echo "Successfully created"
else 
    echo "Created Failed"
    exit 1
fi
##### system #####
cat >> /etc/security/limits.conf <<EOF
* soft nproc 65536
* hard nproc 65536
* soft nofile 65536
* hard nofile 65536
work soft nproc 65536
work hard nproc 65536
work soft nofile 65536
work hard nofile 65536
EOF
cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.ip_local_port_range = 1024 65535
net.core.somaxconn= 1024
####mongodb###########
vm.zone_reclaim_mode = 0
vm.swappiness=0
####mongodb###########
###redis##############
vm.overcommit_memory=0
####redis############
EOF

##### Check Parameter #####
sysctl -p

##### tar #####
tar xvf /root/install-all/all-server.tar.gz -C /home/work/
tar xvf /root/install-all/all-servicefile.tar.gz -C /usr/lib/systemd/system/
systemctl daemon-reload
##### ln #####
if [ ! -f "/usr/local/bin/node" ];then
    rm -rf /usr/local/bin/node
    ln -s /home/work/nodejs/bin/node /usr/local/bin/node
fi
if [ ! -f "/usr/local/bin/npm" ];then
    rm -rf /usr/local/bin/npm
    ln -s /home/work/nodejs/bin/npm /usr/local/bin/npm
fi
npm install -g pm2 && npm install
if [ $? -eq 0 ];then
    echo "Successfully install"
else 
    echo "Failed Install pm2!"
    exit 1
fi

if [ ! -f "/usr/bin/pm2" ];then
    rm -rf /usr/bin/pm2
    ln -s /home/work/nodejs/bin/pm2 /usr/bin/pm2
fi

##### Batch update #####
pip install --upgrade pip
if [ $? -eq 0 ];then
    echo "Successfully install"
else 
    echo "Failed Install pip!"
    exit 1
fi
pip install pymongo kazoo mongoengine -i http://pypi.douban.com/simple/
if [ $? -eq 0 ];then
    echo "Successfully install"
else 
    echo "Failed Install pymongo or kazoo or mongoengine!"
    exit 1
fi

##### license file #####
if [ ! -f "/home/work/face_feature_gpu/server/license.txt" ]; 
then
    cp /root/license.txt /home/work/face_feature_gpu/server/
    echo "Successful copy！"
else
    rm -rf /home/work/face_feature_gpu/server/license.txt
    echo "The old license file was deleted successfully"
    cp /root/license.txt /home/work/face_feature_gpu/server/
    echo "Successful copy！"
fi

##### authorization #####
chown -R work:work /home/work

###### systemctl enable #####
for i in mongod.service zookeeper.service redis.service taskmanager.service http_server.service customeranalysis.service face_recognize.service feature_extract.service feature_search.service analysis_server.service notify_server.service url_server.service business_web.service；
do
    systemctl enable $i 
done

##### systemctl restart #####
for i in mongod.service zookeeper.service redis.service taskmanager.service http_server.service customeranalysis.service face_recognize.service feature_extract.service feature_search.service analysis_server.service notify_server.service url_server.service business_web.service；
do
    systemctl restart $i 
done

##### heep header information #####
#curl -H "Content-Type:application/json" -X POST -d '{"category":"vipreg"}' http://127.0.0.1:8600/category_create
#curl -H "Content-Type:application/json" -X POST -d '{"category":"autoreg"}' http://127.0.0.1:8600/category_create
check_vipreg=`curl -H "Content-Type:application/json" -X POST -d '{"category":"vipreg"}' http://127.0.0.1:8600/category_create`
rm -rf /tmp/check_vipreg.log
echo "$check_vipreg" > /tmp/check_vipreg.log
#error=0 and success>0
if [ `grep -c "error" /tmp/check_results.log` -eq '0' ] && [ `grep -c '"is_success" : 0'  /tmp/check_results.log` -gt '0']; then

    echo "Successfully created vipreg!"
else
    echo "Failed created vipreg!"
fi

check_autoreg=`curl -H "Content-Type:application/json" -X POST -d '{"category":"autoreg"}' http://127.0.0.1:8600/category_create`
rm -rf /tmp/check_autoreg.log
echo "check command available results are: $check_autoreg" > /tmp/check_autoreg.log
if [ `grep -c "error" /tmp/check_results.log` -eq '0' ] && [ `grep -c '"is_success" : 0'  /tmp/check_results.log` -gq '0']; then

    echo "Successfully created autoreg!"
else
    echo "Failed created autoreg!"
fi
##### reboot #####
echo "Please reboot manually!"


