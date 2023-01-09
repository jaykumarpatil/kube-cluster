#!/bin/bash
set -x
## Colors list

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

# High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White

# Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'   # Black
On_IRed='\033[0;101m'     # Red
On_IGreen='\033[0;102m'   # Green
On_IYellow='\033[0;103m'  # Yellow
On_IBlue='\033[0;104m'    # Blue
On_IPurple='\033[0;105m'  # Purple
On_ICyan='\033[0;106m'    # Cyan
On_IWhite='\033[0;107m'   # White

# function backup_file () {
#   # This function creates a backup of a file.
#   # Make sure the file exists.
#   if [ -f "$1" ]; then
#     # Make the BACKUP_FILE variable local to this function.
#     local BACKUP_FILE="$(dirname ${1})/$(basename ${1})_$(date +%F).$$.bak"
#     echo "Backing up $1 to ${BACKUP_FILE}"
#     # The exit status of the function will be the exit status of the cp command.
#     cp $1 $BACKUP_FILE
#   else
#     # The file does not exist, so return an non-zero exit status.
#     echo "Invalid Arguments."
#     return 1
#   fi
# }

function create_sequenced_name_list () {

    local prefix=$1
    local name=$2
    local count=$3 

    # Validations for prefix name and count 
    if [[ -z "$prefix" ]] && [[$prefix =~ ^[A-Za-z]*[A-Za-z][A-Za-z0-9-. _]*$]]; then
            echo "Invalid Arguments."
        return 1
    fi

    if [[ -z "$name" ]] && [[$prefix =~ ^[A-Za-z]*[A-Za-z][A-Za-z0-9-. _]*$]]; then
            echo "Invalid Arguments."
        return 1
    fi

    if [[ -z "$count" ]] || [[ "$count" -le 0 ]] && [[$prefix =~ ^[0-9*$]]; then
            echo "Invalid Arguments."
        return 1
    fi

    if [[ "$count" -eq 1 ]]; then
            echo $(eval echo "$prefix-$name")
        return 0
    fi

    # Generate list
    local from=1 
    local to="$count"
    echo $(eval echo "${prefix}-${name}-{$from..$to}") 
    return 0 
}

# Name and count of cluster
CLUSTER_NAME="k8s"

# Name and count of cluster
CONTROL_PLANE_NAME="control-plane"
CONTROL_PLANE_SERVER_COUNT=1

# Name and count of master node
MASTER_NAME="master"
MASTER_SERVER_COUNT=2

# Name and count of worker node
WORKER_NAME="worker"
WORKER_SERVER_COUNT=3

CONTROL_PLANE_NODES="$(create_sequenced_name_list ${CLUSTER_NAME} ${CONTROL_PLANE_NAME} ${CONTROL_PLANE_SERVER_COUNT})"
MASTER_NODES="$(create_sequenced_name_list ${CLUSTER_NAME} ${MASTER_NAME} ${MASTER_SERVER_COUNT})"
WORKER_NODES="$(create_sequenced_name_list ${CLUSTER_NAME} ${WORKER_NAME} ${WORKER_SERVER_COUNT})"

CLUSTER_NODES=$(echo "${CONTROL_PLANE_NODES[@]} ${MASTER_NODES[@]} ${WORKER_NODES[@]}")

# CONTROL_PLANE_SERVER_LIST="$(convert_space_to_list_format ${CONTROL_PLANE_NODES[@]})"
# MASTER_SERVER_LIST="$(convert_space_to_list_format ${MASTER_NODES[@]})"
# WORKER_SERVER_LIST="$(convert_space_to_list_format ${WORKER_NODES[@]})"

# echo $CONTROL_PLANE_SERVER_LIST
# echo $MASTER_SERVER_LIST
# echo $WORKER_SERVER_LIST

# echo "Control Plane Servers List : $(echo ${CONTROL_PLANE_NODES})"
# echo "Master Servers List : $(echo ${MASTER_NODES})"
# echo "Worker Servers List : $(echo ${WORKER_NODES})"

# echo "$(multipass list --format=csv | awk -F "," 'BEGIN { ORS=" " }; {if (NR!=1) {print $1}}')"
# echo -e "\nALL SERVER"
# echo "------------------------------------------------------"
# echo "${ALL_NODES}" | awk -vORS=', ' '{ print $1 }' | sed 's/, $/\n/'
CLUSTER_NODE_NAME_LIST=$(echo ${CLUSTER_NODES} | sed 's/ /\n/g' | sort -u | awk -vORS=', ' '{ print $1 }' | sed 's/, $/\n/')
echo -e "${Red}Following server are will be deleted if exits${Color_Off} :\n${CLUSTER_NODE_NAME_LIST}"

read -p "Enter \"y\" to proceed or \"n\" to exit:" ANSWER
case "$ANSWER" in
    [yY]*)
        
        echo $(echo ${CLUSTER_NODES} | sed 's/ /\n/g' | sort -u | awk -vORS=', ' '{ print $1 }' | sed 's/, $/\n/')
        multipass delete $(echo ${CLUSTER_NODES} | sed 's/\n/ /g' | sort -u)
        multipass purge
        ;;
   *)
        exit 0        
esac

echo -e "\n${Green}Following server will be created.${Color_Off} Please wait...\n${CLUSTER_NODE_NAME_LIST}"

for node in ${CLUSTER_NODES}
do
    multipass launch --name=${node}
    multipass exec ${node} -- sudo bash -c "apt update 2>/dev/null | apt upgrade -y 2>/dev/null"
done

echo -e "\n${Green}Find the list of available servers\n------------------------------------------------------${Color_Off}"
multipass list



echo -e "\nSetting ssh in following servers with $(echo ${CONTROL_PLANE_NODES} | awk -vORS=', ' '{ print $1 }' | sed 's/, $/\n/') as control plane nodes"
echo "------------------------------------------------------"
echo "${CLUSTER_NODES}" | awk -vORS=', ' '{ print $1 }' | sed 's/, $/\n/'

for controlplane in ${CONTROL_PLANE_NODES}
do
    echo -e "\nCopying CONTROL PLANE NODES KEYS form ${CONTROL_PLANE_NODES}"
    multipass exec ${controlplane} -- sudo bash -c "ssh-keygen -q -t ed25519 -N '' <<< $'\ny' >/dev/null 2>&1"
    KEY=$(multipass exec ${controlplane} -- sudo bash -c "cat /root/.ssh/id_ed25519.pub")
    for node in ${CLUSTER_NODES}
    do
        echo -e "\nCopying SSH KEYS form ${controlplane} --> ${node}";
        multipass exec ${node} -- sudo bash -c "cp /root/.ssh/authorized_keys /root/.ssh/authorized_keys.bak"
        multipass exec ${node} -- sudo bash -c "cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak"
        $(multipass exec ${node} -- sudo bash -c "echo ${KEY} >> /root/.ssh/authorized_keys")
        multipass exec ${node} -- sudo bash -c "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin without-password/g' /etc/ssh/sshd_config"
        multipass exec ${node} -- sudo bash -c "sed -i 's/#StrictModes yes/#StrictModes no/g' /etc/ssh/sshd_config"
        multipass exec ${node} -- sudo bash -c "systemctl restart sshd"
    done
done
echo -e "\n updating host file of following servers"
echo "------------------------------------------------------"
HOST_ENTRIES=$(multipass list --format=csv | grep -E "$(echo "${CLUSTER_NODES[@]}" | sed 's/ /\n/g' | sort -u | awk -vORS='|' '{ print $1 }' | sed 's/|$/\n/' )" | awk -F "," '{print $3" "$1".domain.com "$1}')
for server in ${CLUSTER_NODES[@]}
do
    $(multipass exec ${server} -- sudo bash -c "echo \"${HOST_ENTRIES}\" >> /etc/hosts")
    for host in ${CLUSTER_NODES[@]}}
    do
        $(multipass exec ${server} -- sudo bash -c "ssh-keyscan ${host} >> /root/.ssh/known_hosts")
        $(multipass exec ${server} -- sudo bash -c "ssh-keyscan ${host}.domain.com >> /root/.ssh/known_hosts")
        ip=$(multipass list --format=csv | grep -E "${host}" | awk -F "," '{print $3}')
        $(multipass exec ${server} -- sudo bash -c "ssh-keyscan ${ip} >> /root/.ssh/known_hosts")
    done 
done 

echo "Step 1 — Installing Ansible"
for controlplane in $(echo "${CONTROL_PLANE_NODES[@]}" | sed 's/ /\n/g' | sort -u) 
do
    multipass exec ${controlplane} -- sudo bash -c "apt-add-repository -y ppa:ansible/ansible"
    multipass exec ${controlplane} -- sudo bash -c "apt update 2>/dev/null"
    multipass exec ${controlplane} -- sudo bash -c "apt install ansible -y 2>/dev/null"
done
CONTROL_PLANE_HOST_ENTRIES=$(multipass list --format=csv | grep -E "$(echo "${CONTROL_PLANE_NODES[@]}" | sed 's/ /\n/g' | sort -u | awk -vORS='|' '{ print $1 }' | sed 's/|$/\n/' )" | awk -F "," '{print $1" ansible_host="$3" ansible_user=root"}')
MASTER_HOST_ENTRIES=$(multipass list --format=csv | grep -E "$(echo "${MASTER_NODES[@]}" | sed 's/ /\n/g' | sort -u | awk -vORS='|' '{ print $1 }' | sed 's/|$/\n/' )" | awk -F "," '{print $1" ansible_host="$3" ansible_user=root"}')
WORKER_HOST_ENTRIES=$(multipass list --format=csv | grep -E "$(echo "${WORKER_NODES[@]}" | sed 's/ /\n/g' | sort -u | awk -vORS='|' '{ print $1 }' | sed 's/|$/\n/' )" | awk -F "," '{print $1" ansible_host="$3" ansible_user=root"}')
for controlplane in $(echo "${CONTROL_PLANE_NODES[@]}" | sed 's/ /\n/g' | sort -u) 
do

    multipass exec ${controlplane} -- sudo bash -c "mkdir -p /etc/ansible"
    multipass exec ${controlplane} -- sudo bash -c "cat /dev/null > /etc/ansible/hosts"
    $(multipass exec ${controlplane} -- sudo bash -c "echo -e \"\n[control_plane]\n${CONTROL_PLANE_HOST_ENTRIES}\" >> /etc/ansible/hosts")
    $(multipass exec ${controlplane} -- sudo bash -c "echo -e \"\n[masters]\n${MASTER_HOST_ENTRIES}\" >> /etc/ansible/hosts")
    $(multipass exec ${controlplane} -- sudo bash -c "echo -e \"\n[servers]\n${WORKER_HOST_ENTRIES}\" >> /etc/ansible/hosts")
    multipass exec ${controlplane} -- sudo bash -c "echo -e \"\n[all:vars]\nansible_python_interpreter=/usr/bin/python3\" >> /etc/ansible/hosts"
done 
for controlplane in ${CONTROL_PLANE_NODES[@]}
do
    for node in $(${MASTER_NODES[@]} ${WORKER_NODES[@]})
    do
        echo "setting up ssh to ${controlplane} for ${node}"
        $(multipass exec ${controlplane} -- sudo bash -c "ssh root@${node} -y ls -l")
    done
done