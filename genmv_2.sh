#!/bin/bash
# genmv_2.sh - Version 2
# Le script est relançable :
#   - si Debian1 existe, elle est supprimée
#   - si un ancien fichier .vbox existe, il est également supprimé
#   - une nouvelle VM est créée sous le premier nom libre :
#     Debian1, Debian2, Debian3, ...

# ---- Paramètres ----
NOM="Debian1"
PREFIXE="Debian"
RAM=4096                         # 4096 Mo = 4 GiB
DISQUE=65536                     # 65536 Mo = 64 GiB
DOSSIER="${USERPROFILE:-$HOME}/VirtualBox VMs"

# Git Bash : ajouter VirtualBox au PATH
export PATH="$PATH:/c/Program Files/Oracle/VirtualBox"

# ---- Fonction d'erreur ----
erreur() {
    echo "ERREUR : $1" >&2
    exit 1
}

# ---- Vérifier si une VM existe ----
# Renvoie 0 si :
#   - la VM est enregistrée dans VirtualBox
#   - OU son fichier .vbox existe encore
existe() {
    VBoxManage showvminfo "$1" > /dev/null 2>&1 ||
    [ -f "$DOSSIER/$1/$1.vbox" ]
}

# ---- Supprimer une VM ----
supprimer_vm() {
    local nom="$1"

    # Si la VM est enregistrée dans VirtualBox
    if VBoxManage showvminfo "$nom" > /dev/null 2>&1; then

        echo "Suppression de la VM $nom..."

        # Arrêter la VM si elle fonctionne
        VBoxManage controlvm "$nom" poweroff > /dev/null 2>&1

        # Petite pause pour laisser VirtualBox terminer l'arrêt
        sleep 2

        # Désenregistrer la VM et supprimer ses fichiers
        VBoxManage unregistervm "$nom" --delete \
            || erreur "impossible de supprimer la VM $nom"

    # Sinon, si le dossier existe mais que la VM n'est pas enregistrée
    elif [ -d "$DOSSIER/$nom" ]; then

        echo "Suppression des fichiers résiduels de $nom..."

        rm -rf "$DOSSIER/$nom" \
            || erreur "impossible de supprimer les fichiers de $nom"
    fi
}

# ---- Vérification : VBoxManage est-il accessible ? ----
command -v VBoxManage > /dev/null \
    || erreur "VBoxManage introuvable, vérifiez le PATH"

# ---- Vérifier si Debian1 existe déjà ----
if existe "$NOM"; then

    echo "La VM $NOM existe déjà : suppression..."
    supprimer_vm "$NOM"

fi

# ---- Chercher un nom libre ----
# Si Debian1 vient d'être supprimée, on recrée Debian1.
# Si Debian1 existe encore pour une raison quelconque,
# on essaie Debian2, puis Debian3, etc.

if existe "$NOM"; then

    NUM=2

    while existe "${PREFIXE}${NUM}"; do
        NUM=$((NUM + 1))
    done

    NOM="${PREFIXE}${NUM}"

fi

echo "La nouvelle VM s'appellera $NOM."

# ---- Création et enregistrement de la VM ----
echo "Création de la VM $NOM..."

VBoxManage createvm \
    --name "$NOM" \
    --ostype Debian_64 \
    --basefolder "$DOSSIER" \
    --register \
    || erreur "échec de createvm"

# ---- RAM et carte réseau en NAT ----
echo "Configuration de la RAM et du réseau..."

VBoxManage modifyvm "$NOM" \
    --memory "$RAM" \
    --nic1 nat \
    || erreur "échec de modifyvm"

# ---- Création du disque dur virtuel ----
echo "Création du disque de 64 GiB..."

VBoxManage createmedium disk \
    --filename "$DOSSIER/$NOM/$NOM.vdi" \
    --size "$DISQUE" \
    || erreur "échec de createmedium"

# ---- Création du contrôleur SATA ----
echo "Création du contrôleur SATA..."

VBoxManage storagectl "$NOM" \
    --name "SATA" \
    --add sata \
    || erreur "échec de storagectl"

# ---- Rattachement du disque ----
echo "Rattachement du disque..."

VBoxManage storageattach "$NOM" \
    --storagectl "SATA" \
    --port 0 \
    --device 0 \
    --type hdd \
    --medium "$DOSSIER/$NOM/$NOM.vdi" \
    || erreur "échec de storageattach"

echo ""
echo "======================================"
echo "VM $NOM créée avec succès !"
echo "RAM     : $RAM Mo"
echo "Disque  : 64 GiB"
echo "Réseau  : NAT"
echo "======================================"
