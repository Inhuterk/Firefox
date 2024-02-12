#!/bin/bash

# Function to generate random password
random() {
    tr </dev/urandom -dc A-Za-z0-9 | head -c5; echo
}

# Function to generate IPv6 address segments
ip64() {
    echo $(printf "%x%x" $((RANDOM%16)) $((RANDOM%16)))
}

# Function to generate a full IPv6 address with subnet
gen64() {
    echo "2001:db8:1:$(ip64):$(ip64):$(ip64)"
}

# Function to install 3proxy
install_3proxy() {
    echo "Installing 3proxy..."
    URL="https://raw.githubusercontent.com/quayvlog/quayvlog/main/3proxy-3proxy-0.8.6.tar.gz"
    wget -qO- $URL | tar xzf -
    cd 3proxy-3proxy-0.8.6
    make -f Makefile.Linux
    sudo make -f Makefile.Linux install
    cd ..
}

# Function to generate 3proxy configuration
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

users $(awk -F "/" '{print $1 ":CL:" $2}' ${WORKDATA})

$(awk -F "/" '{print "auth strong\n" \
"allow " $1 "\n" \
"proxy -6 -n -a -p" $4 " -i" $3 " -e"$5"\n" \
"flush\n"}' ${WORKDATA})
EOF
}

# Function to generate user proxy file
gen_proxy_file_for_user() {
    cat >proxy.txt <<EOF
$(awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2 }' ${WORKDATA})
EOF
}

# Function to upload proxy data
upload_proxy() {
    local PASS=$(random)
    zip --password $PASS proxy.zip proxy.txt
    URL=$(curl -s --upload-file proxy.zip https://transfer.sh/proxy.zip)

    echo "Proxy is ready! Format IP:PORT:LOGIN:PASS"
    echo "Download zip archive from: ${URL}"
    echo "Password: ${PASS}"
}

# Function to generate proxy data
gen_data() {
    seq $FIRST_PORT $LAST_PORT | while read port; do
        echo "usr$(random)/pass$(random)/$IP4/$port/$(gen64 $IP6)"
    done
}

# Function to generate iptables rules
gen_iptables() {
    cat <<EOF
$(awk -F "/" '{print "iptables -I INPUT -p tcp --dport " $4 "  -m state --state NEW -j ACCEPT"}' ${WORKDATA}) 
EOF
}

# Function to generate ifconfig commands (if needed for IPv6 assignment)
gen_ifconfig() {
    # Check if user needs IPv6 assignment and modify accordingly
    if [[ "$USE_IPV6" == "true" ]]; then
        cat <<EOF
$(awk -F "/" '{print "ifconfig eth0 inet6 add " $5 "/64"}' ${WORKDATA})
EOF
    fi
}

# Install necessary packages
sudo yum -y install gcc openssl-devel net-tools bsdtar zip >/dev/null

# Install and configure 3proxy
install_3proxy

# Set working folder
WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"
sudo mkdir -p $WORKDIR && cd $WORKDIR

# Get external IP addresses
IP4=$(curl -4 -s icanhazip.com)
IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')

# Prompt user for proxy count
echo "Internal IP = ${IP4}. External subnet for IPv6 = ${IP6}"
echo "How many proxies do you want to create? Example: 500"
read COUNT

FIRST_PORT=10000
LAST_PORT=$(($FIRST_PORT + $COUNT))

# Generate data, iptables rules, and ifconfig commands
gen_data >$WORKDATA
gen_iptables >$WORKDIR/boot_iptables.sh
gen_ifconfig >$WORKDIR/boot_ifconfig.sh
chmod +x ${WORKDIR}/boot_*.sh /etc/rc.local

# Generate 3proxy configuration
gen_3proxy >/usr/local/etc/3proxy/3proxy.cfg

# Add commands to rc.local
cat >>/etc/rc.local <<EOF
bash ${WORKDIR}/boot_iptables.sh
bash ${WORKDIR}/boot_ifconfig.sh
ulimit -n 10048
systemctl start 3proxy
EOF

# Execute rc.local
sudo bash /etc/rc.local

# Generate user proxy file and upload proxy data
gen_proxy_file_for_user
upload_proxy
