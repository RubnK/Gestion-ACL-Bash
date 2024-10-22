#!/bin/bash

user_file='users.txt'

while read line; do
    read -a array <<< "$line"
    if ! grep "^${array[0]}" /etc/group > /dev/null; then
        addgroup ${array[1]}
    fi
    if ! grep "^${array[0]}" /etc/passwd > /dev/null; then
        useradd ${array[0]} --groups ${array[1]}
        password=$(openssl rand -base64 12)
        chpasswd ${array[0]}:$password
        echo "L'utilisateur ${array[0]} a été créé avec un mot de passe temporaire : $password"
    fi
done < "$user_file"
