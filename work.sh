
#!/bin/bash

random() {
    tr </dev/urandom -dc A-Za-z0-9 | head -c5
    echo
}

gen64() {
    array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
    ip64() {
        echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
    }
    echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
}

install_3proxy() {
    echo "Installing 3proxy"
    URL="https://raw.githubusercontent.com/quayvlog/quayvlog/main/3proxy-3proxy-0.8.6.tar.gz"
    wget -qO- "$URL" | tar -xzvf -
    cd 3proxy-3proxy-0.8.6 || exit
    make -f Makefile.Linux
    mkdir -p /usr/local/etc/3proxy/{bin,logs,stat}
    cp src/3proxy /usr/local/etc/3proxy/bin/
    cp ./scripts/rc.d/proxy.sh /etc/init.d/3proxy
    chmod +x /etc/init.d/3proxy
    chkconfig 3proxy on
    cd "$WORKDIR" || exit
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

users $(awk -F "/" 'BEGIN{ORS="";} {print $1 ":CL:" $2 " "}' "${WORKDATA}")

$(awk -F "/" '{print "auth strong\n" \
"allow " $1 "\n" \
"proxy -6 -n -a -p" $4 " -i" $3 " -e"$5"\n" \
"flush\n"}' "${WORKDATA}")
EOF
}

gen_proxy_file_for_user() {
    awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2 }' "${WORKDATA}" > proxy.txt
}

upload_proxy() {
    local PASS
    PASS=$(random)
    zip --password "$PASS" proxy.zip proxy.txt
    URL=$(curl -s --upload-file proxy.zip "https://transfer.sh/proxy.zip")

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
    awk -F "/" '{print "ifconfig ens33 inet6 add " $5 "/48"}' "${WORKDATA}"
}

echo "Installing apps"
yum -y install gcc net-tools bsdtar zip >/dev/null || exit

install_3proxy || exit

echo "Working folder = /home/proxy-installer"
WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"
mkdir "$WORKDIR" && cd "$_" || exit

IP4=$(curl -4 -s icanhazip.com)
IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')

echo "Internal IP = ${IP4}. External sub for IPv6 = ${IP6}"

read -p "How many proxies do you want to create? Example 500: " COUNT

FIRST_PORT=10000
LAST_PORT=$((FIRST_PORT + COUNT))

gen_data > "$WORKDIR"/data.txt
gen_iptables > "$WORKDIR"/boot_iptables.sh
gen_ifconfig > "$WORKDIR"/boot_ifconfig.sh
chmod +x "${WORKDIR}"/boot_*.sh /etc/rc.local

gen_3proxy > /usr/local/etc/3proxy/3proxy.cfg || exit

cat >> /etc/rc.local <<EOF
bash "${WORKDIR}"/boot_iptables.sh
bash "${WORKDIR}"/boot_ifconfig.sh
ulimit -n 10048
service 3proxy start
EOF

bash /etc/rc.local || exit

gen_proxy_file_for_user

upload_proxy