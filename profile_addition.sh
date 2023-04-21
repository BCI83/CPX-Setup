## Addition is from here down
if [ -f /symphony/setup-config ]; then
        ip=$(cat /symphony/setup-config | grep -oP '(?<=ip_address:).*')
        ip="${ip// /}"
        nm=$(cat /symphony/setup-config | grep -oP '(?<=subnet_mask:).*')
        nm="${nm// /}"
        gw=$(cat /symphony/setup-config | grep -oP '(?<=default_gateway:).*')
        gw="${gw// /}"
        dns=$(cat /symphony/setup-config | grep -oP '(?<=dns1:).*')
        dns="${dns// /}"

        an=$(cat /symphony/setup-config | grep -oP '(?<=account_name:).*')
        an="${an// /}"
        id=$(cat /symphony/setup-config | grep -oP '(?<=account_id:).*')
        id="${id// /}"
        ap=$(cat /symphony/setup-config | grep -oP '(?<=account_portal:).*')
        ap="${ap// /}"        
        ue=$(cat /symphony/setup-config | grep -oP '(?<=cpx_serviceUserEmail:).*')
        ue="${ue// /}"
        pw=$(cat /symphony/setup-config | grep -oP '(?<=cpx_serviceUserPassword:).*')
        pw="${pw// /}"

        user=$(whoami)
        
        if [ "$ip" = "" ] || [ "$nm" = "" ] || [ "$gw" = "" ] || [ "$dns" = "" ]; then
                if [ "$user" = "root" ]; then
                        cd /symphony/
                        ./network-setup.sh
                else
                        if [ "$dns1" = "" ]; then
                                clear
                                echo ""
                                echo "Switching to 'root' user, this may take a minute as DNS is not configured yet"
                                sudo su -
                        else
                                sudo su -
                        fi
                fi
        elif [ "$an" = "" ] || [ "$id" = "" ] || [ "$ap" = "" ] || [ "$ue" = "" ] || [ "$pw" = "" ]; then
                if [ "$user" = "root" ]; then
                        cd /symphony/
                        ./certs-and-symphony-setup.sh
                else
                        sudo su -
                fi
        fi
fi
