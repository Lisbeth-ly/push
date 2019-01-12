#先申请license文件，将license文件名为“license.txt”并与您下载的其他文件

#####install_all.sh
function repo {
    #bin/bash
    yum clean all
    rm -rf /tmp/yum.bak
    mkdir /tmp/yum.bak
    mv /etc/yum.repos.d/* /tmp/yum.bak
    curl --silent http://54.222.167.140:9080/install/repo.tar.gz -o  /etc/yum.repos.d/repo.tar.gz && cd /etc/yum.repos.d/ && tar xvf repo.tar.gz && rm -fr repo.tar.gz
    yum repolist
    yum upgrade -y
    yum -y install wget java curl vim make cmake unzip gcc gcc-c++ sysstat lrzsz bind-utils git tmux net-tools ntpdate ntp expect kernel-headers kernel-devel kernel
    if [ $? -eq 0 ];then
        echo "Successfully yum"
        else
            echo "Error：Yum Failed!"
                exit 1
                fi
    ##### SElinux & Fairwall && NTP #####
    systemctl disable firewalld
    systemctl stop firewalld
    setenforce 0
    sed -i s/SELINUX=permissive/SELINUX=disabled/g /etc/selinux/config
    systemctl start ntpdate
    chkconfig ntpdate on
    systemctl start ntpd
    systemctl enable ntpd
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    reboot
}

#####install_gpu_1.sh
function disable {
    yum -y install dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig
    #disable nouveau dirver
    echo "blacklist nouveau" > /etc/modprobe.d/blacklist.conf
    count=`cat /etc/sysconfig/grub | grep 'rd.driver.blacklist=nouveau'`
    if [ ! -n "$count" ];then
      sed -i -e 's/quiet/quiet rd.driver.blacklist=nouveau/g' /etc/sysconfig/grub
    fi
    grub2-mkconfig -o /boot/grub2/grub.cfg
    yum remove xorg-x11-drv-nouveau
    mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r)-nouveau.img
    dracut /boot/initramfs-$(uname -r).img $(uname -r)
    systemctl set-default multi-user.target
    reboot
}
#####install_gpu_2.sh
function disable {
    # [driver version 384.98]
    # nvidia-uninstall -s
    wget http://mirrors.hobot.cc/nvidia/NVIDIA-Linux-x86_64-396.45.run
    sh NVIDIA-Linux-x86_64-396.45.run -s
    systemctl set-default multi-user.target
    echo "check nvidia-smi: " >> ./init.log
    nvidia-smi >> ./init.log
    if [ $? -eq 0 ];then
       echo "Successfully install nvidia!"
    else
        echo "Error：Failed install nvidia!"
        exit 1
    fi
    # install cuda
    mkdir -p /tmp/cuda-install
    wget http://mirrors.hobot.cc/zabbix/gpu-init/20171127/cuda-install-20171127.tar.gz -P /tmp/ && tar xf /tmp/cuda-install-20171127.tar.gz -C /tmp/cuda-install && rm -fr /tmp/cuda-install-20171127.tar.gz
    # install cuda-8.0, default nvidia driver version 367.54
    chmod +x /tmp/cuda-install/install-cuda.exp
    expect /tmp/cuda-install/install-cuda.exp
    # install cudnn&cub  "sh /tmp/cuda-install/install_cudnn_8.0.sh"
    tar xf /tmp/cuda-install/cudnn-8.0-linux-x64-v5.1.tar -C /tmp/cuda-install/
    mv /tmp/cuda-install/cuda/lib64/* /usr/local/cuda-8.0/lib64
    mv /tmp/cuda-install/cuda/include/cudnn.h /usr/local/cuda-8.0/include/
    rm -rf /tmp/cuda-install/cuda
    unzip /tmp/cuda-install/cub.1.5.2.zip -d /usr/local/cuda-8.0/
    ln -s /usr/local/cuda-8.0/cub-1.5.2 /usr/local/cuda-8.0/include/cub
    /usr/local/cuda-8.0/bin/nvcc --version
    if [ $? -eq 0 ];then
        echo "Successfully Install "
    else
        echo "Failed Install cuda!"
        exit 1
    fi

#####
scp -r root@10.31.40.35:/tmp/install-all/ /root/
#####

#####install_business.sh
#!/usr/bin/bash
read -p "Please confirm if your license file exists![yes\no]:" choose
if [ $choose = "yes" -o $choose = "y" ];
then
	echo "OK,Let's continue"
fi
if [ $choose = "no" -o $choose = "n" ];
then
	echo "Plecse application license document and upload the license file to the /root/ directory"
	echo "Then continue to execute this script"
	exit 1
fi
##### Check nvidia #####
nvidia-smi
if [ $? -eq 0 ];then
   echo "Successfully yum"
else
    echo "Failed install nvidia!"
    echo "please execute 'sh NVIDIA-Linux-x86_64-396.45.run -s' manually!"
    exit 1
fi
##### base #####
yum -y install python-devel.x86_64 python-pip libwebp-devel ilmbase openexr
if [ $? -eq 0 ];then
    echo "Successfully yum"
else 
    echo "python-devel.x86_64 or python-pip or libwebp-devel or ilmbase or openexr Yum Failed!"
    exit 1
fi

##### user #####
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
    echo 'work-123' | passwd --stdin work
else
    userdel -r work
    useradd work -g work -s /bin/bash -d /home/work
    echo 'work-123' | passwd --stdin work
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
tar xvf /root/install-all/work.tar.gz -C /home/work/
tar xvf /root/install-all/system.tar.gz -C /usr/lib/systemd/system/
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
if [ $? != 0 ];then
    echo "ERROR:pm2 install failed！！"
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
pip install pymongo kazoo mongoengine
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
for i in mongod.service zookeeper.service redis.service taskmanager.service http_server.service customeranalysis.service face_recognize.service feature_extract.service feature_search.service analysis_server.service notify_server.service url_server.service business_web.service
do
    systemctl enable $i 
done

##### systemctl restart #####
for i in mongod.service zookeeper.service redis.service taskmanager.service http_server.service customeranalysis.service face_recognize.service feature_extract.service feature_search.service analysis_server.service notify_server.service url_server.service business_web.service
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
    exit 1
fi

check_autoreg=`curl -H "Content-Type:application/json" -X POST -d '{"category":"autoreg"}' http://127.0.0.1:8600/category_create`
rm -rf /tmp/check_autoreg.log
echo "check command available results are: $check_autoreg" > /tmp/check_autoreg.log
if [ `grep -c "error" /tmp/check_results.log` -eq '0' ] && [ `grep -c '"is_success" : 0'  /tmp/check_results.log` -gq '0']; then

    echo "Successfully created autoreg!"
else
    echo "Failed created autoreg!"
    exit 1
fi

##### reboot #####
echo "Please reboot manually!"




