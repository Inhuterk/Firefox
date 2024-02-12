#!/bin/bash

# Function to generate random password
random() {
    tr </dev/urandom -dc A-Za-z0-9 | head -c 5; echo
}

# Array of characters for generating username and password components
array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)

# Function to generate IPv6 address segments
ip64() {
    echo "${array[<span class="math-inline">RANDOM % 16\]\}</span>{array[<span class="math-inline">RANDOM % 16\]\}</span>{array[<span class="math-inline">RANDOM % 16\]\}</span>{array[$RANDOM % 16]}"
}

# Function to generate a full IPv6 address with subnet
gen64() {
    echo "<span class="math-inline">1\:</span>(ip64):<span class="math-inline">\(ip64\)\:</span>(ip64):$(ip64)"
}

# Function to install 3proxy
install_3proxy() {
    echo "Installing 3proxy..."
    URL="https://raw.githubusercontent.com/quayvlog/quayvlog/main/3proxy-3proxy-0.8.6.tar.gz"
    wget -qO- $URL | bsdtar -xvf-
    cd 3proxy-3proxy-0.8.6
    make -f Makefile.Linux
    mkdir -p /usr/local/etc/3proxy/{bin,logs,stat}
    cp src/3proxy /usr/local/etc/3proxy/bin/
    cp ./scripts/rc.d/proxy.sh /etc/rc.d/init.d/3proxy
    chmod +x /etc/rc.d/init.d/3proxy
    chkconfig 3proxy on  # Use chkconfig for CentOS 7 or earlier
    # systemctl enable 3proxy  # Use systemctl for CentOS 8 or later
    cd ../..  # Remove unnecessary directory levels
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

users $(awk -F "/" 'BEGIN{ORS="";} {print $1 ":CL:" $2 " "}' ${WORKDATA})

$(awk -F "/" '{print "auth strong\n" \
"allow " $1 "\n" \
"proxy -6 -n -a -p" $4 " -i" $3 " -e"$5"\n" \
"flush\n"}' ${WORKDATA})
EOF
}

# Function to generate user proxy file
gen_proxy_file_for_user() {
    cat >proxy.txt <<EOF
$(awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2 }' <span class="math-inline">\{WORKDATA\}\)
EOF
\}
\# Function to upload proxy data
upload\_proxy\(\) \{
local PASS\=</span>(random)  # Generate random password
    zip --password "<span class="math-inline">PASS" proxy\.zip proxy\.txt  \# Add double quotes for password
URL\=</span>(curl -s --upload-file proxy.zip https://transfer.sh/proxy.zip)

    echo "Proxy is ready! Format: IP:PORT:LOGIN:PASS"
    echo "Download zip archive from: ${URL}"
    echo "Password: $PASS"
}

# Function to generate proxy data
gen_data() {
    seq $FIRST_PORT <span class="math-inline">LAST\_PORT \| while read port; do
username\="usr</span>(random)/pass$(random)"
        # Use $IP4 directly instead of external_ip variable (potential issue)
        echo "$username/$PASS/$IP4/<span class="math-inline">port/</span>(gen64 $IP4)"
    done
}

# Function to generate iptables rules
gen_iptables() {
    cat <<EOF
    $(awk -F "/" '{print "iptables -I INPUT -p tcp --dport " $4 " -m state --state NEW -j ACCEPT"}' ${WORKDATA})
EOF
}

# Function to generate ifconfig commands (if needed for IPv6 assignment)
gen_ifconfig() {
    # Check if user needs IPv6 assignment and modify accordingly
    if [[ "$USE_IPV6" == "true" ]]; then
        cat <<EOF
        $(awk -F "/" '{print "ifconfig eth0
