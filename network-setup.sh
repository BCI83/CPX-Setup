#!/bin/bash
# Make sure this is run as root
user=$(whoami)
if [ "$user" = "root" ]
then
    echo "Logged in as root... proceeding..."
else
    echo "Please log in as the root user and try again..."
    exit 0
fi

# Setting up functions to:
#
# validate yes / no answers
yn(){
while :; do
  read -rsp $'y or n ? : ' -n1 q
  if [ "$q" = "y" ] || [ "$q" = "Y" ]; then
  ynresult="Y"
  break
  elif [ "$q" = "n" ] || [ "$q" = "N" ]; then
  ynresult="N"
  break
  else
    echo "not a valid response, please indicate either yes or no"
  fi
done
}

# check IP addresses are valid
vip(){
    while :; do
        read -p "Enter the IP: " ipc
        if [[ "$ipc" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]
        then
            echo ""
            result=$ipc
            break
        else
            echo "That was not a valid IP, please try again"
        fi
    done
}
# check hostnames are valid
vhn(){
    while :; do
        read -p "Enter the hostname: " hnc
        if [[ "$hnc" =~ ^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])(\.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9]))*$ ]]
        then
            result=$hnc
            break
        else
            echo "not a valid hostname, please try again"
            echo "(exclude http(s):// prefixes)"
        fi
    done
}

curl_test(){
    echo "#########################################################"
    echo ""
    final_code=""
    status_code=""
    subdomain=$(echo "$1" | cut -d. -f1 | cut -d/ -f3)
    echo "curl --write-out %{http_code} --silent --output /dev/null" $1
    status_code=$(curl --write-out %{http_code} --silent --output /dev/null $1)
    echo "HTTP response code "$status_code
    final_code=$status_code
    echo ""
    echo "curl -L --write-out %{http_code} --silent --output /dev/null" $1
    status_code=$(curl -L --write-out %{http_code} --silent --output /dev/null $1)
    echo "HTTP response code "$status_code
    final_code=$final_code"-"$status_code
    echo ""
    echo "curl -L -k --write-out %{http_code} --silent --output /dev/null" $1
    status_code=$(curl -L -k --write-out %{http_code} --silent --output /dev/null $1)
    echo "HTTP response code "$status_code
    final_code=$final_code"-"$status_code
    echo ""
}

wget_test(){
        echo "#########################################################"
        echo ""
        status_code=""
        chars=""
        reply=""
        subdomain=$(echo "$1" | cut -d. -f1 | cut -d/ -f3)
        reply=$(wget -T 3 --no-check-certificate --delete-after ${1} 2>&1)
        chars=$(echo "$reply" |grep "connected")
        if [ `expr length "$chars"` != "0" ]; then
            echo $subdomain" OK"
            status_code="OK"
        else
            echo $subdomain" Failed"
            status_code="Failed"
        fi
        echo ""
}


###########################################################################
###############setting up file location variables

#test or live
#valid options are "live" and "test"
env="live"
#env="test"

#
##### ip/gw
if [ "$env" = "test" ]; then
    ipath="."
    elif [ "$env" = "live" ]; then
    ipath="/etc/network"
fi

##### dns
if [ "$env" = "test" ]; then
    dpath="."
    elif [ "$env" = "live" ]; then
    dpath="/etc"
fi

##### hostname
if [ "$env" = "test" ]; then
    hnpath="."
    elif [ "$env" = "live" ]; then
    hnpath="/etc"
fi

##### hosts
if [ "$env" = "test" ]; then
    hpath="."
    elif [ "$env" = "live" ]; then
    hpath="/etc"
fi

##### ntp
if [ "$env" = "test" ]; then
    npath="."
    elif [ "$env" = "live" ]; then
    npath="/etc/chrony"
fi

##### proxy
if [ "$env" = "test" ]; then
    ppath="."
    elif [ "$env" = "live" ]; then
    ppath="/etc/profile.d"
fi
#ip/gw
#if [ "$env" = "test" ] then;
#
#else
#
#fi
###########################################################################
# starting script
clear
ASCII=" ____                        _ 
/ ___| _   _ _ __ ___  _ __ | |__   ___  _ __  _   _ 
\___ \| | | | '_ ' _ \| '_ \| '_ \ / _ \| '_ \| | | | 
 ___) | |_| | | | | | | |_) | | | | (_) | | | | |_| | 
|____/ \__, |_| |_| |_| .__/|_| |_|\___/|_| |_|\__, | 
  ____ |___/_  __    _|_|       _              |___/ 
 / ___|  _ \ \/ /   / ___|  ___| |_ _   _ _ __ 
| |   | |_) \  /    \___ \ / _ \ __| | | | '_ \ 
| |___|  __//  \     ___) |  __/ |_| |_| | |_) | 
 \____|_|  /_/\_\   |____/ \___|\__|\__,_| .__/ 
                                         |_| 
"
echo "$ASCII"
echo "You will need the following information to hand before proceeding:"
echo ""
echo "1 - The IP address you want to assign to this machine"
echo ""
echo "2 - The subnet mask for the above IP (in slash notation eg: /24)"
echo ""
echo "3 - The default gateway IP for the above network"
echo ""
echo "4 - At least one DNS server IP (can be internal and/or public)"
echo ""
echo "5 - The hostname you wish to set for this machine"
echo "    (otherwise the hostname will remain 'debian')"
echo ""
echo "6 - NTP server IP/FQDN details if you have internal/preferred servers"
echo "    (otherwise the default public servers will be used)"
echo ""
echo "7 - Proxy details if required for internet access (IP/FQDN:Port)"
echo ""
echo "8 - Your welcome email"
echo ""
echo "---------------------------------------------------------------------"
echo ""
echo "Do you have all of the required information above?"
echo ""
yn
q1=$ynresult
if [ "$q1" = "Y" ]; then
    clear
elif [ "$q1" = "N" ]; then
    echo ""
    echo "Aborting as 'No' was indicated"
    echo ""
    echo "Please restart this server once you have all of the required information"
    echo ""
    exit 0
fi
clear
echo "$ASCII"
echo ""
echo "Please provide the IP address you want this machine to use"
echo "( subnetmask information will be collected later )"
echo ""
vip
ip=$result
clear
echo "$ASCII"
echo ""
echo "Please provide the subnet mask for the "$ip " address"
echo "( use slash notation, like /24 or /27 see below table )

255.255.255.252 = /30	255.255.255.248	= /29
255.255.255.240	= /28	255.255.255.224	= /27
255.255.255.192	= /26	255.255.255.128	= /25
255.255.255.0	= /24	255.255.254.0   = /23
255.255.252.0	= /22	255.255.248.0   = /21
"
echo ""
while :; do
    read -p "Enter the subnet mask: /" sn
    echo $sn
    if [ ${#sn} = 1 ] || [ ${#sn} = 2 ]; then
        if (($sn >= 20 && $sn <= 30)); then
            echo ""
            break
        else
            echo "not a valid subnet mask, please try again"
        fi
        echo "not a valid subnet mask, please try again"
    elif [ ${#sn} = 3 ]; then # this is to account for users entering the / even though it's already pre-entered at the input prompt
        if [[ $sn == /* ]]; then
            sn="${sn:1}"
            if (($sn >= 20 && $sn <= 30)); then
                echo ""
                break
            else
                echo "not a valid subnet mask, please try again"
            fi
        fi
    fi
done
clear
echo "$ASCII"
echo ""
echo "Please provide the default Gateway IP for "$ip
echo ""
vip
gw=$result
clear
echo "$ASCII"
echo ""
echo "Please provide the first DNS server IP you want this machine to use"
echo "It can be internal/private and/or external/public"
echo ""
vip
clear
echo "$ASCII"
dns1=$result
echo ""
echo "DNS 1 set to: "$dns1
echo ""
echo "do you want to add a second DNS server?"
echo ""
yn
dns2q=$ynresult
if [ "$dns2q" = "Y" ]; then
    clear
    echo "$ASCII"
    echo ""
    echo "Please provide the second DNS server IP you want this machine to use"
    echo "It can be internal/private and/or external/public"
    echo ""
    vip
    dns2=$result
    clear
    echo "$ASCII"   
    echo ""
    echo "DNS 2 set to: "$dns2
    echo ""
    echo "do you want to add a third DNS server?"
    echo ""
fi
if [ "$dns2q" = "Y" ]
then
    yn
    dns3q=$ynresult
    if [ "$dns3q" = "Y" ]; then
        clear
        echo "$ASCII"
        echo ""
        echo "Please provide the third DNS server IP you want this machine to use"
        echo "It can be internal/private and/or external/public"
        echo ""
        vip
        dns3=$result
        echo ""
        echo "DNS 3 set to: "$dns3
    fi
fi
clear
echo "$ASCII"
echo ""
echo "Do you want to change the hostname of this machine?"
echo "it is currently set to: debian"
echo ""
yn
q2=$ynresult
if [ "$q2" = "Y" ]; then
    echo ""
    echo "Please enter the new hostname you want this machine to have"
    echo ""
    echo "(hostnames can only consist of a to z, A to Z, 0 to 9, decimal (.), and hyphen (-)"
    echo ""
    vhn
    hostname=$result
    echo ""
elif [ "$q2" = "N" ]; then
    hostname=$(cat /etc/hostname)
else
    echo "not a valid response, please indicate either yes or no"
fi
clear
echo "$ASCII"
echo ""
echo "This machine is currently configured to use a pool of NTP servers from ntp.org"
echo "Do you want to provide your own NTP server/pool details?"
echo ""
yn
q3=$ynresult
clear
echo "$ASCII"
if [ "$q3" = "Y" ]; then
    echo ""
    echo "What information will you be providing?"
    echo ""
    echo "1 - An NTP pool Virtul-IP address"
    echo "2 - A single NTP server IP address"
    echo "3 - An NTP pool hostname/FQDN"
    echo "4 - A single NTP server hostname/FQDN"
    echo ""
    while :; do
        read -rsp "Enter your selection: " -n1 ntpq1
        if (($ntpq1 >= 1 && $ntpq1 <= 4)); then
            echo ""
            break
        else
            echo "Not a valid selection, please try again"
        fi
    done
    case $ntpq1 in
        1)
            echo "Please enter the NTP pool Virtual-IP address"
            vip
            ntpv=$result
        ;;
        2)
            echo "Please enter the NTP server IP address"
            vip
            ntpv=$result
        ;;
        3)
            echo "Please enter the NTP pool hostname/FQDN"
            vhn
            ntpv=$result
        ;;
        4)
            echo "Please enter the NTP server hostname/FQDN"
            vhn
            ntpv=$result
        ;;
    esac
fi
clear
echo "$ASCII"
echo "Do you intend to use a HTTP(S) proxy with this server?"
echo ""
yn
q4a=$ynresult

if [ "$q4a" = "Y" ]; then
    clear
    while :; do    
        echo "$ASCII"
        echo "Select the option which best describes your proxy"
        echo "" 
        echo "1 - A regular proxy (has a http:// prefix) and DOES NOT decrypt external certificates"
        echo "  (Commonly referred to as a transparent proxy)"
        echo "2 - A regular proxy (has a http:// prefix) and DOES decrypt external certificates and then re-encrypt the traffic with its own certificate"
        echo "  (Commonly referred to as a non-transparent proxy)"
        echo "3 - A secure proxy (has a https:// prefix) and DOES NOT decrypt external certificates and then re-encrypt the traffic with its own certificate"
        echo "  (Commonly referred to as a secure transparent proxy, a TLS connection is always established between the client and the proxy server)"
        echo "4 - A secure proxy (has a https:// prefix) and DOES decrypt external certificates and then re-encrypt the traffic with its own certificate"
        echo "  (Commonly referred to as a secure non-transparent proxy, a TLS connection is always established between the client and the proxy server)"
        echo ""
        read -rsp "Enter your selection: " -n1 proxyq1
        if (($proxyq1 >= 1 && $proxyq1 <= 4)); then
            echo ""
            break
        else
            clear
            echo "Not a valid selection, please try again"
        fi
    done
    clear
    echo "$ASCII"
    case $proxyq1 in
        1)
            echo "This should work, details will be collected in the next step"
            proxy_details="Y"
            proxy_type="1 - A regular proxy (has a http:// prefix) and DOES NOT decrypt external certificates"
        ;;
        2)
            echo "This should work, however if the proxy certificate is self-signed (not publicly trusted) some functionality may not work"
            echo "specifically, the ability to remotely restart and upgrade the CPX, but the main funcion of collecting and sending monitoring data should still work"
            echo "details will be collected in the next step"
            proxy_details="Y"
            proxy_type="2 - A regular proxy (has a http:// prefix) and DOES decrypt external certificates and then re-encrypt the traffic with its own certificate"
        ;;
        3)
            echo "Not working according to my testing"
            #need to test with the proxy Dan said we had
            proxy_type="3 - A secure proxy (has a https:// prefix) and DOES NOT decrypt external certificates and then re-encrypt the traffic with its own certificate"
        ;;
        4)
            echo "Not working according to my testing"
            #need to test with the proxy Dan said we had
            proxy_type="4 - A secure proxy (has a https:// prefix) and DOES decrypt external certificates and then re-encrypt the traffic with its own certificate"
        ;;
    esac
    sed -i "s/proxy_type:.*/proxy_type: $proxy_type/" /symphony/setup-config
    echo ""
    read -rsp $'Press any key to continue...' -n1 key
    clear
fi

if [ "$proxy_details" = "Y" ]; then
    echo ""
    echo "What proxy information will you be providing?"
    echo ""
    echo "1 - An IP address and port"
    echo "2 - A hostname/FQDN and port"
    echo ""
    while :; do
        read -rsp "Enter your selection: " -n1 proxyq1
        if [[ "$proxyq1" = "1" || "$proxyq1" = "2" ]]; then
            echo ""
            break
        else
            echo "Not a valid selection, please try again"
        fi
    done
    clear
    echo "$ASCII"
    echo ""
    while :; do
        read -p "First, enter the port number: " pn
        if (($pn >= 0 && $pn <= 65535)); then
            pa=1
            sed -i "s/proxy_port:.*/proxy_port: $pn/" /symphony/setup-config
            break
        else
            echo "Not a valid port"
            echo "ports are an integer between 0-65535"
            echo ""
        fi
    done
    case $proxyq1 in
        1)
            echo "And now enter the proxy IP address"
            echo ""
            vip
            pip=$result
            proxy=$pip":"$pn
            sed -i "s/proxy_ip:.*/proxy_ip: $pip/" /symphony/setup-config
        ;;
        2)
            echo "And now enter the proxy hostname/FQDN"
            echo ""
            vhn
            phn=$result
            proxy=$phn":"$pn
            sed -i "s/proxy_fqdn:.*/proxy_fqdn: $phn/" /symphony/setup-config
        ;;
    esac
fi
##################################################################################
# confirm with user that all details are correct
clear
echo "$ASCII"
echo ""
echo ""
echo "IP and subnetmask for this machine:                   "$ip"/"$sn
echo "The default gateway for this machine:                 "$gw
echo "The DNS server(s) this machine will use:       DNS 1: "$dns1
if [ "$dns2q" = "Y" ]; then
    echo "                                               DNS 2: "$dns2
fi
if [ "$dns3q" = "Y" ]; then
    echo "                                               DNS 3: "$dns3
fi
echo "The hostname for this machine will be:                "$hostname
if [ "$ntpq1" = "1" ] || [ "$ntpq1" = "3" ]; then
    ntpstring="pool "$ntpv" iburst"
    echo "You have chosen to use the NTP pool:                  "$ntpv
    elif [ "$ntpq1" = "2" ] || [ "$ntpq1" = "4" ]; then
    ntpstring="server "$ntpv" iburst"
    echo "You have chosen this single NTP server:               "$ntpv
else
    echo "This machine will use the default NPT pool:           2.debian.pool.ntp.org"
fi
if [ "$proxy_details" = "Y" ]; then
    echo "This proxy to use for communication is:               "$proxy
else
    echo "No proxy settings suppied/required                    N/A"
fi
echo ""
echo ""
echo "Are all of the details above correct?"
echo "( N will restart this setup script )"
echo ""
yn
conf=$ynresult
echo ""
if [ "$conf" = "Y" ]; then
    echo ""
elif [ "$conf" = "N" ]; then
    sudo su -
fi
clear
# Information gathering pahse complete
##################################################################################
echo "Applying the settings now..."
echo ""
##################################################################################
#Make a backup of the /etc/network/interfaces file
if [ ! -f $ipath/interfaces.orig ]; then
    cp $ipath/interfaces $ipath/interfaces.orig
    echo ".../interfaces file backed up successfully"
else
    echo ".../interfaces backup file already exists"
fi
inputfile="/etc/network/interfaces"
intadapter="ens192"
#intadapter="enp0s3"
dadapter=$(ip -br a | grep en | awk '$1 !~ "lo|vir|wl" { print $1}')
if [ "$dadapter" != "$intadapter" ]; then
    sed -i "s/$intadapter/$dadapter/g" $ipath/interfaces
fi
oips="  address "
ogws="  gateway "
sed -i "s/$oips.*/$oips$ip\/$sn/" $ipath/interfaces
sed -i "s/$ogws.*/$ogws$gw/" $ipath/interfaces
sed -i "s/ip_address:.*/ip_address: $ip/" /symphony/setup-config
sed -i "s/default_gateway:.*/default_gateway: $gw/" /symphony/setup-config
sed -i "s/subnet_mask:.*/subnet_mask: \/$sn/" /symphony/setup-config
echo "IP settings applied"
echo ""
##################################################################################
#Make a backup of the /etc/resolv.conf file if one doesn't exist already
if [ ! -f $dpath/resolv.conf.orig ]; then
    cp $dpath/resolv.conf $dpath/resolv.conf.orig
    echo ".../resolv.conf file backed up successfully"
else
    echo ".../resolv.conf file backup already exists"
fi
#clear the current contents of resolv.conf
> $dpath/resolv.conf
#Add the new name server(s)
echo "nameserver "$dns1 >> $dpath/resolv.conf
sed -i "s/dns1:.*/dns1: $dns1/" /symphony/setup-config
if [ "$dns2q" = "Y" ]; then
    echo "nameserver "$dns2 >> $dpath/resolv.conf
    sed -i "s/dns2:.*/dns2: $dns2/" /symphony/setup-config
fi
if [ "$dns3q" = "Y" ]; then
    echo "nameserver "$dns3 >> $dpath/resolv.conf
    sed -i "s/dns3:.*/dns3: $dns3/" /symphony/setup-config
fi
echo "DNS settings applied"
echo ""
##################################################################################
#Setting the hostname (only if they have requested a change)
if [ "$q2" = "Y" ]; then
    if [ ! -f $hnpath/hostname.orig ]
    then
        cp $hnpath/hostname $hnpath/hostname.orig
        echo ".../hostname file backed up successfully"
    else
        echo ".../hostname file backup already exists"
    fi
    hostnamectl set-hostname $hostname
    sed -i "s/hostname:.*/hostname: $hostname/" /symphony/setup-config
    echo "Hostname settings applied"
else
    echo "The hostname is remaining set to '"$hostname"'"
fi
echo ""
##################################################################################
#Make a backup and edit the /etc/hosts file
if [ ! -f $hpath/hosts.orig ]; then
    cp $hpath/hosts $hpath/hosts.orig
    echo ".../hosts file backed up successfully"
else
    echo ".../hosts file backup already exists"
fi
sed    -i '1 a '"${ip}"'         '"${hostname}"'' $hpath/hosts
echo "Hosts settings applied"
echo ""
##################################################################################
#Setting NTP server/pool (only if they have requested a change)
if [ "$q3" = "Y" ]
then
    echo "Applying NTP configuration"
    #make a backup of the /etc/chrony/chrony.conf file if  one doesn't already exist
    if [ ! -f $npath/chrony.conf.orig ];     then
        cp $npath/chrony.conf $npath/chrony.conf.orig
        echo ".../chrony.conf file backed up successfully"
    else
        echo ".../chrony.conf backup already exists"
    fi
    oldntp="pool 2.debian.pool.ntp.org iburst"
    sed -i "s/$oldntp/$ntpstring/" /etc/chrony/chrony.conf
    if [ "$ntpstring" == *"pool"* ]; then
        sed -i "s/ntp_pool:.*/ntp_pool: $ntpstring/" /symphony/setup-config
    else
        sed -i "s/ntp_server:.*/ntp_server: $ntpstring/" /symphony/setup-config
    fi

    echo "NTP settings applied"
else
    echo "NTP settings unchanged"
fi
echo ""
##################################################################################
#Setting the proxy settings (only if the user indicated a proxy is to be used)
if [ "$proxy_details" = "Y" ]; then
    #write the /etc/profile.d/proxy.sh file which is triggered at login
    if [ ! -f /etc/profile.d/proxy.sh ]; then
        touch /etc/profile.d/proxy.sh
        echo "/etc/profile.d/proxy.sh file successfully created"
        echo "Backed up /etc/profile.d/proxy.sh successfully"
    else
        echo "pre-existing /etc/profile.d/proxy.sh file found"
        if [ ! -f /etc/profile.d/proxy.sh.orig ]
        then
            cp /etc/profile.d/proxy.sh /etc/profile.d/proxy.sh.orig
            echo "Backed up /etc/profile.d/proxy.sh successfully"
        fi
        > /etc/profile.d/proxy.sh
    fi
    fn="/etc/profile.d/proxy.sh"
    > $fn
    echo "#!/bin/bash"  >> $fn
    echo "# http/https/ftp/no_proxy" >> $fn
    echo "export http_proxy=\"http://"$proxy"/\"" >> $fn
    echo "export https_proxy=\"http://"$proxy"/\"" >> $fn
    echo "export ftp_proxy=\"http://"$proxy"/\"" >> $fn
    echo "export no_proxy=\"127.0.0.1,localhost\"" >> $fn
    echo "# For curl" >> $fn
    echo "export HTTP_PROXY=\"http://"$proxy"/\"" >> $fn
    echo "export HTTPS_PROXY=\"http://"$proxy"/\"" >> $fn
    echo "export FTP_PROXY=\"http://"$proxy"/\"" >> $fn
    echo "export NO_PROXY=\"127.0.0.1,localhost\"" >> $fn

    chmod +x /etc/profile.d/proxy.sh
    # Create a service so that settings are applied at boot and not just login
    if [ ! -f /etc/systemd/system/proxy.service ]; then
        touch /etc/systemd/system/proxy.service
    fi
    svc="/etc/systemd/system/proxy.service"
    > $svc
    echo "[Unit]
Description=Script to apply proxy server settings

[Service]
ExecStart=/usr/bin/sh /etc/profile.d/proxy.sh
Restart=on-failure
TimeoutSec=5s

[Install]
WantedBy=multi-user.target
" >> $svc
    systemctl enable proxy
    systemctl start proxy
    echo "/etc/profile.d/proxy.sh file populated successfully"
    echo "Proxy service created and started successfully"
    echo "Proxy settings configured"
else
    echo "No Proxy settings provided"
fi
echo ""
##################################################################################
echo "---------------------------------------------------------------------------"
echo ""

echo "Restarting networking services"
systemctl restart networking.service
echo ""
echo "Done applying the changes"
echo ""
echo "The initial phase is now completed"
echo ""
echo "---------------------------------------------------------------------------"
echo ""
echo "Testing network connectivity by pinging the default gateway"
### Ping the gateway to confirm local network connectivity
ping_gw=$(ping -c 1 "$gw" > /dev/null)
if [ $? -eq 0 ]; then
    echo "Default Gateway response OK"
    ip_check1="OK"
else
    ip_check1="FAIL"
    echo "Default Gateway failed to respond"
fi
if [ "$ip_check1" = "OK" ]; then
    ### Ping Google DNS IP to confirm internet connectivity
    ping_dns_ip=$(ping -c 1 "8.8.8.8" > /dev/null)
    if [ $? -eq 0 ]; then
        ip_check2="OK"
        echo "Google DNS IP response OK"
    else
        ip_check2="FAIL"
        echo "Google DNS IP failed to respond"
    fi
    ### Ping Google Domain to confirm DNS functionality
    ping_dns_d=$(ping -c 1 "google.com" > /dev/null)
    if [ $? -eq 0 ]; then
        ip_check3="OK"
        echo "google.com resolution to IP OK"
    else
        ip_check3="FAIL"
        echo "google.com resolution to IP failed"
    fi
elif [ "$ip_check1" != "OK" ]; then
    echo ""
    echo "LAN connectivity test failed"
    echo ""
    read -rsp $'Press any key to run the setup script again...' -n1 key
    # clear the network values from the setup-config file
    sed -i "s/ip_address:.*/ip_address: /" /symphony/setup-config
    sed -i "s/default_gateway:.*/default_gateway: /" /symphony/setup-config
    sed -i "s/subnet_mask:.*/subnet_mask: /" /symphony/setup-config
    sed -i "s/dns1:.*/dns1: /" /symphony/setup-config
    sed -i "s/dns2:.*/dns2: /" /symphony/setup-config
    sed -i "s/dns3:.*/dns3: /" /symphony/setup-config
    sed -i "s/ntp_pool:.*/ntp_pool: /" /symphony/setup-config
    # trigger the login script again
    sudo su -
fi
sed -i "s/gw_ping:.*/gw_ping: $ip_check1/" /symphony/setup-config
sed -i "s/ip_8.8.8.8:.*/ip_8.8.8.8: $ip_check2/" /symphony/setup-config
sed -i "s/ip_resolve:.*/ip_resolve: $ip_check3/" /symphony/setup-config

# Test WGETs to the Symphony URLs
portal="https://portal.vnocsymphony.com"
portal5="https://portal5.avisplsymphony.com/symphony-portal"
cloud="https://cloud.vnocsymphony.com"
cloud5="https://cloud5.avisplsymphony.com/symphony-cloud-api"
registry="https://registry.vnocsymphony.com"

# Test wgets
wget_test $portal
portal_wget=$status_code
wget_test $portal5
portal5_wget=$status_code
wget_test $cloud
cloud_wget=$status_code
wget_test $cloud5
cloud5_wget=$status_code
wget_test $registry
registry_wget=$status_code
echo "#########################################################"
sed -i "s/wget_portal:.*/wget_portal: $portal_wget/" /symphony/setup-config
sed -i "s/wget_portal5:.*/wget_portal5: $portal5_wget/" /symphony/setup-config
sed -i "s/wget_cloud:.*/wget_cloud: $cloud_wget/" /symphony/setup-config
sed -i "s/wget_cloud5:.*/wget_cloud5: $cloud5_wget/" /symphony/setup-config
sed -i "s/wget_registry:.*/wget_registry: $registry_wget/" /symphony/setup-config

# Test curls
curl_test $portal
portal_codes=$final_code
curl_test $portal5
portal5_codes=$final_code
curl_test $cloud
cloud_codes=$final_code
curl_test $cloud5
cloud5_codes=$final_code
curl_test $registry
registry_codes=$final_code

echo "#########################################################"
sed -i "s/curl_portal:.*/curl_portal:   $portal_codes/" /symphony/setup-config
sed -i "s/curl_portal5:.*/curl_portal5:  $portal5_codes/" /symphony/setup-config
sed -i "s/curl_cloud:.*/curl_cloud:    $cloud_codes/" /symphony/setup-config
sed -i "s/curl_cloud5:.*/curl_cloud5:   $cloud5_codes/" /symphony/setup-config
sed -i "s/curl_registry:.*/curl_registry: $registry_codes/" /symphony/setup-config

echo ""
read -rsp $'Press any key to continue the setup script...' -n1 key

clear

if [ "$portal_wget" != "OK" ] || [ "$portal5_wget" != "OK" ] || [ "$cloud_wget" != "OK" ] || [ "$cloud5_wget" != "OK" ] || [ "$registry_wget" != "OK" ]; then
    echo ""
    echo "Unable to confirm connectivity to all services"
    echo ""
    echo "#####  Ping tests  #####"
    echo "The ping test to the default gateway ($gw) was successful, LAN connectivity is confirmed"
    echo ""
    if [ "$ip_check2" != "OK" ]; then
        echo "The ping test to 8.8.8.8 (a Google DNS server) failed, either general internet access is blocked, or routing configuration for this server's IP is missing"
    else
        echo "The ping test to 8.8.8.8 (a Google DNS server) was successful, internet connectivity is confirmed"
    fi
    echo ""
    if [ "$ip_check3" != "OK" ]; then
        echo "The ping test to google.com failed, either general internet access is blocked, or routing configuration for this server's IP is missing"
    else
        echo "The ping test to google.com was successful, domain name resolution is confirmed"
    fi
    echo ""
    echo "#####  WGET tests #####"
    echo ""
    if [ "$portal_wget" != "OK" ]; then
        echo "The WGET to $portal failed, "
    else
        echo "The ping test to 8.8.8.8 (a Google DNS server) was successful, internet connectivity is confirmed"
    fi
    echo ""
    if [ "$pn" != "" ]; then
        echo "As a Proxy was specified, it is the most likely cause of the connectivity issues"
        echo "You will need to upload at least the Proxy Root/Intermediate certificate" 
        #echo "-If there is a loadbalancer for the proxy you can try configuring this server to send traffic directly to one of the proxy nodes"
        #echo "-Getting a bypass for this sevrer, so that traffic from this server does not go via the proxy"
        #echo "-Alternatively, you may need AVI-SPL DevOps assistance to get this CPX running"
    else
        echo ""
        echo "#########################################################################"
        echo ""
        echo "Symphony connectivity test failed"
        echo ""
        read -rsp $'Press any key to restart this part of the setup script again...' -n1 key
        # clear the values from the setup-config file
        sed -i "s/wget_portal:.*/wget_portal: /" /symphony/setup-config
        sed -i "s/wget_portal5:.*/wget_portal5: /" /symphony/setup-config
        sed -i "s/wget_cloud:.*/wget_cloud: /" /symphony/setup-config
        sed -i "s/wget_cloud5:.*/wget_cloud5: /" /symphony/setup-config
        sed -i "s/wget_registry:.*/wget_registry: /" /symphony/setup-config
        # trigger the login script again
        sudo su -
    fi
else
    sed -i "s/portal:.*/portal: $portal_wget/" /symphony/setup-config
    sed -i "s/portal5:.*/portal5: $portal5_wget/" /symphony/setup-config
    sed -i "s/cloud:.*/cloud: $cloud_wget/" /symphony/setup-config
    sed -i "s/cloud5:.*/cloud5: $cloud5_wget/" /symphony/setup-config
    sed -i "s/registry:.*/registry: $registry_wget/" /symphony/setup-config
fi

echo ""
echo "---------------------------------------------------------------------------"
echo ""
echo "The initial phase is now completed"
echo ""
echo "For the next phase you will need information from your welcome letter"
echo ""
echo "It is advised that you disconnect from this console session and reconnect to the newly"
echo "configured IP of this machine (symphony@$ip) using an SSH client (like Putty)"
echo "(this recommendation is for ease of use, so that you can paste into the terminal)"
echo ""
echo "Do you want to continue?"
echo "( Y to continue this session and manually enter details here )"
echo "( N to exit this session and reconnect using an SSH client like Putty (setup will resume when you log in) )"
echo ""
yn
c_or_q=$ynresult

if [ "$c_or_q" = "N" ]; then
    echo "In your Putty/SSH client, enter symphony@$ip for the connection address"
    echo "Enter the '5ym...' password when prompted, and the setup process should then resume"
    echo "(by default, right clicking in the Putty window pastes the contents of your clipboard)"
    exit 0
    elif [ "$c_or_q" = "Y" ]; then
    sudo su -
fi

