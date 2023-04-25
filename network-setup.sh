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
        read -p "y or n ? : " q
        if [ "$q" = "y" ] || [ "$q" = "Y" ] || [ "$q" = "YES" ] || [ "$q" = "yes" ] || [ "$q" = "Yes" ]
        then
            result="Y"
            break
        elif [ "$q" = "n" ] || [ "$q" = "N" ] || [ "$q" = "NO" ] || [ "$q" = "no" ] || [ "$q" = "No" ]
        then
            result="N"
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
        fi
    done
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
echo "  ____                        _"
echo " / ___| _   _ _ __ ___  _ __ | |__   ___  _ __  _   _"
echo " \___ \| | | | '_ ' _ \| '_ \| '_ \ / _ \| '_ \| | | |"
echo "  ___) | |_| | | | | | | |_) | | | | (_) | | | | |_| |"
echo " |____/ \__, |_| |_| |_| .__/|_| |_|\___/|_| |_|\__, |"
echo "   ____ |___/_  __    _|_|       _              |___/"
echo "  / ___|  _ \ \/ /   / ___|  ___| |_ _   _ _ __"
echo " | |   | |_) \  /    \___ \ / _ \ __| | | | '_ \ "
echo " | |___|  __//  \     ___) |  __/ |_| |_| | |_) |"
echo "  \____|_|  /_/\_\   |____/ \___|\__|\__,_| .__/"
echo "                                          |_|"
echo ""
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
echo "------------------------------------------------------------------"
echo ""
echo "Do you have all of the required information above?"
echo ""
yn
q1=$result
if [ "$q1" = "Y" ]; then
    clear
elif [ "$q1" = "N" ]; then
    echo ""
    echo "Aborting as 'No' was indicated"
    echo ""
    echo "Please restart this server once you have all of the required information"
    echo ""
    exit 0
else
    echo "not a valid response, please indicate either yes or no"
fi
echo ""
echo "Please provide the IP address you want this machine to use"
echo "( subnetmask information will be collected later )"
echo ""
vip
ip=$result
clear
echo ""
echo "Please provide the subnet mask for the "$ip " address in slash notation"
echo "( for example /24 or /27 or /28 )"
echo "255.255.255.252 = /30	255.255.255.248	= /29
255.255.255.240	= /28	255.255.255.224	= /27
255.255.255.192	= /26	255.255.255.128	= /25
255.255.255.0	= /24	255.255.254.0 = /23
255.255.252.0	= /22	255.255.248.0 = /21
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
    fi
done
clear
echo ""
echo "Please provide the default Gateway IP for "$ip
echo ""
vip
gw=$result
clear
echo ""
echo "Please provide the first DNS server IP you want this machine to use"
echo "It can be internal/private and/or external/public"
echo ""
vip
dns1=$result
clear
echo ""
echo "DNS 1 set to: "$dns1
echo ""
echo "do you want to add a second DNS server?"
echo ""
yn
dns2q=$result
if [ "$dns2q" = "Y" ]; then
    clear
    echo ""
    echo "Please provide the second DNS server IP you want this machine to use"
    echo "It can be internal/private and/or external/public"
    echo ""
    vip
    dns2=$result
    clear
    echo ""
    echo "DNS 2 set to: "$dns2
    echo ""
    echo "do you want to add a third DNS server?"
    echo ""
fi
if [ "$dns2q" = "Y" ]
then
    yn
    dns3q=$result
    if [ "$dns3q" = "Y" ]; then
        clear
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
echo ""
echo "Do you want to change the hostname of this machine?"
echo "it is currently set to: debian"
echo ""
yn
q2=$result
if [ "$q2" = "Y" ]; then
    clear
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
echo ""
echo "This machine is currently configured to use a pool of NTP servers from ntp.org"
echo "Do you want to change from that to an internal NTP server/pool?"
echo ""
yn
q3=$result
clear
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
        read -p "Enter your selection: " ntpq1
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
echo ""
echo "Do proxy settings need to be configured for this machine to reach the internet?"
echo ""
yn
q4=$result
clear
if [ "$q4" = "Y" ]; then
    echo ""
    echo "What proxy information will you be providing?"
    echo ""
    echo "1 - An IP address and port"
    echo "2 - A hostname/FQDN and port"
    echo ""
    while :; do
        read -p "Enter your selection: " proxy_question
        if [[ "$proxy_question" = "1" || "$proxy_question" = "2" ]]; then
            echo ""
            break
        else
            echo "Not a valid selection, please try again"
        fi
    done
    clear
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
    case $proxy_question in
        1)
            echo "And now enter the proxy IP address"
            echo ""
            vip
            pip=$result
            proxy=$pip":"$pn
            sed -i "s/proxy_ip:.*/proxy_ip: $pip/" /symphony/setup-config
        ;;
        2)
            echo "First, enter just the proxy hostname/FQDN"
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
echo ""
echo "Please check the details below"
echo ""
echo ""
echo "IP and subnetmask for this machine:             "$ip"/"$sn
echo "The default gateway for this machine:           "$gw
echo "The DNS server(s) this machine will use: DNS 1: "$dns1
if [ "$dns2q" = "Y" ]; then
    echo "                                         DNS 2: "$dns2
fi
if [ "$dns3q" = "Y" ]; then
    echo "                                         DNS 3: "$dns3
fi
echo "The hostname for this machine will be:          "$hostname
if [ "$ntpq1" = "1" ] || [ "$ntpq1" = "3" ]; then
    ntpstring="pool "$ntpv" iburst"
    echo "You have chosen to use the NTP pool:            "$ntpv
    elif [ "$ntpq1" = "2" ] || [ "$ntpq1" = "4" ]; then
    ntpstring="server "$ntpv" iburst"
    echo "You have chosen this single NTP server:         "$ntpv
else
    echo "This machine will use the default NPT pool:     2.debian.pool.ntp.org"
fi
echo ""
if [ "$q4" = "Y" ]; then
    echo "This proxy to use for communication is:         "$proxy
else
    echo "No proxy settings suppied/required"
fi
echo ""
echo ""
echo "Are all of the details above correct?"
echo "( N will restart this setup script )"
echo ""
yn
conf=$result
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
if [ "$q4" = "Y" ]; then
    #write the /etc/profile.d/proxy.sh file
    if [ ! -f /etc/profile.d/proxy.sh ]; then
        touch /etc/profile.d/proxy.sh
        echo "/etc/profile.d/proxy.sh file successfully created"
        cp /etc/profile.d/proxy.sh /etc/profile.d/proxy.sh.orig
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

    echo "/etc/profile.d/proxy.sh file populated successfully"
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
    echo "Default Gateway is responding"
    ip_check1="OK"
else
    ip_check1="FAIL"
    echo "Default Gateway is NOT responding"
fi
if [ "$ip_check1" = "OK" ]; then
    ### Ping Google DNS IP to confirm internet connectivity
    ping_dns_ip=$(ping -c 1 "8.8.8.8" > /dev/null)
    if [ $? -eq 0 ]; then
        ip_check2="OK"
        echo "Google DNS IP is responding"
    else
        ip_check2="FAIL"
        echo "Google DNS IP is NOT responding"
    fi
    ### Ping Google Domain to confirm DNS functionality
    ping_dns_d=$(ping -c 1 "google.com" > /dev/null)
    if [ $? -eq 0 ]; then
        ip_check3="OK"
        echo "google.com is resolving to an IP"
    else
        ip_check3="FAIL"
        echo "google.com is NOT resolving to an IP"
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
portal6="https://portal.vnocsymphony.com"
portal5="https://portal5.avisplsymphony.com/symphony-portal"
cloud6="https://cloud.vnocsymphony.com"
cloud5="https://cloud5.avisplsymphony.com/symphony-cloud-api"
registry="https://registry.vnocsymphony.com"

echo "#####################################################################################################"
reply1=$(wget -T 3 --no-check-certificate --delete-after ${portal6} 2>&1)
c1=$(echo "$reply1" |grep "connected")
if [ `expr length "$c1"` != "0" ]; then
    echo $portal6
    echo "Is reachable"
    portal6_reachable="OK"
else
    echo $portal6
    echo "Is NOT reachable"
    portal6_reachable="Failed"
fi
echo "#####################################################################################################"
reply2=$(wget -T 3 --no-check-certificate --delete-after ${portal5} 2>&1)
c2=$(echo "$reply2" |grep "connected")
if [ `expr length "$c2"` != "0" ]; then
    echo $portal5
    echo "Is reachable"
    portal5_reachable="OK"
else
    echo $portal5
    echo "Is NOT reachable"
    portal5_reachable="FAIL"
fi
echo "#####################################################################################################"
reply3=$(wget -T 3 --no-check-certificate --delete-after ${cloud6} 2>&1)
c3=$(echo "$reply3" |grep "connected")
if [ `expr length "$c3"` != "0" ]; then
    echo $cloud6
    echo "Is reachable"
    cloud6_reachable="OK"
else
    echo $cloud6
    echo "Is NOT reachable"
    cloud6_reachable="FAIL"
fi
echo "#####################################################################################################"
reply4=$(wget -T 3 --no-check-certificate --delete-after ${cloud5} 2>&1)
c4=$(echo "$reply4" |grep "connected")
if [ `expr length "$c4"` != "0" ]; then
    echo $cloud5
    echo "Is reachable"
    cloud5_reachable="OK"
else
    echo $cloud5
    echo "Is NOT reachable"
    cloud5_reachable="FAIL"
fi
echo "#####################################################################################################"
reply5=$(wget -T 3 --no-check-certificate --delete-after ${registry} 2>&1)
c5=$(echo "$reply5" |grep "connected")
if [ `expr length "$c5"` != "0" ]; then
    echo $registry
    echo "Is reachable"
    registry_reachable="OK"
else
    echo $registry
    echo "Is NOT reachable"
    registry_reachable="FAIL"
fi
echo "#####################################################################################################"

sed -i "s/wget_portal6:.*/wget_portal6: $portal6_reachable/" /symphony/setup-config
sed -i "s/wget_portal5:.*/wget_portal5: $portal5_reachable/" /symphony/setup-config
sed -i "s/wget_cloud6:.*/wget_cloud6: $cloud6_reachable/" /symphony/setup-config
sed -i "s/wget_cloud5:.*/wget_cloud5: $cloud5_reachable/" /symphony/setup-config
sed -i "s/wget_registry:.*/wget_registry: $registry_reachable/" /symphony/setup-config

clear

if [ "$portal6_reachable" != "OK" ] || [ "$portal5_reachable" != "OK" ] || [ "$cloud6_reachable" != "OK" ] || [ "$cloud5_reachable" != "OK" ] || [ "$registry_reachable" != "OK" ]; then
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
    if [ "$portal_reachable" != "OK" ]; then
        echo "The WGET to $portal6 failed, "
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
        sed -i "s/wget_portal6:.*/wget_portal6: /" /symphony/setup-config
        sed -i "s/wget_portal5:.*/wget_portal5: /" /symphony/setup-config
        sed -i "s/wget_cloud6:.*/wget_cloud6: /" /symphony/setup-config
        sed -i "s/wget_cloud5:.*/wget_cloud5: /" /symphony/setup-config
        sed -i "s/wget_registry:.*/wget_registry: /" /symphony/setup-config
        # trigger the login script again
        sudo su -
    fi
else
    sed -i "s/portal6:.*/portal6: $portal6_reachable/" /symphony/setup-config
    sed -i "s/portal5:.*/portal5: $portal5_reachable/" /symphony/setup-config
    sed -i "s/cloud6:.*/cloud6: $cloud6_reachable/" /symphony/setup-config
    sed -i "s/cloud5:.*/cloud5: $cloud5_reachable/" /symphony/setup-config
    sed -i "s/registry:.*/registry: $registry_reachable/" /symphony/setup-config
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
c_or_q=$result

if [ "$c_or_q" = "N" ]; then
    echo "In your Putty/SSH client, enter symphony@$ip for the connection address"
    echo "Enter the '5ym...' password when prompted, and the setup process should then resume"
    echo "(by default, right clicking in the Putty window pastes the contents of your clipboard)"
    exit 0
    elif [ "$c_or_q" = "Y" ]; then
    sudo su -
fi