#!/bin/bash

### Setting up functions:

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
# verify user provided file exists at specified path
verify_file_path(){
while :; do
    echo ""
    read -p "Enter the absolute path fo the $1 certificate: " fp
    if [[ -f $fp ]]; then
        result=$fp
        clear
        break
    elif [[ $fp = "" ]]; then
        echo "A valid path must be provided"
    else  
        echo "Error: no file exists at the path provided"
        echo "(use the full/absolute path, for example '/symphony/"$1".crt')"
    fi
done
}
# get and verify password characters / length
get_password(){
singleq="'"
while :; do
        echo ""
        read -r -p "Enter the password for the $1: " entered_password
        clear
        echo ""
        if [[ "$entered_password" =~ [$singleq\\] ]]; then
                echo ""
                echo "The entered Password contains at least one forbidden character $singleq or \ "
                echo ""
                echo "Check the password again, if it contains a backslash or"
                echo "an apostrophe you will need a new password to be generated"
                echo ""
        else
                entered_password="${entered_password// /}"
                result=$(echo $entered_password | sed -e 's/[\/&]/\\&/g') # Escape / and &
                break
        fi
done
}

### Main()
clear
# check session type
session_type_string=$(who am i | grep tty)
echo ""
if [ "$session_type_string" = "" ]; then
    session_type="SSH"
    echo "SSH session detected, you should be able to paste your answers in for the upcomming questions."
else
    session_type="Console"
    echo "Console session detected, you will have to manually type out all answers for the upcomming questions."
fi
echo ""
read -rsp $'Press any key to continue the setup script...' -n1 key
clear

# check if DMCA is being used
dmca_config=$(cat /symphony/setup-config | grep -oP '(?<=dmca_config_check:).*')
dmca_config="${dmca_config// /}"
if [ "$dmca_config" = "" ]; then
    echo ""
    echo "Do you intend to use DMCA? (for monitoring of Windows based devices)"
    echo ""
    yn
    q1=$result
    clear
    if [ "$q1" = "Y" ]; then
        dmca_cert_uploads_req=1
        sed -i "s/dmca_config_check:.*/dmca_config_check: yes/" /symphony/setup-config
    else
        dmca_cert_uploads_req=0
        sed -i "s/dmca_config_check:.*/dmca_config_check: no/" /symphony/setup-config
    fi
elif [ "$dmca_config" = "yes" ]; then
    dmca_cert_uploads_req=1
elif [ "$dmca_config" = "no" ]; then
    dmca_cert_uploads_req=0
fi

# check if proxy settings were provided
proxy_certs_required=$(cat /symphony/setup-config | grep -oP '(?<=proxy_certs_required:).*')
proxy_certs_required="${proxy_certs_required// /}"
proxy_port=$(cat /symphony/setup-config | grep -oP '(?<=proxy_port:).*')
proxy_port="${proxy_port// /}"
if [ "$proxy_port" != "" ]; then
    if [ "$proxy_certs_required" = "" ]; then
        clear
        echo ""
        echo "Proxy configuration was provided in the previous section"
        echo ""
        echo "Does the proxy do certificate fixup / substitution?"
        echo "(If yes you need to provide certificate(s) for this)"
        echo ""
        yn
        q2=$result
        clear
        if [ "$q2" = "Y" ]; then        
            proxy_certs_required="yes"
            sed -i "s/proxy_certs_required:.*/proxy_certs_required: yes/" /symphony/setup-config
        else
            proxy_certs_required="no"
            sed -i "s/proxy_certs_required:.*/proxy_certs_required: no/" /symphony/setup-config
        fi
    fi
fi
# notify that certs need to be uploaded (only if they are required)
if [ "$dmca_cert_uploads_req" = 1 ] || [ "$proxy_certs_required" = "yes" ]; then
    dmca_file_name=$(cat /symphony/setup-config | grep -oP '(?<=dmca_ssl_file_name:).*')
    dmca_file_name="${dmca_file_name// /}"
    dmca_file_path=$(cat /symphony/setup-config | grep -oP '(?<=dmca_ssl_file_path:).*')
    dmca_file_path="${dmca_file_path// /}"
    proxy_ca=$(cat /symphony/setup-config | grep -oP '(?<=ca_certificate:).*')
    proxy_ca="${proxy_ca// /}"
    proxy_int=$(cat /symphony/setup-config | grep -oP '(?<=intermediate_certificate:).*')
    proxy_int="${proxy_int// /}"

    needinput=0
    if [ "$dmca_file_name" = "" ] && [ "$dmca_file_path" = "" ]; then
        needinput=1
    fi
    if [ "$proxy_ca" = "" ] && [ "$proxy_int" = "" ]; then
        needinput=1
    fi

    if [ $needinput=1 ]; then
        clear
        echo ""
        echo "Certificates are required for:" 
        if [ "$dmca_cert_uploads_req" = 1 ]; then
            if [ "$dmca_file_name" = "" ] || [ "$dmca_file_path" = "" ]; then
                echo ""
                echo "-DMCA functionality"
                echo " (SSL certificate)"
            fi
        fi
        if [ "$proxy_certs_required" = "yes" ]; then
            if [ "$proxy_ca" = "" ] && [ "$proxy_int" = "" ]; then
                echo ""
                echo "-Proxy functionality"
                echo " (CA certificate that the proxy uses)"
                echo " (Intermediate certificate if available)"
            fi
        fi

        while :; do        
            echo ""
            echo "Choose from the options below"
            echo ""
            echo "1 - Quit this script (so that you can upload the required certificates to this VM)"
            echo "    (Make sure to remove spaces from the certificate file names, and note down the full path(s))"
            echo "    (once done you can resume this script by restarting this VM, or running the command 'sudo su -')"
            echo ""
            echo "2 - Continue this script, (only if all required certificates are uploaded to this VM, and the full path(s) are known)"
            echo ""
            read -p "Enter your selection: " proxycertsq
            if (($proxycertsq >= 1 && $proxycertsq <= 2)); then
                echo ""
                break
            else
                echo "Not a valid selection, please try again"
            fi
        done
        echo ""
        case $proxycertsq in
            1)
            ip=$(cat /symphony/setup-config | grep -oP '(?<=ip_address:).*')
            ip="${ip// /}"  
            echo "(This server can be reached at 'symphony@"$ip"' and providing the '5ym...' password when prompted)"
            echo ""
            ;;            
            2)
            if [ "$proxy_certs_required" = "yes" ]; then
                proxy_ca=$(cat /symphony/setup-config | grep -oP '(?<=ca_certificate:).*')
                proxy_ca="${proxy_ca// /}"
                proxy_int=$(cat /symphony/setup-config | grep -oP '(?<=intermediate_certificate:).*')
                proxy_int="${proxy_int// /}"
                if [ "$proxy_ca" = "" ] &&  [ "$proxy_int" = "" ]; then
                    while :; do
                        clear
                        echo ""
                        echo "Which proxy certificates do you want to provide?"
                        echo ""
                        echo "1 - A CA Certificate"
                        echo "2 - An Intermediate Certificate"
                        echo "3 - Both Certificates"
                        echo ""
                        read -p "Enter your selection: " proxycertsq
                        if (($proxycertsq >= 1 && $proxycertsq <= 3)); then
                            echo ""
                            break
                        else
                            echo "Not a valid selection, please try again"
                        fi
                    done
                    case $proxycertsq in
                        1)
                        verify_file_path "Proxy CA"
                        sed -i "s/ca_certificate:.*/ca_certificate: $result/" /symphony/setup-config
                        ;;
                        2)
                        verify_file_path "Proxy Intermediate"
                        sed -i "s/intermediate_certificate:.*/intermediate_certificate: $result/" /symphony/setup-config
                        ;;
                        3)
                        verify_file_path "Proxy CA"
                        sed -i "s/ca_certificate:.*/ca_certificate: $result/" /symphony/setup-config
                        verify_file_path "Proxy Intermediate"
                        sed -i "s/intermediate_certificate:.*/intermediate_certificate: $result/" /symphony/setup-config
                        ;;        
                    esac
                fi
            fi
            if [ "$dmca_cert_uploads_req" = 1 ]; then
                dmca_file_name=$(cat /symphony/setup-config | grep -oP '(?<=ssl_cert_file_name:).*')
                dmca_file_name="${dmca_file_name// /}"
                dmca_file_path=$(cat /symphony/setup-config | grep -oP '(?<=ssl_cert_file_location:).*')
                dmca_file_path="${dmca_file_path// /}"
                dmca_cert_pw=$(cat /symphony/setup-config | grep -oP '(?<=ssl_cert_file_pass:).*')
                dmca_cert_pw="${dmca_cert_pw// /}"
                if [ "$dmca_file_name" = "" ] || [ "$dmca_file_path" = "" ] || [ "$dmca_cert_pw" = "" ]; then
                        if [ "$dmca_file_name" = "" ]; then
                                verify_file_path "DMCA SSL"
                                dmca_ssl_file_name=$(echo $result | sed 's:.*/::') # get everything after the last / (the file name)
                                dmca_ssl_file_path="$(dirname "$result")" # get the directory name
                                dmca_ssl_file_path=$(echo $dmca_ssl_file_path | sed -e 's/[\/&]/\\&/g') # Escape / and &
                                sed -i "s/ssl_cert_file_name:.*/ssl_cert_file_name: $dmca_ssl_file_name/" /symphony/setup-config
                                sed -i "s/ssl_cert_file_location:.*/ssl_cert_file_location: $dmca_ssl_file_path\//" /symphony/setup-config
                        fi
                        if [ "$dmca_cert_pw" = "" ]; then
                                get_password "DMCA SSL CERTIFICATE"
                                echo ""
                                sed -i "s'ssl_cert_file_pass:.*'ssl_cert_file_pass: $result'" /symphony/setup-config
                        fi
                fi
            fi
            ;;
        esac
    fi
fi

### Gather Symphony settings
clear
# Check for existing values
sym_an=$(cat /symphony/setup-config | grep -oP '(?<=account_name:).*')
sym_an="${sym_an// /}"
sym_aid=$(cat /symphony/setup-config | grep -oP '(?<=account_id:).*')
sym_aid="${sym_aid// /}"
sym_portal=$(cat /symphony/setup-config | grep -oP '(?<=account_portal:).*')
sym_portal="${sym_portal// /}"
sym_ccun=$(cat /symphony/setup-config | grep -oP '(?<=cpx_serviceUserEmail:).*')
sym_ccun="${sym_ccun// /}"
sym_ccpw=$(cat /symphony/setup-config | grep -oP '(?<=cpx_serviceUserPassword:).*')
sym_ccpw="${sym_ccpw// /}"

#if [ "$sym_aid" = "" ] || [ "$sym_portal" = "" ] || [ "$sym_ccun" = "" ] || [ "$sym_ccpw" = "" ]; then
#    echo ""
#    echo ""
#    echo ""
#fi

# get account name
if [ "$sym_an" = "" ]; then
    while :; do
        echo ""
        echo "### Account Name ###"
        echo ""
        echo "This can be anything, it will be used to name folders and services on this server"
        echo "As such it should only consist of a-z, A-Z, - (hyphen) and _ (underscore)"
        echo "( This detail is not a part of the welcome letter )"
        echo ""
        read -p "Enter the desired Account Name: " an
        if [[ "$an" =~ ^[a-zA-Z_-]+$ ]]; then # check for only valid characters
            sed -i "s'account_name:.*'account_name: $an'" /symphony/setup-config
            clear
            break
        else
            clear
            echo ""
            echo "The 'Account Name' entered is not valid"
            echo "Check that is only consists of the allowed characters"
            echo ""
        fi
    done
    clear 
fi

# get account number
if [ "$sym_id" = "" ]; then
    while :; do
        echo ""
        echo "### Account ID ###"
        echo ""
        echo "This detail can be found on your welcome letter"
        echo "It consists of a-z, 0-9, and - (hyphen)"
        echo ""
        read -p "Enter the Account ID (including the hyphens): " aid
        if [[ "$aid" =~ ^[a-z0-9-]+$ && ${#aid} -eq 36 ]]; then
            aid="${aid// /}"
            sed -i "s'account_id:.*'account_id: $aid'" /symphony/setup-config
            clear
            break
        else
            clear
            echo ""
            echo "The supplied value is not valid"
            echo "Check that is only consists of the allowed characters (include the hyphens)"
        fi
    done
    clear  
fi

# select a portal
if [ "$sym_portal" = "" ]; then
    while :; do
            echo ""
            echo "### Portal Selection ###"
            echo ""
            echo "This detail can be found on your welcome letter"
            echo "(It consists of 3 or 4 letters)"
            echo ""
            read -p "Enter the Symphony Portal: " portal
            if [[ "$portal" = "PROD" || "$portal" = "Prod" || "$portal" = "prod" ]]; then
                    break
            elif [[ "$portal" = "EMEA" || "$portal" = "Emea" || "$portal" = "emea" ]]; then
                    break
            elif [[ "$portal" = "INT" || "$portal" = "Int" || "$portal" = "int" ]]; then
                    break
            elif [[ "$portal" = "DEV" || "$portal" = "Dev" || "$portal" = "dev" ]]; then
                    break
            else
                    clear
                    echo ""
                    echo "Unknown/invalid Portal environment provided"
            fi
    done
    sed -i "s'account_portal:.*'account_portal: $portal'" /symphony/setup-config
    clear    
fi

# get cpx user email
if [ "$sym_ccun" = "" ]; then
    while :; do
        echo ""
        read -p "Enter your Cloud Connector Username: " ccun

        if [[ "$ccun" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            ccun="${ccun// /}"
            sed -i "s'cpx_serviceUserEmail:.*'cpx_serviceUserEmail: $ccun'" /symphony/setup-config
            break
        else
            echo "Invalid 'Cloud Connector Username' entered"
            echo "(It will be in the format of an email address)"
        fi
    done
    clear
fi

# get cpx user password
if [ "$dmca_cert_pw" = "" ]; then
    get_password "Cloud Connector"
    echo ""
    sed -i "s'cpx_serviceUserPassword:.*'cpx_serviceUserPassword: $result'" /symphony/setup-config
    clear
fi

#########################################################################################################
### Info collection done
#########################################################################################################

### Now add colledted data to the Ansible variable file (or update them if they already exist)

# Make list of required variables (and add single quotes to strings to keep Ansible happy)
sym_an=$(cat /symphony/setup-config | grep -oP '(?<=account_name:).*')
sym_an="${sym_an// /}"
sym_an='account_name:"'$sym_an'"'

sym_aid=$(cat /symphony/setup-config | grep -oP '(?<=account_id:).*')
sym_aid="${sym_aid// /}"
sym_aid='account_id:"'$sym_aid'"'

sym_portal=$(cat /symphony/setup-config | grep -oP '(?<=account_portal:).*')
sym_portal="${sym_portal// /}"
sym_portal='account_portal:"'$sym_portal'"'

sym_ccun=$(cat /symphony/setup-config | grep -oP '(?<=cpx_serviceUserEmail:).*')
sym_ccun="${sym_ccun// /}"
sym_ccun='cpx_serviceUserEmail:"'$sym_ccun'"'

sym_ccpw=$(cat /symphony/setup-config | grep -oP '(?<=cpx_serviceUserPassword:).*')
sym_ccpw="${sym_ccpw// /}"
sym_ccpw='cpx_serviceUserPassword:"'$sym_ccpw'"'

dmca_cc=$(cat /symphony/setup-config | grep -oP '(?<=dmca_config_check:).*')
dmca_cc="${dmca_cc// /}"
dmca_cc='dmca_config_check:"'$dmca_cc'"'

dmca_file_name=$(cat /symphony/setup-config | grep -oP '(?<=ssl_cert_file_name:).*')
dmca_file_name="${dmca_file_name// /}"
dmca_file_name='ssl_cert_file_name:"'$dmca_file_name'"'

dmca_file_path=$(cat /symphony/setup-config | grep -oP '(?<=ssl_cert_file_location:).*')
dmca_file_path="${dmca_file_path// /}"
dmca_file_path='ssl_cert_file_location:"'$dmca_file_path'"'

dmca_cert_pw=$(cat /symphony/setup-config | grep -oP '(?<=ssl_cert_file_pass:).*')
dmca_cert_pw="${dmca_cert_pw// /}"
dmca_cert_pw='ssl_cert_file_pass:"'$dmca_cert_pw'"'

list_of_vars="$sym_an $sym_aid $sym_portal $sym_ccun $sym_ccpw $dmca_cc $dmca_file_name $dmca_file_path $dmca_cert_pw"

# Add to end, or modify existing sntries in the defaults file
file="/symphony/symphony-cpx-ansible-role/defaults/main.yml"
for var in $list_of_vars; do
    # Get key from 'key: value' pairs
    key=$(echo "$var" | cut -d':' -f1)

    if grep -q "^$key:" "$file"; then
        sed -i "s/^$key:.*/$var/" "$file"
    else
        echo "$var" >> "$file"
    fi
done
sed -i 's/:"/: "/g' $file # adds the space after the colon to the key: value pairs (it has to be missing initially so that the keys and their values aren't treated as separate items in the $list_of_vars list)

### Now create a replacement start_here.yml (without the Q&A section) and run it

playbook='---
- hosts: localhost
#  become: yes
#
# Questions and answer section omitted, as that`s already done in the script
#
###
#
# START PLAYBOOK AFTER QUESTIONS ARE ANSWERED AND SAVED
#
####
  tasks:
    - name: Include OS-specific variables.
      include_vars: "{{ playbook_dir }}/defaults/main.yml"
    # check if playbook has been run and fail if it has
    # this prevents changing cpx config settings and systems that have already been
    - name: Check if playbook was run before
      stat:
        path: "{{ symphony_prerun_dir }}/{{ pre_run_check_file }}"
      register: prerun_check

    - name: Configuration Pre Check
      fail:
        msg: "This playbook has run on this system previously"
      when: prerun_check.stat.exists

    - name: Configuration Pre Check
      fail:
        msg: "This playbook has run on this system previously"
      when: prerun_check.stat.exists

    - import_tasks: "tasks/main.yml"
'
pb="/symphony/symphony-cpx-ansible-role/new_start.yml"
if [ ! -f $pb ]; then
    sudo -u symphony touch $pb
fi
sudo -u symphony > $pb # make sure it's empty in case of pre-existing file
echo "$playbook" >> $pb

sudo -u symphony ansible-playbook $pb
sed -i "s'setup_run:.*'setup_run: yes'" /symphony/setup-config