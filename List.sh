#!/bin/bash
random() {
	tr </dev/urandom -dc A-Za-z0-9 | head -c5
	echo
}

array=("1" "2" "3" "4" "5" "6" "7" "8" "9" "0" "a" "b" "c" "d" "e" "f")
gen64() {
	ip64() {
		echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
	}
	echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
}

install_3proxy() {
    echo "installing 3proxy"
    URL="https://raw.githubusercontent.com/quayvlog/quayvlog/main/3proxy-3proxy-0.8.6.tar.gz"
    wget -qO- $URL | tar -xzvf -
    cd 3proxy-3proxy-0.8.6
    make -f Makefile.Linux
    sudo mkdir -p /usr/local/etc/3proxy/{bin,logs,stat}
    sudo cp src/3proxy /usr/local/etc/3proxy/bin/
    sudo cp ./scripts/rc.d/proxy.sh /etc/init.d/3proxy
    sudo chmod +x /etc/init.d/3proxy
    sudo update-rc.d 3proxy defaults
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

echo "installing apps"
sudo apt-get update
sudo apt-get install -y gcc net-tools bsdtar zip

install_3proxy

echo "working folder = /home/proxy-installer"
WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"
mkdir $WORKDIR && cd $_

IP4=$(curl -4 -s icanhazip.com)
IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')

echo "Internal ip = ${IP4}. External sub for ip6 = ${IP6}"

echo "How many proxies do you want to create? Example: 500"
read COUNT

FIRST_PORT=10000
LAST_PORT=$(($FIRST_PORT + $COUNT))

# Placeholder for gen_data function
gen_data() {
    # Your implementation here
}

# Placeholder for gen_iptables function
gen_iptables() {
    # Your implementation here
}

# Placeholder for gen_ifconfig function
gen_ifconfig() {
    # Your implementation here
}

# Placeholder for gen_proxy_file_for_user function
gen_proxy_file_for_user() {
    # Your implementation here
}

# Placeholder for upload_proxy function
upload_proxy() {
    # Your implementation here
}

gen_data >$WORKDIR/data.txt
# gen_iptables >$WORKDIR/boot_iptables.sh
# gen_ifconfig >$WORKDIR/boot_ifconfig.sh
# chmod +x ${WORKDIR}/boot_*.sh /etc/rc.local

gen_3proxy >/usr/local/etc/3proxy/3proxy.cfg

# Placeholder for gen_proxy_file_for_user function
gen_proxy_file_for_user

# Placeholder for upload_proxy function
upload_proxy