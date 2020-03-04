#!/bin/bash
# 1.定义基本变量
INET_IF="eth1"                 #外网接口
INET_IP="x.x.x.x"         #外网接口地址
LAN_IF="eth0"                  #内网接口
LAN_IP="x.x.x.x"           #内网接口地址
#LAN_NET="192.168.1.0/24"       #内网网段
#LAN_WWW_IP="192.168.1.7"       #网站服务器的内部地址
IPT="/sbin/iptables"           #iptables命令的路径
MOD="/sbin/modprobe"           #modprode命令的路径
CTL="/sbin/sysctl"             #sysctl命令的路径
# 2.加载内核模块
$MOD ip_tables              #iptables基本模块
$MOD ip_conntrack           #连接跟踪模块
$MOD ipt_REJECT             #拒绝操作模块
$MOD ipt_LOG                #日志记录模块
$MOD ipt_iprange            #支持IP范围匹配
$MOD xt_state               #支持状态匹配
$MOD xt_multiport           #支持多端口匹配
$MOD xt_mac                 #支持MAC地址匹配
$MOD ip_nat_ftp             #支持TFP地址转换
$MOD ip_conntrack_ftp       #支持TFP连接跟踪  
# 3.调整/porc参数
$CTL -w net.ipv4.ip_forward=1                      #打开路由转发功能
$CTL -w net.ipv4.ip_default_ttl=128                #修改ICMP响应超时
#$CTL -w net.ipv4.icmp_echo_ignore_all=1            #拒绝响应ICMP请求
#$CTL -w net.ipv4.icmp_echo_ignore_broadcasts       #拒绝响应ICMP广播
$CTL -w net.ipv4.tcp_syncookies=1                  #启用SYN Cookie机制
$CTL -w net.ipv4.tcp_syn_retries=3                 #最大SYN请求重试次数
$CTL -w net.ipv4.tcp_synack_retries=3              #最大ACK确认重试次数
$CTL -w net.ipv4.tcp_fin_timeout=60                #TCP连接等待超时
$CTL -w net.ipv4.tcp_max_syn_backlog=3200          #SYN请求的队列长度
# 4.设置具体的防火墙规则
# 4.1删除自定义链、清空已有规则
$IPT -t filter -X       #清空各表中定义的链
$IPT -t nat -X
$IPT -t mangle -X
$IPT -t raw -X
$IPT -t filter -F       #清空各表中已有的规则
$IPT -t nat -F
$IPT -t mangle -F
$IPT -t raw -F
# 4.2定义默认规则
$IPT -P INPUT DROP
$IPT -P FORWARD ACCEPT
$IPT -P OUTPUT ACCEPT
# 4.3设置nat表中的各种策略
#$IPT -t nat -A POSTROUTING -s $LAN_NAT -o $INET_IF -j SNAT --to-source $INET_IP
#$IPT -t nat -A PREROUTING -i $INET_IF -d $INET_IP -p tcp --dport 80 -j DNAT --to-destination $LAN_WWW_IP
# 4.4设置filter表中的各种规则
##通用规则
$IPT -I INPUT 1  -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -I INPUT 2  -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
$IPT -I INPUT 3  -p icmp --icmp-type echo-request -j ACCEPT
$IPT -I INPUT 4  -p tcp  -m  multiport --dports 20,21,10050,25,3306,9999 -j ACCEPT

##特殊应用
#$IPT -A INPUT -p tcp  -m  multiport --dports 2049,3699,5433,5434,32000,32005,60011 -j ACCEPT
$IPT -A INPUT -p tcp  -m  multiport --dports 4567,3200 -j ACCEPT
#$IPT -A INPUT -p udp  -m  multiport --dports 2049,3699,5433,5434,32000,32005,60011 -j ACCEP$IPT -A INPUT -p tcp  -m  multiport --dports 4567,3200 -j ACCEPT
$IPT -A INPUT -p udp  -m  multiport --dports 4567,3200 -j ACCEPT
#$IPT -A INPUT -s 10.169.25.50 -p tcp  -m  multiport --dports 111 -j ACCEPT
#$IPT -A INPUT -s 10.169.25.50 -p udp  -m  multiport --dports 111 -j ACCEPT

#防止SYN攻击 轻量级预防
#iptables -N syn-flood  # (如果您的防火墙默认配置有“ :syn-flood - [0:0] ”则不许要该项，因为重复了)
#iptables -A INPUT -p tcp --syn -j syn-flood   
#iptables -I syn-flood -p tcp -m limit --limit 3/s --limit-burst 6 -j RETURN   
#iptables -A syn-flood -j REJECT   
#防止DOS太多连接进来,可以允许外网网卡每个IP最多15个初始连接,超过的丢弃   
#iptables -A INPUT -i eth0 -p tcp --syn -m connlimit --connlimit-above 15 -j DROP   
#用Iptables抵御DDOS (参数与上相同)   
#iptables -A INPUT  -p tcp --syn -m limit --limit 12/s --limit-burst 24 -j ACCEPT  
#iptables -A FORWARD -p tcp --syn -m limit --limit 1/s -j ACCEPT
#$IPT -A FORWARD -s $LAN_NET -o $INET_IF -p udp --dport 53 -j ACCEPT
#$IPT -A FORWARD -s $LAN_NET -o $INET_IF -p tcp -m multiport --dport 20,21,25,80,110,143,443 -j ACCEPT
#$IPT -A FORWARD -d $LAN_NET -i $INET_IF -m state ESTABLISHED,RELATED -j ACCEPT
#$IPT -A FORWARD -d $LAN_WWW_IP -p tcp --dport 80 -j ACCEPT
#$IPT -A FORWARD -d $LAN_WWW_IP -p tcp --sport 80 -j ACCEPT
# 4.5设置mangle 表中的各种策略(保留)
# 4.6设置raw 表中的各种策略(保留)
