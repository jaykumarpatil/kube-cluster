#!/bin/bash
MASTER_SERVER=$(echo "k8s-m1 k8s-m2" | sed 's/ /\n/g' | sort -u)
echo -e "\nALL MASTER SERVER"
echo "------------------------------------------------------"
echo "${MASTER_SERVER}" | awk -vORS=', ' '{ print $1 }' | sed 's/, $/\n/'
SLAVE_SERVER=$(echo "k8s-s1 k8s-s2 k8s-s3" | sed 's/ /\n/g' | sort -u)
echo -e "\nALL SLAVE SERVER"
echo "------------------------------------------------------"
echo "${SLAVE_SERVER}" | awk -vORS=', ' '{ print $1 }' | sed 's/, $/\n/'

echo -e "\nFollowing server are will be deleted if exits"
echo "------------------------------------------------------"
echo $(echo "${MASTER_SERVER[@]} ${SLAVE_SERVER[@]}" | sed 's/ /\n/g' | sort -u | awk -vORS=', ' '{ print $1 }' | sed 's/, $/\n/')

multipass delete $(echo "${MASTER_SERVER[@]} ${SLAVE_SERVER[@]}" | sed 's/\n/ /g' | sort -u)
multipass purge

echo -e "\nFollowing server will be created. Please wait..."
echo "------------------------------------------------------"
echo $(echo "${MASTER_SERVER[@]} ${SLAVE_SERVER[@]}" | sed 's/ /\n/g' | sort -u | awk -vORS=', ' '{ print $1 }' | sed 's/, $/\n/')

for server in $(echo "${MASTER_SERVER[@]} ${SLAVE_SERVER[@]}" | sed 's/ /\n/g' | sort -u) 
do
    multipass launch --name=${server}
done

echo -e "\nFind the list of available servers"
echo "------------------------------------------------------"
multipass list

# ALL_SERVER=$(multipass list --format=csv | awk -F "," '{if (NR!=1) {print $1}}')\
# echo -e "\nALL SERVER"
# echo "------------------------------------------------------"
# echo "${ALL_SERVER}" | awk -vORS=', ' '{ print $1 }' | sed 's/, $/\n/'

SET_SSH_IN_THESE_SERVER=$(echo "${SLAVE_SERVER[@]}" | sed 's/ /\n/g' | sort -u)

echo -e "\nSetting ssh in following servers with $(echo ${MASTER_SERVER} | awk -vORS=', ' '{ print $1 }' | sed 's/, $/\n/') as master server"
echo "------------------------------------------------------"
echo "${SET_SSH_IN_THESE_SERVER}" | awk -vORS=', ' '{ print $1 }' | sed 's/, $/\n/'

for masternode in ${MASTER_SERVER}
do
    echo -e "\nCopying MASTER KEYS form ${masternode}"
    $(multipass exec ${masternode} -- sudo bash -c "ssh-keygen -q -t ed25519 -N '' <<< $'\ny' >/dev/null 2>&1")
    KEY=$(multipass exec ${masternode} -- sudo bash -c "cat /root/.ssh/id_ed25519.pub")
    for slavenode in ${SET_SSH_IN_THESE_SERVER}
    do
        echo -e "\nCopying SSH KEYS form ${masternode} --> ${slavenode}";
        $(multipass exec ${slavenode} -- sudo bash -c "cp /root/.ssh/authorized_keys /root/.ssh/authorized_keys.bak")
        $(multipass exec ${slavenode} -- sudo bash -c "cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak")
        $(multipass exec ${slavenode} -- sudo bash -c "echo ${KEY} >> /root/.ssh/authorized_keys")
        $(multipass exec ${slavenode} -- sudo bash -c "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin without-password/g' /etc/ssh/sshd_config")
        $(multipass exec ${slavenode} -- sudo bash -c "sed -i 's/#StrictModes yes/#StrictModes no/g' /etc/ssh/sshd_config")
        $(multipass exec ${slavenode} -- sudo bash -c "systemctl restart sshd")
    done
done
echo -e "\n updating host file of following servers"
echo "------------------------------------------------------"
HOST_ENTRIES=$(multipass list --format=csv | grep -E "$(echo "${MASTER_SERVER[@]} ${SLAVE_SERVER[@]}" | sed 's/ /\n/g' | sort -u | awk -vORS='|' '{ print $1 }' | sed 's/|$/\n/' )" | awk -F "," '{print $3" "$1".domain.com "$1}')
for server in $(echo "${MASTER_SERVER[@]} ${SLAVE_SERVER[@]}" | sed 's/ /\n/g' | sort -u) 
do
    $(multipass exec ${server} -- sudo bash -c "echo \"${HOST_ENTRIES}\" >> /etc/hosts")
    for host in $(echo "${MASTER_SERVER[@]} ${SLAVE_SERVER[@]}" | sed 's/ /\n/g' | sort -u) 
    do
        $(multipass exec ${server} -- sudo bash -c "ssh-keyscan ${host} >> /root/.ssh/known_hosts")
        $(multipass exec ${server} -- sudo bash -c "ssh-keyscan ${host}.domain.com >> /root/.ssh/known_hosts")
        ip=$(multipass list --format=csv | grep -E "${host}" | awk -F "," '{print $3}')
        $(multipass exec ${server} -- sudo bash -c "ssh-keyscan ${ip} >> /root/.ssh/known_hosts")
    done 
done 

echo "Step 1 — Installing Ansible"
for server in $(echo "${MASTER_SERVER[@]} ${SLAVE_SERVER[@]}" | sed 's/ /\n/g' | sort -u) 
do
    multipass exec ${server} -- sudo bash -c "apt update 2>/dev/null | apt upgrade -y 2>/dev/null"
done
for server in $(echo "${MASTER_SERVER[@]}" | sed 's/ /\n/g' | sort -u) 
do
    multipass exec ${server} -- sudo bash -c "apt-add-repository -y ppa:ansible/ansible"
    multipass exec ${server} -- sudo bash -c "apt update 2>/dev/null"
    multipass exec ${server} -- sudo bash -c "apt install ansible -y 2>/dev/null"
done
MASTER_HOST_ENTRIES=$(multipass list --format=csv | grep -E "$(echo "${MASTER_SERVER[@]}" | sed 's/ /\n/g' | sort -u | awk -vORS='|' '{ print $1 }' | sed 's/|$/\n/' )" | awk -F "," '{print $1" ansible_host="$3" ansible_user=root"}')
SLAVE_HOST_ENTRIES=$(multipass list --format=csv | grep -E "$(echo "${SLAVE_SERVER[@]}" | sed 's/ /\n/g' | sort -u | awk -vORS='|' '{ print $1 }' | sed 's/|$/\n/' )" | awk -F "," '{print $1" ansible_host="$3" ansible_user=root"}')
for server in $(echo "${MASTER_SERVER[@]}" | sed 's/ /\n/g' | sort -u) 
do

    multipass exec ${server} -- sudo bash -c "mkdir -p /etc/ansible"
    multipass exec ${server} -- sudo bash -c "cat /dev/null > /etc/ansible/hosts"
    multipass exec ${server} -- sudo bash -c "cat /dev/null > /etc/ansible/hosts"
    multipass exec ${server} -- sudo bash -c "echo -e \"[masters]\n${MASTER_HOST_ENTRIES}\" >> /etc/ansible/hosts"
    multipass exec ${server} -- sudo bash -c "echo -e \"[servers]\n${SLAVE_HOST_ENTRIES}\" >> /etc/ansible/hosts"
    multipass exec ${server} -- sudo bash -c "echo -e \"\n[all:vars]\nansible_python_interpreter=/usr/bin/python3\" >> /etc/ansible/hosts"
done 
for masternode in ${MASTER_SERVER}
do
    for slavenode in ${SLAVE_SERVER}
    do
        echo "setting up ssh to ${masternode} for ${slavenode}"
        $(multipass exec ${masternode} -- sudo bash -c "ssh root@${slavenode} -y ls -l")
    done
done