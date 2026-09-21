#!/bin/bash
# genmv_1.sh - Version 1
# Crée une VM Debian1 (Debian 64 bits, 4096 Mo de RAM, disque 64 GiB, NAT),
# fait une pause pour vérification dans la GUI, puis détruit la VM.

# ---- Paramètres (faciles à modifier) ----
NOM="Debian1"
RAM=4096                          # en Mo
DISQUE=65536                      # en Mo : 64 GiB = 64 x 1024
DOSSIER="$USERPROFILE/VirtualBox VMs"   # dossier de base des VM (défaut sous Windows)

# Git Bash : ajouter VirtualBox au PATH (syntaxe /c/... pour C:\...)
export PATH="$PATH:/c/Program Files/Oracle/VirtualBox"

# ---- Fonction d'erreur : message + arrêt du script ----
erreur() {
    echo "ERREUR : $1" >&2
    exit 1
}

# ---- Vérification : VBoxManage est-il accessible ? ----
command -v VBoxManage > /dev/null || erreur "VBoxManage introuvable, vérifiez le PATH"

# ---- 1. Création et enregistrement de la VM ----
echo "Création de la VM $NOM..."
VBoxManage createvm --name "$NOM" --ostype Debian_64 \
    --basefolder "$DOSSIER" --register \
    || erreur "échec de createvm"

# ---- 2. RAM et carte réseau en NAT ----
VBoxManage modifyvm "$NOM" --memory "$RAM" --nic1 nat \
    || erreur "échec de modifyvm"

# ---- 3. Disque dur virtuel ----
VBoxManage createmedium disk --filename "$DOSSIER/$NOM/$NOM.vdi" --size "$DISQUE" \
    || erreur "échec de createmedium"

# ---- 4. Contrôleur SATA + rattachement du disque ----
VBoxManage storagectl "$NOM" --name "SATA" --add sata \
    || erreur "échec de storagectl"

VBoxManage storageattach "$NOM" --storagectl "SATA" \
    --port 0 --device 0 --type hdd --medium "$DOSSIER/$NOM/$NOM.vdi" \
    || erreur "échec de storageattach"

echo "VM $NOM créée."

# ---- Pause : vérifier dans la GUI de VirtualBox ----
read -p "Vérifiez la VM dans la GUI, puis appuyez sur Entrée pour la détruire..."

# ---- 5. Destruction (désenregistrement + suppression des fichiers) ----
VBoxManage unregistervm "$NOM" --delete \
    || erreur "échec de unregistervm"

echo "VM $NOM supprimée."
