#!/bin/bash


#Set DNS
/bin/cat > /etc/resolv.conf << EOF
nameserver 10.9.1.2
nameserver 10.10.10.10
nameserver 10.10.201.5
search openstacklocal hobot.cc

EOF

yum clean all
rm -rf /tmp/yum.bak
mkdir /tmp/yum.bak
mv /etc/yum.repos.d/* /root/yum.bak
curl --silent http://mirrors.hobot.cc/centos/repo-centos-7.4/rhel7.4.repo.tar.gz -o  /etc/yum.repos.d/rhel7.4.repo.tar.gz && cd /etc/yum.repos.d/ && tar xvf rhel7.4.repo.tar.gz && rm -fr rhel7.4.repo.tar.gz
yum repolist
yum upgrade -y && reboot


yum -y install htop lsof ntp tree nfs-utils unzip gcc-c++ make bind-utils ntpdate pylint incron libcgroup  libcgroup-tools openldap-clients nss-pam-ldapd epel-release yum-utils openblas opencv python-devel opencv-python rsync psmisc gdb net-tools dstat sysstat perf strace numactl hwloc-devel java-1.7.0-openjdk emacs tmux vim git wget gtest-devel mpich mpich-devel ganglia-gmond ganglia-gmond-python gtest lrzsz sox python-pillow glog p7zip glog-devel gflags-devel opencv-devel openblas-devel java-1.7.0-openjdk-devel cmake boost boost-devel python-matplotlib ffmpeg ffmpeg-devel gtk3-devel python2-pip ambari-agent expect gcc kernel-headers kernel-devel dkms gperftools gperftools-devel gperftools-libs
pip install --upgrade pip -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
env MPICC=/usr/lib64/mpich/bin/mpicc pip install mpi4py  -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
pip install supervisor hdfs pip virtualenv bumpy spicy matplotlib nvidia-ml-py mpi4py protobuf==3.3.0 setuptools==33.1.1  ipython==5.3.0 numpy==1.11.1   jupyter cython  -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
yum install http://downloads.linux.hpe.com/SDR/repo/mlnx_ofed/suse/SLES12-SP2/x86_64/3.4-2.0.0.0/mpi-selector-1.0.3-1.34100.x86_64.rpm -y
debuginfo-install glibc -y
yum install -y python-debuginfo.x86_64
pip install jupyter  --trusted-host pypi.douban.com
pip install tensorflow==1.2.0 tensorflow-tensorboard==0.1.4 -i http://pypi.douban.com/simple  --trusted-host pypi.douban.com


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
sysctl -a|egrep "overcommit|oom_kill"
sed -i -e 's/auto/1G/g' /etc/sysconfig/grub
sed -i -e 's/auto/1G/g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg



systemctl disable firewalld
systemctl stop firewalld
setenforce 0
sed -i s/SELINUX=Enforcing/SELINUX=disabled/g /etc/selinux/config

touch /etc/ssh/login.users.allowed
rpm -qa|grep sssd|xargs yum remove -y
sed -i -e s/USESSSD=yes/USESSSD=no/g /etc/sysconfig/authconfig
sed -i -e s/USESSSDAUTH=yes/USESSSDAUTH=no/g /etc/sysconfig/authconfig
sed -i '/auth       include      postlogin/ a\auth       required     pam_listfile.so item=user sense=allow file=/etc/ssh/login.users.allowed onerr=fail' /etc/pam.d/sshd
authconfig --enableldap --enableldapauth --ldapserver=dc001.hosso.cc,dc002.hosso.cc --ldapbasedn="dc=hosso,dc=cc" --enablemkhomedir --update
echo -e "gpuwork\nlookjob\nshanzhi.yu\nyanbing.du\nheya.na" >> /etc/ssh/login.users.allowed
echo "shanzhi.yu      ALL=(ALL)       ALL" >> /etc/sudoers
echo "yanbing.du      ALL=(ALL)       ALL" >> /etc/sudoers
echo "heya.na      ALL=(ALL)       ALL" >> /etc/sudoers
systemctl status nslcd
su -c "incrontab -l" gpuwork
/usr/bin/expect <<-EOF
spawn runuser -l gpuwork -c ssh-keygen
expect "Enter file in which to save the key (/home/users/gpuwork/.ssh/id_rsa):"
send "\r"
expect "Enter passphrase (empty for no passphrase):"
send "\r"
expect "Enter same passphrase again:"
send "\r"
EOF




cat >> /etc/bashrc <<EOF

#history
USER_IP=\$(who -u am i 2> /dev/null | awk '{print \$NF}' | sed -e 's/[()]//g')
HISTFILESIZE=4000
HISTSIZE=4000
HISTTIMEFORMAT="%F | %T | \${USER_IP} | \$(whoami) | "
export HISTTIMEFORMAT

EOF

# Extend limit number of file descriptors and processes
/bin/echo -e "*\t\tsoft\tnofile\t65535" >> /etc/security/limits.conf
/bin/echo -e "*\t\thard\tnofile\t65535" >> /etc/security/limits.conf
/bin/sed -i '/\*.*soft.*nproc.*/d' /etc/security/limits.d/*-nproc.conf
/bin/sed -i '/\*.*hard.*nproc.*/d' /etc/security/limits.d/*-nproc.conf
/bin/echo -e "*\tsoft\tnproc\t65535" >> /etc/security/limits.d/*-nproc.conf
/bin/echo -e "*\thard\tnproc\t65535" >> /etc/security/limits.d/*-nproc.conf

yum install nscd -y
cat > /etc/nscd.conf << EOF
#logfile        /var/log/nscd.log
threads         6
max-threads     128
server-user     nscd
debug-level     5
paranoia        no
enable-cache    passwd      no
enable-cache    group       no
enable-cache    hosts       yes
positive-time-to-live   hosts       3600
negative-time-to-live   hosts       3600
suggested-size  hosts       211
check-files     hosts       yes
persistent      hosts       yes
shared          hosts       yes
max-db-size     hosts       33554432
EOF

systemctl restart nscd

echo ulimit -HSn 65535 >> /etc/rc.local
echo ulimit -HSn 65535 >> /root/.bash_profile
ulimit -u 65535
ulimit -HSn 65535


/bin/mkdir -p /root/.ssh
/bin/cat > /root/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrolLQPs2AM6Ieo/4CAHSAKuAZ7c/4XjbJUI5pQsHgXHKUqtGE6vRrETdD+Ew8bdXaXX2++0PUnZsCHF9sa4mybnC0IRLyXAKg1XbIKN0LmpCNfL8W9pBUoFq6Onv/2dr+4pfN1MkyF/2W35M7KYvRMpGZQNviAcKtNXVP4uE9p5MKrtyc6q/D7Ti2fJ5gB5QIQlqa2ssd8HLLJcD+T3cLHxyBOhOE6Krg6aAgEO4HN5WPRlyeO4ZekO/xOx/FvHdDVv9yzmLRcvgqSUSc7UIJJB7de4CfgP6llShn8nudZnpJCUGY/Xy1WNvPZrmOPiEA0Xf+5YwyfWkKM65FOME5 root@ansible.hobot.cc
EOF

/bin/chmod 0700 /root/.ssh
/bin/chmod 0600 /root/.ssh/authorized_keys
/bin/chown -R root.root /root/.ssh

# Extend limit number of file descriptors and processes
/bin/echo -e "*\t\tsoft\tnofile\t65535" >> /etc/security/limits.conf
/bin/echo -e "*\t\thard\tnofile\t65535" >> /etc/security/limits.conf

/bin/sed -i '/\*.*soft.*nproc.*/d' /etc/security/limits.d/*-nproc.conf
/bin/sed -i '/\*.*hard.*nproc.*/d' /etc/security/limits.d/*-nproc.conf
/bin/echo -e "*\tsoft\tnproc\t65535" >> /etc/security/limits.d/*-nproc.conf
/bin/echo -e "*\thard\tnproc\t65535" >> /etc/security/limits.d/*-nproc.conf

# Tune kernel arguments by edit /etc/sysctl.conf
/bin/echo "#-------------insert-------------" >> /etc/sysctl.conf
/bin/echo "net.core.rmem_max=16777215" >> /etc/sysctl.conf
/bin/echo "net.core.wmem_max=16777215" >> /etc/sysctl.conf
/bin/echo "net.core.netdev_max_backlog = 30000" >> /etc/sysctl.conf
/bin/echo "net.core.somaxconn = 65535">> /etc/sysctl.conf

/bin/echo "net.ipv4.ip_local_port_range = 1024 65535" >> /etc/sysctl.conf
/bin/echo "net.ipv4.tcp_rmem=4096 87379 16777215" >> /etc/sysctl.conf
/bin/echo "net.ipv4.tcp_wmem=4096 65535 16777215" >> /etc/sysctl.conf
/bin/echo "net.ipv4.tcp_fin_timeout = 10" >> /etc/sysctl.conf
/bin/echo "net.ipv4.tcp_tw_recycle = 0" >> /etc/sysctl.conf
/bin/echo "net.ipv4.tcp_timestamps = 1" >> /etc/sysctl.conf
/bin/echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
/bin/echo "net.ipv4.tcp_no_metrics_save=1" >> /etc/sysctl.conf
/bin/echo "net.ipv4.tcp_syncookies = 0" >> /etc/sysctl.conf
/bin/echo "net.ipv4.tcp_max_orphans = 262143" >> /etc/sysctl.conf
/bin/echo "net.ipv4.tcp_max_syn_backlog = 262143" >> /etc/sysctl.conf
/bin/echo "net.ipv4.tcp_synack_retries = 2" >> /etc/sysctl.conf
/bin/echo "net.ipv4.tcp_syn_retries = 2" >> /etc/sysctl.conf

/bin/echo "vm.swappiness = 0" >> /etc/sysctl.conf
/sbin/sysctl -p

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

