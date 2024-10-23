#!/bin/bash

user_file='users.txt' # Fichier contenant les utilisateurs à ajouter
inactive_days=90  # Période d'inactivité définie (en jours)
backup_dir='/backup_users' # Dossier de sauvegarde des répertoires personnels
shared_dirs=("/shared/rh" "/shared/direction") # Répertoires partagés où appliquer les ACL


# Boucle pour ajouter des utilisateurs
while read line; do # Lire chaque ligne du fichier
    read -a array <<< "$line" # Convertir la ligne en tableau
    group_name=${array[1]} # Nom du groupe
    username=${array[0]} # Nom de l'utilisateur
    # Créer le groupe si inexistant
    if ! grep "^$group_name" /etc/group > /dev/null; then
        groupadd $group_name # Ajouter le groupe
        echo "Groupe $group_name créé."
    fi
    # Ajouter l'utilisateur si inexistant
    if ! grep "^$username" /etc/passwd > /dev/null; then
        useradd -m $username --groups $group_name # Ajouter l'utilisateur
        password=$(openssl rand -base64 12) # Générer un mot de passe temporaire
        echo "$username:$password" | chpasswd # Changer le mot de passe de l'utilisateur
        usermod -aG "$group_name" "$username" # Changer le groupe principal
        echo "L'utilisateur $username a été créé dans le groupe $group_name avec un mot de passe temporaire : $password"
    fi
    # L'utilisateur existe, vérifier s'il est dans le bon groupe
    if ! id -Gn "$username" | grep -qw "$group_name"; then
        usermod -aG "$group_name" "$username" # Ajouter l'utilisateur au groupe sans supprimer ses autres groupes
        echo "L'utilisateur $username a été ajouté au groupe $group_name."
    fi
done < "$user_file"

# Gestion des utilisateurs inactifs
echo -e "Vérification des utilisateurs inactifs depuis plus de $inactive_days jours\n"

# Utilisation de lastlog pour identifier les utilisateurs inactifs et awk pour extraire les noms d'utilisateurs
inactive_users=$(lastlog -b $inactive_days | awk 'NR>1 {print $1}')

for user in $inactive_users; do
        echo "L'utilisateur $user est inactif depuis plus de $inactive_days jours."
        
        # Demander à l'administrateur s'il veut verrouiller ou supprimer le compte
        echo "Souhaitez-vous verrouiller (v) ou supprimer (s) le compte $user ? (v/s/ignorer)"
        read -r choice

        if [ "$choice" == "v" ]; then
            usermod -L "$user" # Verrouiller le compte
            echo -e "Le compte $user a été verrouillé.\n"
        elif [ "$choice" == "s" ]; then
            # Vérifier si le répertoire de sauvegarde existe, sinon le créer
            if [ ! -d "$backup_dir" ]; then
                mkdir -p "$backup_dir"
            fi
            # Sauvegarde du répertoire personnel
            home_dir=$(getent passwd "$user" | cut -d: -f6) # Récupérer le répertoire personnel de l'utilisateur
            if [ -d "$home_dir" ]; then
                tar -czf "$backup_dir/${user}_home_backup.tar.gz" "$home_dir" # Créer une archive du répertoire personnel
                echo "Répertoire personnel de $user sauvegardé dans $backup_dir." 
            fi
            # Suppression de l'utilisateur
            userdel -r -f "$user" # Supprimer l'utilisateur et son répertoire personnel
            echo -e "Le compte $user a été supprimé.\n"
        else
            echo -e "Aucune action prise pour $user.\n"
        fi
done

echo -e "Gestion des utilisateurs inactifs terminée.\n"

# Suppression des groupes vides
for group in $(cut -d: -f1 /etc/group); do
    # Vérifier si le groupe est vide
    members=$(members "$group")
    exclusion_list=("root" "adm" "daemon" "bin" "sys" "sync" "games" "crontab" "backup" "src" "shadow" "utmp" "sasl" "staff" "admin" "nobody" "tty" "disk" "kmem" "fax" "voice" "tape" "operator" "input" "sgx" "kvm" "render" "_ssh" "")
    if [ -z "$members" ] && [[ ! " ${exclusion_list[@]} " =~ " ${group} " ]]; then
        groupdel "$group" # Supprimer le groupe s'il est vide
        echo "Le groupe $group est vide et a été supprimé."
    fi
done

# Gestion des permissions spécifiques via ACL
echo "Configuration des permissions ACL sur les répertoires partagés..."

for dir in "${shared_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" # Créer le répertoire s'il n'existe pas
        echo "Répertoire $dir créé."
    fi

    if [ "$dir" == "/shared/rh" ]; then
        # Permission de lecture seule pour le groupe RH
        setfacl -m g:rh:rwx "$dir" # Autoriser uniquement la lecture et l'exécution pour le groupe RH
        setfacl -d -m g:rh:rwx "$dir" # Appliquer cette règle par défaut aux nouveaux fichiers
        setfacl -m g:direction:rwx "$dir" # Autoriser la lecture, l'écriture et l'exécution pour le groupe direction
        setfacl -d -m g:direction:rwx "$dir" # Appliquer cette règle par défaut aux nouveaux fichiers
        echo "Permissions attribuées pour le répertoire $dir."
    elif [ "$dir" == "/shared/direction" ]; then
        # Permissions de lecture et écriture pour le groupe direction
        setfacl -m g:direction:rwx "$dir" # Autoriser la lecture, l'écriture et l'exécution pour le groupe direction
        setfacl -d -m g:direction:rwx "$dir" # Appliquer cette règle par défaut aux nouveaux fichiers
        echo "Permissions attribuées pour le répertoire $dir."
    fi
done

echo -e "Permissions ACL configurées.\n"