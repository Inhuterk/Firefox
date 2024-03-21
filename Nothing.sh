#!/bin/bash

random() {
    tr </dev/urandom -dc A-Za-z0-9 | head -c5
    echo
}

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)

gen64() {
    ip64() {
        echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
    }
    echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
}

install_3proxy() {
    echo "installing 3proxy"
    URL="https://raw.githubusercontent.com/quayvlog/quayvlog/main/3proxy-3proxy-0.8.6.tar.gz"
    
    yum -y install gcc net-tools bsdtar zip >/dev/null
    
    yum -y install curl wget nano make
    
    wget -qO- $URL | bsdtar -xvf-
    
    cd 3proxy-3proxy-0.8.6 || exit
    make -f Makefile.Linux
    mkdir -p /usr/local/etc/3proxy/bin
    mkdir -p /usr/local/etc/3proxy/logs
    mkdir -p /usr/local/etc/3proxy/stat
    cp src/3proxy /usr/local/etc/3proxy/bin/
    cp ./scripts/rc.d/proxy.sh /etc/init.d/3proxy
    chmod +x /etc/init.d/3proxy
    systemctl daemon-reload
    systemctl enable 3proxy
    systemctl start 3proxy
    cd "$WORKDIR" || exit
}

gen_3proxy() {
    cat <<EOF
daemon
maxconn 4000
nserver 1.1.1.1
nserver 8.8.4.4
nserver 2001:4860:4860::8888
nserver 2001:4860:4860::8844
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
stacksize 6291456 
flush
auth strong
EOF

awk -F "/" '{print "auth strong\n" \
"allow " $1 "\n" \
"proxy -6 -n -a -p" $4 " -i" $3 " -e"$5"\n" \
"flush\n"}' "${WORKDATA}"
}

gen_proxy_file_for_user() {
    cat >proxy.txt <<EOF
$(awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2 }' "${WORKDATA}")
EOF
}

upload_proxy() {
    local PASS=$(random)
    zip --password "$PASS" proxy.zip proxy.txt
    URL=$(curl -s --upload-file proxy.zip https://transfer.sh/proxy.zip)

    echo "Proxy is ready! Format IP:PORT:LOGIN:PASS"
    echo "Download zip archive from: ${URL}"
    echo "Password: ${PASS}"

}

gen_data() {
    seq "$FIRST_PORT" "$LAST_PORT" | while read -r port; do
        echo "usr$(random)/pass$(random)/$IP4/$port/$(gen64 "$IP6")"
    done
}

gen_iptables() {
    awk -F "/" '{print "iptables -I INPUT -p tcp --dport " $4 "  -m state --state NEW -j ACCEPT"}' "${WORKDATA}"
}

gen_ifconfig() {
    awk -F "/" '{print "ifconfig ens33 inet6 add " $5 "/64"}' "${WORKDATA}"
}

echo "installing apps"

# Check if the directory exists and remove it if it does
WORKDIR="/home/proxy-installer"
if [ -d "$WORKDIR" ]; then
    echo "Removing existing directory: $WORKDIR"
    rm -rf "$WORKDIR" || { echo "Failed to remove directory $WORKDIR"; exit 1; }
fi

echo "Creating new directory: $WORKDIR"
mkdir -p "$WORKDIR" && cd "$WORKDIR" || { echo "Failed to create or change directory to $WORKDIR"; exit 1; }

cd "$WORKDIR" || exit

install_3proxy || { echo "Failed to install 3proxy"; exit 1; }

IP4=$(curl -4 -s icanhazip.com)
IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')

echo "Internal ip = ${IP4}. External sub for ip6 = ${IP6}"

echo "How many proxy do you want to create? Example 500"
read -r COUNT

FIRST_PORT=22000
LAST_PORT=$((FIRST_PORT + COUNT))

gen_data >"$WORKDIR/data.txt"
gen_iptables >"$WORKDIR/boot_iptables.sh"
gen_ifconfig >"$WORKDIR/boot_ifconfig.sh"

gen_3proxy >/usr/local/etc/3proxy/3proxy.cfg || { echo "Failed to generate 3proxy configuration"; exit 1; }

cat >>/etc/rc.local <<EOF
bash ${WORKDIR}/boot_iptables.sh
bash ${WORKDIR}/boot_ifconfig.sh
ulimit -n 10048
systemctl start 3proxy || { echo "Failed to start 3proxy service"; exit 1; }
EOF

bash /etc/rc.local || { echo "Failed to execute /etc/rc.local"; exit 1; }

gen_proxy_file_for_user

upload_proxy
