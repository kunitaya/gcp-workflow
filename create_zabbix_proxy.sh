#!/bin/bash

dnf -y update
dnf -y install attr git telnet wget zip
dnf -y install sqlite

timedatectl set-timezone Asia/Tokyo

sed -i -r 's/(SELINUX=)[enforcing|permissive]$/\1disabled/g' /etc/selinux/config
setenforce 0
find / -exec setfattr -h -x security.selinux {} \; > /dev/null 2>&1

rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/9/x86_64/zabbix-release-6.0-4.el9.noarch.rpm
dnf clean all
dnf -y install zabbix-proxy-sqlite3 zabbix-selinux-policy

mkdir -p /var/lib/zabbix
chown -R zabbix. /var/lib/zabbix/
sed -i -r 's/(DBName)=(zabbix_proxy)$/\1=\/var\/lib\/zabbix\/\2/g' /etc/zabbix/zabbix_proxy.conf
sed -i -r 's/(Server)=127.0.0.1$/\1=34.84.91.49/g' /etc/zabbix/zabbix_proxy.conf
sed -i -r 's/(Hostname=Zabbix proxy)$/#\1/g' /etc/zabbix/zabbix_proxy.conf
systemctl enable --now zabbix-proxy
