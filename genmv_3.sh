#!/bin/bash

RAM_MB=4096
DISK_GB=64
DISK_MB=$((DISK_GB * 1024))
OSTYPE="Debian_64"

ACTION="$1"
VM_NAME="$2"

if [ -z "$ACTION" ]; then
    echo "Erreur : Action manquante. Usage: $0 {L|N|S|D|A} [nom_vm]"
    exit 1
fi

case "$ACTION" in
    L)
        echo "=== Liste des VM enregistrées et métadonnées ==="
        VBoxManage list vms | while read -r line; do
            VM_PARSED=$(echo "$line" | cut -d '"' -f 2)
            
            DATE_CREA=$(VBoxManage getextradata "$VM_PARSED" "DateCreation" | awk -F': ' '{print $2}')
            USER_CREA=$(VBoxManage getextradata "$VM_PARSED" "Createur" | awk -F': ' '{print $2}')
            
            echo "Nom VM            : $VM_PARSED"
            echo "  Date de création : ${DATE_CREA:-"Non renseignée"}"
            echo "  Créateur         : ${USER_CREA:-"Non renseigné"}"
            echo "--------------------------------------------------"
        done
        ;;
    N)
        if [ -z "$VM_NAME" ]; then echo "Erreur : Nom de VM requis pour N"; exit 1; fi
        
        if VBoxManage showvminfo "$VM_NAME" >/dev/null 2>&1; then
            echo "Erreur : La VM '$VM_NAME' existe déjà."
            exit 1
        fi
        
        VBoxManage createvm --name "$VM_NAME" --ostype "$OSTYPE" --register
        VBoxManage modifyvm "$VM_NAME" --memory "$RAM_MB" --nic1 nat
        VBoxManage createmedium disk --filename "${VM_NAME}.vdi" --size "$DISK_MB" --format VDI
        VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci
        VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "${VM_NAME}.vdi"
        
        # Ajout des métadonnées
        VBoxManage setextradata "$VM_NAME" "DateCreation" "$(date '+%Y-%m-%d_%H:%M:%S')"
        VBoxManage setextradata "$VM_NAME" "Createur" "$USER"
        
        echo "VM '$VM_NAME' créée avec succès."
        ;;
    S)
        if [ -z "$VM_NAME" ]; then echo "Erreur : Nom de VM requis pour S"; exit 1; fi
        VBoxManage unregistervm "$VM_NAME" --delete
        ;;
    D)
        if [ -z "$VM_NAME" ]; then echo "Erreur : Nom de VM requis pour D"; exit 1; fi
        VBoxManage startvm "$VM_NAME"
        ;;
    A)
        if [ -z "$VM_NAME" ]; then echo "Erreur : Nom de VM requis pour A"; exit 1; fi
        VBoxManage controlvm "$VM_NAME" acpipowerbutton
        ;;
    *)
        echo "Action invalide. Utiliser L, N, S, D ou A."
        exit 1
        ;;
esac
