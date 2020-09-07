#!/bin/bash

if [ -f "usuarios.txt" ]; then

    if [ ! $EUID -ne 0 ]; then
        usersFile="usuarios.txt"
        logFile="users.log"

        if [ ! -f "users.log" ]; then
            touch "users.log"
        else
            rm "users.log"
            touch "users.log"
        fi

        added=0
        removed=0

        while read line; do                
            IFS=':'            
            read -ra user <<< "$line"
            
            userName=${user[0]}
            userPwd=${user[1]}
            action=${user[2]}

            if [ "$action" = "adicionar" ]; then

                echo "" -e | useradd $userName 2>/dev/null
                
                if [ ! $? = 0 ]; then
                    logWrite="Erro - $(date '+%d/%m/%Y %T') - Nao foi possivel adicionar o usuario $userName"
                    echo -e $logWrite >> $logFile                 
                else
                    let added++                    
                fi
                echo -e "$userPwd\n$userPwd" | passwd $userName 2>/dev/null
                
            elif [ "$action" = "remover" ]; then
                
                echo "" -e | userdel $userName 2>/dev/null
                
                if [ ! $? = 0 ]; then
                    logWrite="Erro - $(date '+%d/%m/%Y %T') - Nao foi possivel remover o usuario $userName"
                    echo -e $logWrite >> $logFile
                else
                    let removed++                    
                fi
            fi
            
        done < $usersFile

        echo $added "Usuarios adicionados com sucesso!"
        echo $removed "Usuarios removidos com sucesso!"

    else 
        echo $USER "logue como administrador e tente novamente!"
    fi
else
    echo "Arquivo usuarios.txt inexistente a execucao foi encerrada!"
fi