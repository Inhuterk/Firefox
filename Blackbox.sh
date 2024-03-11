#!/bin/bash

# Install wget
install_wget() {
    echo "Installing wget"
    yum -y install wget >/dev/null
}

# Additional configurations
IPV6_PRIVACY="no"
IPV6ADDR=$(ip -6 addr show ens | awk '/inet6/{print $2}' | head -n 1)
DEFAULTGW=$(ip -6 route show default | awk '/via/{print $3}' | head -n 1)

# resolvconf doesn't recognize more than 3 nameservers
DNS1=$(nmcli device show ens | awk '/IP4.DNS\[/{print $2}' | head -n 1)
DNS2=$(nmcli device show ens | awk '/IP4.DNS\[/{print $2}' | sed -n 2p)
DNS3=$(nmcli device show ens | awk '/IP4.DNS\[/{print $2}' | sed -n 3p)
DNS4="8.8.8.8"
DNS5="1.1.1.1"

# Sysconfig.txt says that PREFIX takes precedence over
# NETMASK when both are present. Since both aren't necessary,
# we'll go with PREFIX since it seems to be preferred.

# IP assignment for ens33
IPADDR0=$(nmcli device show ens | awk '/IP4.ADDRESS\[/{print $2}' | cut -f1 -d'/')
PREFIX0=$(nmcli device show ens | awk '/IP4.ADDRESS\[/{print $2}' | cut -f2 -d'/')

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
gen64() {
    ip64() {
        echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
    }
    echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
}

install_apps() {
    echo "Installing apps"
    yum -y install gcc net-tools bsdtar zip >/dev/null
}

install_3proxy() {
    echo "Installing 3proxy"
    URL="https://raw.githubusercontent.com/quayvlog/quayvlog/main/3proxy-3proxy-0.8.6.tar.gz"
    install_wget
    wget -qO- $URL | tar -xzvf -
    cd 3proxy-3proxy-0.8.6
    make -f Makefile.Linux
    mkdir -p /usr/local/etc/3proxy/bin
    mkdir -p /usr/local/etc/3proxy/logs
    mkdir -p /usr/local/etc/3proxy/stat
    cp src/3proxy /usr/local/etc/3proxy/bin/
    cp ./scripts/rc.d/proxy.sh /etc/init.d/3proxy
    chmod +x /etc/init.d/3proxy
    chkconfig 3proxy on
    cd $WORKDIR
}

gen_3proxy() {
    cat <<EOF
daemon
maxconn 1000
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
flush
auth strong

users $(awk -F "/" 'BEGIN{ORS="";} {print $1 ":CL:" $2 " "}' ${WORKDATA})

$(awk -F "/" '{print "auth strong\n" \
"allow " $1 "\n" \
"proxy -6 -n -a -p" $4 " -i" $3 " -e"$5"\n" \
"flush\n"}' ${WORKDATA})
EOF
}

gen_proxy_file_for_user() {
    cat >proxy.txt <<EOF
$(awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2 }' ${WORKDATA})
EOF
}

upload_proxy() {
    local PASS=$(random)
    zip --password $PASS proxy.zip proxy.txt
    URL=$(curl -s --upload-file proxy.zip https://transfer.sh/proxy.zip)

    echo "Proxy is ready! Format IP:PORT:LOGIN:PASS"
    echo "Download zip archive from: ${URL}"
    echo "Password: ${PASS}"
}

gen_data() {
    seq $FIRST_PORT $LAST_PORT | while read port; do
        echo "usr$(random)/pass$(random)/$IP4/$port/$(gen64 $IP6)"
    done
}

gen_iptables() {
    cat <<EOF
$(awk -F "/" '{print "iptables -I INPUT -p tcp --dport " $4 "  -m state --state NEW -j ACCEPT"}' ${WORKDATA}) 
EOF
}

gen_ifconfig() {
    cat <<EOF
$(awk -F "/" '{print "ifconfig ens inet6 add " $5 "/64"}' ${WORKDATA})
EOF
}

echo "Working folder = /home/proxy-installer"
WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"
mkdir $WORKDIR && cd $_

IP4=$(curl -4 -s icanhazip.com)
IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')

echo "Internal IP = ${IP4}. External subnet for IP6 = ${IP6}"

echo "How many proxies do you want to create? Example 500"
read COUNT

FIRST_PORT=10000
LAST_PORT=$(bc <<< "$FIRST_PORT + $COUNT")

gen_data >$WORKDIR/data.txt
gen_iptables >$WORKDIR/boot_iptables.sh
gen_ifconfig >$WORKDIR/boot_ifconfig.sh
chmod +x ${WORKDIR}/boot_*.sh /etc/rc.local

gen_3proxy >/usr/local/etc/3proxy/3proxy.cfg

cat >>/etc/rc.local <<EOF
bash ${WORKDIR}/boot_iptables.sh
bash ${WORKDIR}/boot_ifconfig.sh
ulimit -n 10048
service 3proxy start
EOF

bash /etc/rc.local

gen_proxy_file_for_user
upload_proxy
