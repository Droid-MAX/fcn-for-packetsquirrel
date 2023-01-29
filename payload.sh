#!/bin/bash

DHCP_MODE=1
DNS_SERVER="8.8.8.8"

function setdns() {
	while true
	do
		[[ ! $(grep -q "$DNS_SERVER" /tmp/resolv.conf) ]] && {
			echo -e "search lan\nnameserver $DNS_SERVER" > /tmp/resolv.conf
		}
		sleep 5
	done
}

function setnet() {
	BUTTON 5s && {
		/usr/bin/NETMODE VPN
		uci set network.vpn.ifname='fcn_eth1'
		[[ "$DHCP_MODE" == "0" ]] && {
			uci set network.wan.proto=static
			uci set network.wan.ipaddr='192.168.1.100'
			uci set network.wan.netmask='255.255.255.0'
			uci set network.wan.gateway='192.168.1.1'
			uci set network.wan.dns='8.8.8.8 8.8.4.4'
		}
		uci commit
		/etc/init.d/network restart
	} || {
		/usr/bin/NETMODE BRIDGE
		[[ "$DHCP_MODE" == "0" ]] && {
			uci set network.lan.proto=static
			uci set network.lan.ipaddr='192.168.1.110'
			uci set network.lan.netmask='255.255.255.0'
			uci set network.lan.gateway='192.168.1.1'
			uci set network.lan.dns='8.8.8.8 8.8.4.4'
			uci commit
			/etc/init.d/network restart
		}
	}
}

function start() {
	LED SETUP
	DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
	setnet
	sleep 3
	${DIR}/fcn --cfg ${DIR}/fcn.conf
	/etc/init.d/sshd start &
	setdns &
	LED ATTACK
}

start &
