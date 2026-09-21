# SAÉ 51 — Manuel d'utilisation : Automatisation VirtualBox

Auteurs : Mohamed & Evan URSULET
Dépôt GitHub : projet-vbox
Date : 21 septembre 2026

--------------------------------------------------

1. Description du projet & Répartition

Ce projet s'inscrit dans le cadre de la SAÉ 51. Il propose une suite progressive de 4 scripts Bash (genmv_1.sh à genmv_4.sh) permettant d'automatiser le cycle de vie de machines virtuelles Debian sous VirtualBox via l'outil VBoxManage.

Répartition des tâches dans le binôme :
- Evan URSULET : Développement des étapes 1 (genmv_1.sh) et 2 (genmv_2.sh).
- Mohamed : Développement des étapes 3 (genmv_3.sh) et 4 (genmv_4.sh), et rédaction de la documentation.

--------------------------------------------------

2. Évolution des scripts (Version par Version)

Étape 1 : genmv_1.sh
- Rôle : Script de base qui crée une VM, configure ses paramètres (RAM, disque VDI, interface NAT) et la supprime immédiatement après une pause de vérification.
- Syntaxe : ./genmv_1.sh

Étape 2 : genmv_2.sh
- Rôle : Introduction de la gestion par arguments (L, N, D, A, S) et contrôle anti-doublon à la création.
- Syntaxe : ./genmv_2.sh <ACTION> [NOM_VM]

Étape 3 : genmv_3.sh
- Rôle : Ajout de la gestion des métadonnées (injection de la date de création et de l'utilisateur créateur) et affichage détaillé lors du listing L.
- Syntaxe : ./genmv_3.sh <ACTION> [NOM_VM]

Étape 4 : genmv_4.sh (Version finale complète)
- Rôle : Intégration de la priorité de démarrage réseau PXE (--boot1 net) pour permettre l'automatisation du déploiement par le réseau.
- Syntaxe : ./genmv_4.sh <ACTION> [NOM_VM]

--------------------------------------------------

3. Guide des commandes (Script principal genmv_4.sh)

L'utilisation globale s'effectue avec la syntaxe :
./genmv_4.sh <ACTION> [NOM_VM]

Actions disponibles :

- L (Lister) : Affiche toutes les VM enregistrées ainsi que leurs métadonnées (date et créateur).
  Exemple : ./genmv_4.sh L

- N <nom> (Nouveau) : Crée une VM avec 4 Go RAM, 64 Go disque VDI, réseau NAT, boot PXE et sauvegarde des métadonnées.
  Exemple : ./genmv_4.sh N mon-serveur

- D <nom> (Démarrer) : Démarre la VM spécifiée.
  Exemple : ./genmv_4.sh D mon-serveur

- A <nom> (Arrêter) : Envoie un signal d'extinction propre (ACPI Power Button) à la VM.
  Exemple : ./genmv_4.sh A mon-serveur

- S <nom> (Supprimer) : Désenregistre et détruit définitivement la VM ainsi que ses fichiers .vdi.
  Exemple : ./genmv_4.sh S mon-serveur

--------------------------------------------------

4. Détails techniques & Sécurités

- Contrôle anti-doublon : Avant de créer une VM (action N), le script exécute "VBoxManage showvminfo". Si la VM existe déjà, la création s'arrête en affichant une erreur.
- Métadonnées : Lors de la création, la date (DateCreation) et l'utilisateur ($USER) sont enregistrés via "VBoxManage setextradata". L'action L extrait puis affiche ces informations.
- Boot Réseau (PXE) : Le paramètre "--boot1 net" force la VM à chercher un serveur d'installation sur le réseau NAT au démarrage avant de basculer sur le disque dur ("--boot2 disk").

--------------------------------------------------

5. Prérequis et contraintes

- Le chemin "C:\Program Files\Oracle\VirtualBox" doit être renseigné dans la variable PATH du terminal.
- Une VM en cours d'exécution ne peut pas être supprimée (action S). Il faut l'arrêter (action A) au préalable.
