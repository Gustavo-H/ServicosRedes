#!/bin/bash

function valid_ip() {
    local ip=$1
    local stat=1
    
    if [ "$2" = "CIDR" ]; then
        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,2}$ ]]; then
            ip=$(echo "$ip" | sed -r 's/[/]+/./g')
            OIFS=$IFS
            IFS='.'
            ip=($ip)
            IFS=$OIFS
            [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
                && ${ip[2]} -le 255 && ${ip[3]} -le 255 && ${ip[4]} -le 32 ]]
            stat=$?
        fi
    elif [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function valid_parameter() {
    local errors=0
    dns2="null"
    if [ ${#3} = 2 ]; then
        valid_ip $2
        if [ $? = 1 ]; then
            echo "O valor: $2 nao eh um IP valido!"
            let errors++
        fi 
   
        if [ ! $3 -le 32 ]; then
            echo "O valor: $3 nao eh uma CIDR valida!"
            let errors++
        fi 
    
        valid_ip $4
        if [ $? = 1 ]; then
            echo "O valor: $4 nao eh um IP de Gateway valido!"
            let errors++
        fi 
        
        valid_ip $5
        if [ $? = 1 ]; then
            echo "O valor: $5 nao eh um IP de DNS valido!"
            let errors++
        fi

        if [ ${#6} -gt 0 ]; then
            valid_ip $6
            if [ $? = 1 ]; then
                if [ $errors = 0 ]; then
                    echo "O valor: $6 nao eh um IP de DNS valido! A insercao continuara sem DNS secundario!"
                else
                    echo "O valor: $6 nao eh um IP de DNS valido!"
                fi
            else
                dns2=$6
            fi
        fi

        if [ $errors = 0 ]; then
            ip=$2/$3
            gateway=$4
            dns1=$5
        fi

    else
        valid_ip $2 "CIDR"
        if [ $? = 1 ]; then
            echo "O valor: $2 nao eh um IP valido!"
            let errors++
        fi 

        valid_ip $3
        if [ $? = 1 ]; then
            echo "O valor: $3 nao eh um IP de Gateway valido!"
            let errors++
        fi 
        
        valid_ip $4
        if [ $? = 1 ]; then
            echo "O valor: $4 nao eh um IP de DNS valido!"
            let errors++
        fi

        if [ ${#5} -gt 0 ]; then
            valid_ip $5
            if [ $? = 1 ]; then
                if [ $errors = 0 ]; then
                    echo "O valor: $5 nao eh um IP de DNS valido! A insercao continuara sem DNS secundario!"
                else
                    echo "O valor: $5 nao eh um IP de DNS valido!"
                fi
            else
                dns2=$5
            fi       
        fi
        
        if [ $errors = 0 ]; then
            ip=$2
            gateway=$3
            dns1=$4
        fi
    fi
    return $errors
}

function get_interface_name() {
    local interfaces=$(nmcli --terse --fields DEVICE dev status)    
    IFS=' '
    read -ra interface_name <<< "$interfaces"
}

function insert_temp_config() {
    get_interface_name
            
    ip a add $ip dev $interface_name
    if [ $? = 0 ]; then
        ipResult="IP: $ip configurado com sucesso!"
    else
        ipResult="Erro ao configurar IP: $ip"
    fi
    
    ip route add default via $gateway dev $interface_name
    if [ $? = 0 ]; then
        gwResult="Gateway: $gateway configurado com sucesso!"
    else
        gwResult="Erro ao configurar Gateway: $gateway"
    fi

    if [ $dns2 = "null" ]; then 
        echo "nameserver $dns1" > /etc/resolv.conf
        if [ $? = 0 ]; then
            dns1Result="DNS Primario: $dns1 configurado com sucesso!"
        else
            dns1Result="Erro ao configurar DNS Primario: $dns1"
        fi
    else
        echo "nameserver $dns1" > /etc/resolv.conf
        if [ $? = 0 ]; then
            dns1Result="DNS Primario: $dns1 configurado com sucesso!"
        else
            dns1Result="Erro ao configurar DNS Primario: $dns1"
        fi
        
        echo "nameserver $dns2" >> /etc/resolv.conf
        if [ $? = 0 ]; then
            dns2Result="DNS Secundario: $dns2 configurado com sucesso!"
        else
            dns2Result="Erro ao configurar DNS Secundario: $dns1"
        fi                
    fi
}

function insert_persistent_config() {
    get_interface_name    
    
    #for file in /etc/netplan/*.yaml; do
        #mv $file $file.bkp
    #done
    touch /etc/netplan/config.yaml
    config_file="/etc/netplan/config.yaml"

    if [ $dns2 = "null" ]; then
        echo -e "network:" >> /etc/netplan/config.yaml
        echo -e "    version: 2" >> /etc/netplan/config.yaml
        echo -e "    ethernets:" >> /etc/netplan/config.yaml
        echo -e "        $interface_name:" >> /etc/netplan/config.yaml
        echo -e "            addresses: [$ip]" >> /etc/netplan/config.yaml
        echo -e "            dhcp4: false" >> /etc/netplan/config.yaml
        echo -e "            namesservers: [$dns1]" >> /etc/netplan/config.yaml      
    else
        echo  "network:" > /etc/netplan/config.yaml
        echo  "    version: 2" >> /etc/netplan/config.yaml
        echo  "    ethernets:" >> /etc/netplan/config.yaml
        echo  "        $interface_name:" >> /etc/netplan/config.yaml
        echo  "            addresses: [$ip]" >> /etc/netplan/config.yaml
        echo  "            dhcp4: false" >> /etc/netplan/config.yaml
        echo  "            nameservers: [$dns1,$dns2]" >> /etc/netplan/config.yaml
    fi

    cat $config_file
    netplan generate
    if [ ! $? = 0]; then
        echo "Ocorreu um erro ao tentar aplicar as alteracoes!"
    fi
    netplan apply
    if [ $? = 0]; then
        echo "Configuracoes aplicadas com sucesso!"
    else
        echo "Ocorreu um erro ao tentar aplicar as alteracoes!"
    fi
}


if [ ! $EUID -ne 0 ]; then

    if [ "$1" = "temporario" ]; then
        valid_parameter $1 $2 $3 $4 $5 $6
    
        if [ $? = 0 ]; then
            insert_temp_config
            echo $ipResult
            echo $gwResult
            echo $dns1Result

            if [ ! $dns2 = "null" ]; then
                echo $dns2Result
            fi
        fi 
    elif [ "$1" = "permanente" ]; then
        valid_parameter $1 $2 $3 $4 $5 $6
        if [ $? = 0 ]; then
            insert_persistent_config
        fi
    else
        echo "O valor: $1 nao eh uma opcao valida!"
    fi
else 
    echo $USERNAME "logue como administrador e tente novamente!"
fi


