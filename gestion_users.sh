#!/bin/bash

user_file='users.txt' # Fichier contenant les utilisateurs à ajouter

# Boucle pour ajouter des utilisateurs
while read line; do # Lire chaque ligne du fichier
    read -a array <<< "$line" # Convertir la ligne en tableau
    if ! grep "^${array[0]}" /etc/group > /dev/null; then
        addgroup ${array[1]} # Ajouter le groupe si inexistant
    fi
    if ! grep "^${array[0]}" /etc/passwd > /dev/null; then
        useradd ${array[0]} --groups ${array[1]} # Ajouter l'utilisateur si inexistant
        password=$(openssl rand -base64 12) # Générer un mot de passe temporaire
        chpasswd ${array[0]}:$password # Changer le mot de passe de l'utilisateur
        echo "L'utilisateur ${array[0]} a été créé avec un mot de passe temporaire : $password"
    fi
done < "$user_file"
