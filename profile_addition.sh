if [ -f /symphony/setup-config ]; then
        ip=$(cat /symphony/setup-config | grep -oP '(?<=ip_address:).*')        # return everything after 'ip_address:' on the line it is found on in the setup-config file
        ip="${ip// /}"                                                          # remove any/all spaces from the value
        aid=$(cat /symphony/setup-config | grep -oP '(?<=account_id:).*')
        aid="${aid// /}"
        dns1=$(cat /symphony/setup-config | grep -oP '(?<=dns1:).*')
        dns1="${dns1// /}"
        user=$(whoami)
        if [ "$ip" = "" ]; then
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
        elif [ "$aid" = "" ]; then
                if [ "$user" = "root" ]; then
                        cd /symphony/
                        ./certs-and-symphony-setup.sh
                else
                        sudo su -
                fi
        fi
fi
