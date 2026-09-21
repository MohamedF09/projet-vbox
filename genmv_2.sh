#!/bin/bash
# genmv_2.sh - Version 2
# Par rapport à la v1 :
#   - plus de pause : le script est non-interactif
#   - le script est relançable : si la VM existe déjà, elle est supprimée,
#     puis une nouvelle VM est créée sous un autre nom libre
#     (Debian2, Debian3, ...) ; sinon la VM est créée sous le nom Debian1

# ---- Paramètres (faciles à modifier) ----
NOM="Debian1"                                   # nom de base
PREFIXE="Debian"                                # préfixe des noms de remplacement
RAM=4096                                        # en Mo
DISQUE=65536                                    # en Mo : 64 GiB = 64 x 1024
DOSSIER="${USERPROFILE:-$HOME}/VirtualBox VMs"  # dossier de base des VM

# Git Bash : ajouter VirtualBox au PATH (syntaxe /c/... pour C:\...)
export PATH="$PATH:/c/Program Files/Oracle/VirtualBox"

# ---- Fonction d'erreur : message + arrêt du script ----
erreur() {
    echo "ERREUR : $1" >&2
    exit 1
}

# existe <nom> : renvoie 0 si la VM est enregistrée dans VirtualBox
# (showvminfo renvoie 0 si la VM existe, une valeur non nulle sinon)
existe() {
    VBoxManage showvminfo "$1" > /dev/null 2>&1
}

# ---- Vérification : VBoxManage est-il accessible ? ----
command -v VBoxManage > /dev/null || erreur "VBoxManage introuvable, vérifiez le PATH"

# ---- Une VM du même nom existe-t-elle déjà ? ----
if existe "$NOM"; then
    echo "La VM $NOM existe déjà : suppression..."
    VBoxManage controlvm "$NOM" poweroff > /dev/null 2>&1   # au cas où elle tourne
    sleep 2
    VBoxManage unregistervm "$NOM" --delete \
        || erreur "impossible de supprimer l'ancienne VM $NOM"

    # On cherche un autre nom : Debian2, puis Debian3, ... jusqu'à un nom libre
    NUM=2
    while existe "${PREFIXE}${NUM}"; do
        NUM=$((NUM + 1))
    done
    NOM="${PREFIXE}${NUM}"
    echo "La nouvelle VM s'appellera $NOM."
fi

# ---- Création et enregistrement de la VM ----
echo "Création de la VM $NOM..."
VBoxManage createvm --name "$NOM" --ostype Debian_64 \
    --basefolder "$DOSSIER" --register \
    || erreur "échec de createvm"

# ---- RAM et carte réseau en NAT ----
VBoxManage modifyvm "$NOM" --memory "$RAM" --nic1 nat \
    || erreur "échec de modifyvm"

# ---- Disque dur virtuel ----
VBoxManage createmedium disk --filename "$DOSSIER/$NOM/$NOM.vdi" --size "$DISQUE" \
    || erreur "échec de createmedium"

# ---- Contrôleur SATA + rattachement du disque ----
VBoxManage storagectl "$NOM" --name "SATA" --add sata \
    || erreur "échec de storagectl"

VBoxManage storageattach "$NOM" --storagectl "SATA" \
    --port 0 --device 0 --type hdd --medium "$DOSSIER/$NOM/$NOM.vdi" \
    || erreur "échec de storageattach"

echo "VM $NOM créée."
