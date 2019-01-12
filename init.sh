#!/bin/bash

#Set DNS
/bin/cat > /etc/resolv.conf << EOF
nameserver 10.9.1.2
nameserver 10.10.10.10
search hobot.cc

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

/bin/sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config


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


yum -y install wget iptables-services wget expect telnet lrzsz vim lsof tree mlocate htop dstat 
