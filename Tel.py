import subprocess
import random
import string
import os

def generate_random_string(length):
    return ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(length))

def generate_ip64():
    array = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'a', 'b', 'c', 'd', 'e', 'f']
    return ':'.join([random.choice(array) + random.choice(array) + random.choice(array) + random.choice(array) for _ in range(4)])

def install_3proxy():
    print("Installing 3proxy")
    url = "https://raw.githubusercontent.com/ngochoaitn/multi_proxy_ipv6/main/3proxy-3proxy-0.8.6.tar.gz"
    subprocess.run(["wget", "-qO-", url], check=True)
    subprocess.run(["bsdtar", "-xvf-", "-C", "/home/proxy-installer/"], check=True)
    os.chdir("/home/proxy-installer/3proxy-3proxy-0.8.6")
    subprocess.run(["make", "-f", "Makefile.Linux"], check=True)
    subprocess.run(["mkdir", "-p", "/usr/local/etc/3proxy/{bin,logs,stat}"], check=True)
    subprocess.run(["cp", "src/3proxy", "/usr/local/etc/3proxy/bin/"], check=True)
    subprocess.run(["cp", "./scripts/rc.d/proxy.sh", "/etc/init.d/3proxy"], check=True)
    subprocess.run(["chmod", "+x", "/etc/init.d/3proxy"], check=True)
    subprocess.run(["chkconfig", "3proxy", "on"], check=True)
    os.chdir("/home/proxy-installer/")

def generate_3proxy_config(data):
    config = f"""daemon
maxconn 1000
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
flush
auth strong

users {"".join([f"{line.split('/')[0]}:CL:{line.split('/')[1]} " for line in data])}

{"".join([f"auth strong\nallow {line.split('/')[0]}\nproxy -6 -n -a -p{line.split('/')[3]} -i{line.split('/')[2]} -e{line.split('/')[4]}\nflush\n" for line in data])}
"""
    return config

def generate_proxy_file_for_user(data):
    with open("/home/proxy-installer/proxy.txt", "w") as file:
        file.write("\n".join([f"{line.split('/')[2]}:{line.split('/')[3]}:{line.split('/')[0]}:{line.split('/')[1]}" for line in data]))

def upload_proxy():
    password = generate_random_string(10)
    subprocess.run(["zip", "--password", password, "proxy.zip", "proxy.txt"], check=True)
    result = subprocess.run(["curl", "-s", "--upload-file", "proxy.zip", "https://transfer.sh/proxy.zip"], capture_output=True, text=True)
    url = result.stdout.strip()
    
    print("Proxy is ready! Format IP:PORT:LOGIN:PASS")
    print(f"Download zip archive from: {url}")
    print(f"Password: {password}")

def generate_data(count, first_port):
    ip4 = subprocess.run(["curl", "-4", "-s", "icanhazip.com"], capture_output=True, text=True).stdout.strip()
    ip6 = ":".join(subprocess.run(["curl", "-6", "-s", "icanhazip.com"], capture_output=True, text=True).stdout.strip().split(':')[:4])

    data = [f"usr{generate_random_string(5)}/pass{generate_random_string(5)}/{ip4}/{str(port)}/{generate_ip64()}" for port in range(first_port, first_port + count)]
    return data

def generate_iptables(data):
    return "\n".join([f"iptables -I INPUT -p tcp --dport {line.split('/')[3]} -m state --state NEW -j ACCEPT" for line in data])

def generate_ifconfig(data):
    return "\n".join([f"ifconfig ens33 inet6 add {line.split('/')[4]}/48" for line in data])

# Main script
print("Installing apps")
subprocess.run(["yum", "-y", "install", "gcc", "net-tools", "bsdtar", "zip"], stdout=subprocess.DEVNULL)

install_3proxy()

print("Working folder = /home/proxy-installer")
WORKDIR = "/home/proxy-installer"
WORKDATA = f"{WORKDIR}/data.txt"
os.makedirs(WORKDIR, exist_ok=True)
os.chdir(WORKDIR)

IP4 = subprocess.run(["curl", "-4", "-s", "icanhazip.com"], capture_output=True, text=True).stdout.strip()
IP6 = ":".join(subprocess.run(["curl", "-6", "-s", "icanhazip.com"], capture_output=True, text=True).stdout.strip().split(':')[:4])

print(f"Internal ip = {IP4}. External sub for ip6 = {IP6}")

COUNT = int(input("How many proxies do you want to create? Example 500\n"))
FIRST_PORT = 10000
LAST_PORT = FIRST_PORT + COUNT

data = generate_data(COUNT, FIRST_PORT)
with open(WORKDATA, "w") as file:
    file.write("\n".join(data))

with open("/etc/rc.local", "a") as file:
    file.write(f"bash {WORKDIR}/boot_iptables.sh\nbash {WORKDIR}/boot_ifconfig.sh\nulimit -n 10048\nservice 3proxy start\n")

generate_3proxy_config(data)
generate_proxy_file_for_user(data)
upload_proxy()
