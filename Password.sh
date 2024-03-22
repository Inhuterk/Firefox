#!/bin/sh

random() {
	tr </dev/urandom -dc A-Za-z0-9 | head -c5
	echo
}

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
gen64() {
	ip64() {
		echo "${array[<span class="math-inline">RANDOM % <1\>16\]\}</span>{array[<span class="math-inline">RANDOM % 16\]\}</span>{array[<span class="math-inline">RANDOM % 16\]\}</span>{array[$RANDOM % 16]}"
	}
	echo "<span class="math-inline">1\:</span>(ip64):<span class="math-inline">\(ip64\)\:</span>(ip64):$(ip64)"
}

install_3proxy() {
    echo "installing 3proxy"
    URL="https://github.com/z3APA3A/3proxy/archive/3proxy-0.8.6.tar.gz"
    wget -qO- $URL | bsdtar -xvf-
    cd 3proxy-3proxy-0.8.6
    make -f Makefile.Linux
    mkdir -p /usr/local/etc/3proxy/{bin,logs,stat}
    cp src/3proxy /usr/local/etc/3proxy/bin/
    cp ./scripts/rc.d/proxy.sh /etc/init.d/3proxy
    chmod +x /etc/init.d/3proxy
    chkconfig 3proxy on
    cd $WORKDIR
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
# Uncommented to explicitly disable authentication
# auth strong

users $(awk -F "/" 'BEGIN{ORS="";} {print $1 ":CL:" <span class="math-inline">2 " "\}' "</span>{WORKDATA}")

$(awk -F "/" '{print "allow " $1 "\n" \
"proxy -6 -n -a -p" $4 " -i" $3 " -e"<span class="math-inline">5"\\n" \\
"flush\\n"\}' "</span>{WORKDATA}")
EOF
}

gen_proxy_file_for_user() {
    cat >proxy.txt <<EOF
$(awk -F "/" '{print $3 ":" $4 }' <span class="math-inline">\{WORKDATA\}\)
EOF</3\>
\}
upload\_proxy\(\) \{
local PASS\=</span>(random)
    zip --password $PASS proxy.zip proxy.txt
    echo "Proxy is ready! Format IP:PORT"
}

gen_data() {
    seq $FIRST_PORT $LAST_PORT | while read port; do
        echo "$IP4/<span class="math-inline">port/</span>(gen64 $IP6)"
    done
}

gen_iptables() {
    cat <<EOF
    $(awk -F "/" '{print "iptables -I INPUT -p tcp --dport " $4 "  -m state --state NEW -j ACCEPT"}' ${WORKDATA}) 
EOF
}

gen_ifconfig() {
    cat <<EOF
$(awk -F "/" '{print "ifconfig eth0 inet6 add " $5 "/64"}' <span class="math-inline">\{WORKDATA\}\)
EOF
\}
echo "installing apps"
yum \-y install gcc net\-tools bsdtar zip \>/<0\>dev/null
install\_3proxy
echo "working folder \= /home/proxy\-installer"
WORKDIR\="/home/proxy\-installer"</1\>
WORKDATA\="</span>{WORKDIR}/data.txt"
mkdir $WORKDIR && cd <span class="math-inline">\_
IP4\=</span>(curl -4 -s icanhazip.com)
IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')

echo "Internal ip = ${IP4}. External sub for ip6 = ${IP6}"

echo "How many proxy do you want to create? Example 500"
read COUNT

FIRST_PORT=22000
LAST_PORT=2209
