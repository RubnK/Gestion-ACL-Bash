#!/bin/bash

user_file='users.txt' # Fichier contenant les utilisateurs à ajouter
inactive_days=90  # Période d'inactivité définie (en jours)
backup_dir='/backup_users' # Dossier de sauvegarde des répertoires personnels

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

# Gestion des utilisateurs inactifs
echo -e "Vérification des utilisateurs inactifs depuis plus de $inactive_days jours\n"

# Utilisation de lastlog pour identifier les utilisateurs inactifs et awk pour extraire les noms d'utilisateurs
inactive_users=$(lastlog -b $inactive_days | awk 'NR>1 {print $1}')

for user in $inactive_users; do
        echo "L'utilisateur $user est inactif depuis plus de $inactive_days jours."
        
        # Demander à l'administrateur s'il veut verrouiller ou supprimer le compte
        echo "Souhaitez-vous verrouiller (l) ou supprimer (s) le compte $user ? (l/s/ignorer)"
        read -r choice

        if [ "$choice" == "l" ]; then
            usermod -L "$user" # Verrouiller le compte
            echo -e "Le compte $user a été verrouillé.\n"
        elif [ "$choice" == "s" ]; then
            # Sauvegarde du répertoire personnel
            home_dir=$(getent passwd "$user" | cut -d: -f6) # Récupérer le répertoire personnel de l'utilisateur
            if [ -d "$home_dir" ]; then
                tar -zczf "$backup_dir/${user}_home_backup.tar.gz" "$home_dir" # Créer une archive du répertoire personnel
                echo "Répertoire personnel de $user sauvegardé dans $backup_dir." 
            fi
            # Suppression de l'utilisateur
            userdel -r "$user"
            echo -e "Le compte $user a été supprimé.\n"
        else
            echo -e "Aucune action prise pour $user.\n"
        fi
done

echo "Gestion des utilisateurs inactifs terminée."