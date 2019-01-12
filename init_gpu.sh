#/bin/bash

HOSTNAME=`hostname`
checkLDAP=`ps -ef | grep nslcd | grep -v grep | wc -l`
checkZabbix=`ps -ef | grep zabbix | grep -v grep | wc -l`

function repo {
	yum clean all
	rm -rf /tmp/yum.bak
	mkdir /tmp/yum.bak
	mv /etc/yum.repos.d/* /tmp/yum.bak
	curl --silent http://mirrors.hobot.cc/centos/repo-centos-7.5/rhel7.5.repo.tar.gz -o  /etc/yum.repos.d/rhel7.5.repo.tar.gz && cd /etc/yum.repos.d/ && tar xvf rhel7.5.repo.tar.gz && rm -fr rhel7.5.repo.tar.gz
	yum repolist
	yum upgrade -y && reboot
}

function mellanox {
	yum -y install pciutils libnl tcsh tk lsof redhat-rpm-config rpm-build createrepo
	curl --silent http://10.10.10.35/tools/gpucluster/MLNX_OFED_LINUX-3.4-2.0.0.0-rhel7.3-x86_64.tgz -o MLNX_OFED_LINUX-3.4-2.0.0.0-rhel7.3-x86_64.tgz && tar xf MLNX_OFED_LINUX-3.4-2.0.0.0-rhel7.3-x86_64.tgz && rm -fr MLNX_OFED_LINUX-3.4-2.0.0.0-rhel7.3-x86_64.tgz >> /dev/null 2>&1
	ls -d  MLNX_OFED_LINUX-3.4-2.0.0.0-rhel7.3-x86_64
	./MLNX_OFED_LINUX-3.4-2.0.0.0-rhel7.3-x86_64/mlnxofedinstall --add-kernel-support
	reboot
}

function packages {
	yum -y install smartmontools gcc-c++ htop lsof ntp tree nfs-utils unzip gcc-c++ make bind-utils ntpdate pylint incron libcgroup  libcgroup-tools openldap-clients nss-pam-ldapd epel-release yum-utils openblas opencv python-devel opencv-python rsync psmisc gdb net-tools dstat sysstat perf strace numactl hwloc-devel java-1.7.0-openjdk emacs tmux vim git wget gtest-devel mpich mpich-devel ganglia-gmond ganglia-gmond-python gtest lrzsz sox python-pillow glog p7zip glog-devel gflags-devel opencv-devel openblas-devel java-1.7.0-openjdk-devel cmake boost boost-devel python-matplotlib ffmpeg ffmpeg-devel gtk3-devel python2-pip ambari-agent expect gcc kernel-headers kernel-devel dkms gperftools gperftools-devel gperftools-libs
	pip install --upgrade pip -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
	env MPICC=/usr/lib64/mpich/bin/mpicc pip install mpi4py  -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
	pip install pyyaml easydict==1.7 supervisor hdfs pip virtualenv bumpy spicy matplotlib nvidia-ml-py mpi4py protobuf==3.3.0 setuptools==33.1.1  ipython==5.3.0 numpy==1.11.1   jupyter cython  -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
	yum install http://downloads.linux.hpe.com/SDR/repo/mlnx_ofed/suse/SLES12-SP2/x86_64/3.4-2.0.0.0/mpi-selector-1.0.3-1.34100.x86_64.rpm -y
	debuginfo-install glibc -y
	yum install -y python-debuginfo.x86_64
	pip install jupyter  --trusted-host pypi.douban.com
	pip install tensorflow==1.2.0 tensorflow-tensorboard==0.1.4 -i http://pypi.douban.com/simple  --trusted-host pypi.douban.com
	if [ $? -eq  0 ];then
		echo "Packages Install Successful..." >> ./public-init.log
		echo "pip Packages Sum: "
		pip freeze | wc -l >> ./init.log
	else
        	echo "Packages Install failed..." >> ./public-init.log
	fi
}
function init {
#	umount /home/
#	spawn lvremove /dev/cl/home
#	expect "Do you really want to remove active logical volume centos/home? [y/n]:"
#	send "y\r"
#	lvextend -L +890G /dev/cl/root
#	xfs_growfs /dev/cl/root
	systemctl disable firewalld
	systemctl stop firewalld
	setenforce 0
	sed -i 's/SELINUX=Enforcing/SELINUX=disabled/g' /etc/selinux/config
#	/usr/bin/expect <<-EOF
#	spawn ssh-keygen
#	expect "Enter file in which to save the key (/root/.ssh/id_rsa):"
#	send "\r"
#	expect "Enter passphrase (empty for no passphrase):"
#	send "\r"
#	expect "Enter same passphrase again:"
#	send "\r"
#	expect eof
#	EOF
	systemctl start ntpdate
	chkconfig ntpdate on
	systemctl start ntpd
	systemctl enable ntpd
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	mkdir /etc/incron
	echo gpuwork >> /etc/incron/allow
	systemctl enable incrond
	echo -e "fs.may_detach_mounts = 1\nfs.may_detach_mounts = 1" >> /etc/sysctl.conf
	echo -e "vm.oom_kill_allocating_task = 1\nvm.overcommit_memory = 1\nvm.overcommit_ratio = 85" >> /etc/sysctl.d/99-sysctl.conf
	sysctl -p
#	sysctl -a|egrep "overcommit|oom_kill"
	sed -i -e 's/auto/1G/g' /etc/sysconfig/grub
	sed -i -e 's/auto/1G/g' /etc/default/grub
	grub2-mkconfig -o /boot/grub2/grub.cfg
}

function format {
	# format xfs
	wget http://mirrors.hobot.cc/tools/gpucluster/formatdisk.exp
	chmod +x /root/formatdisk.exp
	for disk in a b c d e f g h i j k l m n o p
	do
		expect /root/formatdisk.exp /dev/sd$disk;
	done
	mkdir /mnt/hdfs-data-{1..16}
	for i in  a b c d e f g h i j k l m n o p
	do
	dra=/mnt/hdfs-data-1
	drb=/mnt/hdfs-data-2
	drc=/mnt/hdfs-data-3
	drd=/mnt/hdfs-data-4
	dre=/mnt/hdfs-data-5
	drf=/mnt/hdfs-data-6
	drg=/mnt/hdfs-data-7
	drh=/mnt/hdfs-data-8
	dri=/mnt/hdfs-data-9
	drj=/mnt/hdfs-data-10
	drk=/mnt/hdfs-data-11
	drl=/mnt/hdfs-data-12
	drm=/mnt/hdfs-data-13
	drn=/mnt/hdfs-data-14
	dro=/mnt/hdfs-data-15
	drp=/mnt/hdfs-data-16
	uuid=`blkid /dev/sd\$i | awk '{print $2}' | cut -d "\"" -f2`
        eval echo "UUID=$uuid \$dr$i xfs defaults 0 0" >> /etc/fstab
	done
	mount -a
	lsblk >> ./init.log
}

function ldap {
	yum install openldap-clients nss-pam-ldapd -y
	touch /etc/ssh/login.users.allowed
	rpm -qa|grep sssd|xargs yum remove -y
	sed -i -e s/USESSSD=yes/USESSSD=no/g /etc/sysconfig/authconfig
	sed -i -e s/USESSSDAUTH=yes/USESSSDAUTH=no/g /etc/sysconfig/authconfig
	sed -i '/auth       include      postlogin/ a\auth       required     pam_listfile.so item=user sense=allow file=/etc/ssh/login.users.allowed onerr=fail' /etc/pam.d/sshd
	authconfig --enableldap --enableldapauth --ldapserver=dc001.hosso.cc,dc002.hosso.cc --ldapbasedn="dc=hosso,dc=cc" --enablemkhomedir --update
	echo -e "shanzhi.yu\nyanbing.du\nyuan01.liu" >> /etc/ssh/login.users.allowed
	echo "shanzhi.yu      ALL=(ALL)       ALL" >> /etc/sudoers
	echo "yanbing.du      ALL=(ALL)       ALL" >> /etc/sudoers
	echo "yuan01.liu      ALL=(ALL)       ALL" >> /etc/sudoers
	systemctl status nslcd
}

function mpi {
	# mvapich2-2.2
        mkdir /usr/mpi/gcc -p
	curl http://mirrors.hobot.cc/tools/update/mvapich2-2.2.tar.gz -o /usr/mpi/gcc/mvapich2-2.2.tar.gz
	tar xvf /usr/mpi/gcc/mvapich2-2.2.tar.gz -C /usr/mpi/gcc/
	mpi-selector --unregister mvapich2-2.3a
	mpi-selector --register mvapich2-2.2 --source-dir /usr/mpi/gcc/mvapich2-2.2/bin/
	mpi-selector --set mvapich2-2.2 --system --yes
	runuser -l gpuwork -c 'mpi-selector --set mvapich2-2.2 --yes'
	mpi-selector --user root --set mvapich2-2.2 --yes
	mpi-selector --set mvapich2-2.2 --system --yes
	mpi-selector --query --user gpuwork
	mpi-selector --query --system
	pip uninstall mpi4py --yes
	mkdir /home/users/gpuwork/mpi_jobs/
	chown gpuwork:hogpu-bot /home/users/gpuwork/mpi_jobs/
	env MPICC=/usr/lib64/mpich/bin/mpicc pip install mpi4py==2.0.0  -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
	pip install mpi4py==2.0.0 --no-cache-dir -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
}

function nvidiagraph {
	# [driver version 384.90]
	# nvidia-uninstall -s
	wget http://mirrors.hobot.cc/nvidia/NVIDIA-Linux-x86_64-396.45.run
	yum install -y acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig
	echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
	sed -i -e 's/quiet/quiet rd.driver.blacklist=nouveau/g' /etc/sysconfig/grub
	grub2-mkconfig -o /boot/grub2/grub.cfg
	yum remove xorg-x11-drv-nouveau -y
	mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r)-nouveau.img
	dracut /boot/initramfs-$(uname -r).img $(uname -r)
	systemctl set-default multi-user.target
	#reboot
	sh NVIDIA-Linux-x86_64-387.34.run -s
	systemctl set-default graphical.target
	echo "check nvidia-smi: " >> ./init.log
	nvidia-smi >> ./init.log
	#reboot
}

function nvidianograph {
	# [driver version 384.90]
	# nvidia-uninstall -s
	wget http://mirrors.hobot.cc/nvidia/NVIDIA-Linux-x86_64-387.34.run
	sh NVIDIA-Linux-x86_64-387.34.run -s
	echo "check nvidia-smi: " >> ./init.log
	nvidia-smi >> ./init.log
}

function cuda {
	wget http://mirrors.hobot.cc/zabbix/gpu-init/20171127/cuda-install-20171127.tar.gz -P /tmp/ && tar xf /tmp/cuda-install-20171127.tar.gz -C /tmp/ && rm -fr /tmp/cuda-install-20171127.tar.gz
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

	# install nccl
	curl http://mirrors.hobot.cc/tools/update/nccl-update-080410/include/nccl.h -o /usr/local/cuda-8.0/include/nccl.h
	curl http://mirrors.hobot.cc/tools/update/nccl-update-080410/lib64/libnccl.so -o /usr/local/cuda-8.0/lib64/libnccl.so
	curl http://mirrors.hobot.cc/tools/update/nccl-update-080410/lib64/libnccl.so.2 -o /usr/local/cuda-8.0/lib64/libnccl.so.2
	curl http://mirrors.hobot.cc/tools/update/nccl-update-080410/lib64/libnccl.so.2.1.4 -o /usr/local/cuda-8.0/lib64/libnccl.so.2.1.4
	curl http://mirrors.hobot.cc/tools/update/nccl-update-080410/lib64/libnccl_static.a -o /usr/local/cuda-8.0/lib64/libnccl_static.a

	# install nvidia ganglia modules
	tar xfz /tmp/cuda-install/ganglia-gpu.tar.gz -C /tmp/cuda-install/
	cp /tmp/cuda-install/nvidia/python_modules/nvidia.py /usr/lib64/ganglia/python_modules/
	cp /tmp/cuda-install/nvidia/conf.d/nvidia.pyconf /etc/ganglia/conf.d/
	rm -rf /tmp/cuda-install/nvidia
	service gmond restart

	# install nvidia-docker
	wget http://mirrors.hobot.cc/zabbix/software/nvidia-docker-1.0.1-1.x86_64.rpm
	rpm -ivh nvidia-docker-1.0.1-1.x86_64.rpm
	systemctl start nvidia-docker
	systemctl enable nvidia-docker
	echo "Cuda Version: " >> ./init.log
	cat /usr/local/cuda/version.txt >> ./init.log
	echo "Cudnn Version: " >> ./init.log
	cat /usr/local/cuda-8.0/include/cudnn.h | grep CUDNN_MAJOR -A 2 >> ./init.log
}

function caddy {
	wget http://mirrors.hobot.cc/zabbix/gpu-init/20171127/caddy-20171127.tar.gz -P /home/users/gpuwork
	tar xf /home/users/gpuwork/caddy-20171127.tar.gz -C /home/users/gpuwork/
	chown -R gpuwork:hogpu-bot /home/users/gpuwork/caddy
	cp /home/users/gpuwork/caddy/caddy /usr/local/bin/
	runuser -l gpuwork -c 'supervisord -c ~/caddy/supervisord.conf'

}

function torque {
	mkdir /tmp/torque-install && curl --silent http://mirrors.hobot.cc/tools/update/torque_6.1.1.1_20170714.tar.gz  -o  /tmp/torque-install/torque_6.1.1.1_20170714.tar.gz && curl --silent http://10.10.10.35/tools/gpucluster/mom_priv.tar.gz -o /tmp/torque-install/mom_priv.tar.gz
	cp /tmp/torque-install/torque_6.1.1.1_20170714.tar.gz /home/users/gpuwork
	tar xf /tmp/torque-install/torque_6.1.1.1_20170714.tar.gz -C /home/users/gpuwork
	sh /home/users/gpuwork/torque_6.1.1.1_20170714/torque-package-clients-linux-x86_64.sh --install
	sh /home/users/gpuwork/torque_6.1.1.1_20170714/torque-package-devel-linux-x86_64.sh --install
	sh /home/users/gpuwork/torque_6.1.1.1_20170714/torque-package-doc-linux-x86_64.sh --install
	sh /home/users/gpuwork/torque_6.1.1.1_20170714/torque-package-mom-linux-x86_64.sh --install
	curl --silent http://mirrors.hobot.cc/tools/gpucluster/qsub_i.conf -o /etc/qsub_i.conf
	curl --silent http://mirrors.hobot.cc/tools/update/qsub_i-20171115 -o /usr/local/bin/qsub_i
	chmod 755 /usr/local/bin/qsub_i
	mv /var/spool/torque/mom_priv /var/spool/torque/mom_priv_backup
	wget http://mirrors.hobot.cc/zabbix/gpu-init/20171127/mom_priv-20171127.tar.gz -P /var/spool/torque/
	tar xf /var/spool/torque/mom_priv-20171127.tar.gz -C /var/spool/torque/
	sed -i 's/trainvm003.hogpu.cc/trainvm004.hogpu.cc/g' /var/spool/torque/mom_priv/config
	sed -i 's/trainvm001.hogpu.cc/trainvm004.hogpu.cc/g' /etc/qsub_i.conf
	sed -i 's/queue_gpu/smart_auto/g' /etc/qsub_i.conf
	echo "trainvm004.hogpu.cc" > /var/spool/torque/server_name
	systemctl restart trqauthd
	systemctl enable trqauthd
	chkconfig pbs_mom on
	chmod 777 /var/spool/torque/spool/
	service pbs_mom restart
	service pbs_mom status
	# libnvidia-ml.so.384.90 cp it from other host
	# ln -s /usr/local/lib64/libnvidia-ml.so.384.90 /usr/local/lib64/libnvidia-ml.so.1
	# ln -s /usr/local/lib64/libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so.1
	# yum install -y hwloc-libs
	# /var/spool/torque/server_priv/nodes
	# /etc/hosts.equiv // allow to submit jobs
}

function ambari {
	mkdir /opt/hdfs
	sed -i 's/verify=platform_default/verify=disable/' /etc/python/cert-verification.cfg
	echo "`hostname`:/ /opt/hdfs nfs vers=3,proto=tcp,retrans=10,timeo=600,hard,rsize=1048576,wsize=1048576,nolock,sync 0 0" >> /etc/fstab
	wget http://mirrors.hobot.cc/HDFS/client/hadoop-2.7.2.tar.gz -C /home/users/gpuwork/
	tar xf /home/users/gpuwork/hadoop-2.7.2.tar.gz -C /home/users/gpuwork/
	cat <<-EOF >> /home/users/gpuwork/.bashrc
	export JAVA_HOME=/usr/lib/jvm/jre-1.8.0
	export HADOOP_PREFIX=/home/users/gpuwork/hadoop-2.7.2
	export HADOOP_HOME=\$HADOOP_PREFIX
	export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$HADOOP_PREFIX/lib/native:\$JAVA_HOME/lib/amd64/server
	export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/cuda-7.5/lib64:/usr/local/cuda-8.0/lib64/
	EOF
}

function ganglia {
	read -p "Please enter agent port: " port
	sed -i s/8649/$port/g /etc/ganglia/gmond.conf
	systemctl restart gmond
	systemctl enable gmond
}

function zabbix {
	wget http://mirrors.hobot.cc/zabbix/zabbix/zabbix-agent-3.2.6-1.el7.x86_64.rpm
	rpm -ivh zabbix-agent-3.2.6-1.el7.x86_64.rpm
	sed -i -e s/Server=127.0.0.1/Server=10.9.1.22/g /etc/zabbix/zabbix_agentd.conf
	sed -i -e s/^ServerActive=127.0.0.1/ServerActive=10.9.1.22/g /etc/zabbix/zabbix_agentd.conf
	sed -i -e '/Timeout=3/ a\Timeout=10' /etc/zabbix/zabbix_agentd.conf
	sed -i '/EnableRemoteCommands=0/ a\EnableRemoteCommands=1' /etc/zabbix/zabbix_agentd.conf
	sed -i -e "s/^Hostname=Zabbix server/Hostname=$HOSTNAME/g" /etc/zabbix/zabbix_agentd.conf
	echo "zabbix          ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
	mkdir /etc/zabbix/script
	wget http://mirrors.hobot.cc/zabbix/zabbix/userparameter_hobot.conf -P /etc/zabbix/zabbix_agentd.d
	systemctl start zabbix-agent
	systemctl enable zabbix-agent
}


echo "+---------------------------------------+"
echo "|                                       |"
echo "|     1. update yum repos to local's    |"
echo "|     2. install packages               |"
echo "|     3. formatdisk & mount             |"
echo "|     4. install mellanox driver        |"
echo "|     5. install ganglia                |"
echo "|     6. install cuda                   |"
echo "|     7. configure ldap                 |"
echo "|     8. install torque client          |"
echo "|     9. install incrontab              |"
echo "|     10. install zabbix-agent          |"
echo "|     11. install mpi	              |"
echo "|     all. all operation                |"
echo "|                                       |"
echo "+---------------------------------------+"

read -p "Please select your choice: " choice
case $choice in
	all)
		repo
		packages
		formatdisk
		mellanox
		ganglia
		cuda
		ldap
		torque
		incrontab
		zabbix
		mpi
		sleep 1
		;;
	1)
		repo
		sleep 1
		;;
	2)
		packages
		sleep 1
		;;
	3)
		formatdisk
		sleep 1
		;;
	4)
		mellanox
		sleep 1
		;;
	5)
		ganglia
		sleep 1
		;;
	6)
		cuda
		sleep 1
		;;
	7)
		ldap
		sleep 1
		;;
	8)
		torque
		sleep 1
		;;
	9)
		incrontab
		sleep 1
		;;
	10)
		zabbix
		sleep 1
		;;
	11)
		mpi
		sleep 1
		;;
esac
