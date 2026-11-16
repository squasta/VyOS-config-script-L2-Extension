
# Structure

Placez toujours vos scripts dans /config/scripts/, car le répertoire /config est le seul à être automatiquement conservé lors des mises à jour d'image système (add system image).

/config/scripts/provisioning/
├── deploy.sh                  # Orchestrateur principal (exécutable)
└── modules/
    ├── 01-system.cfg          # Hostname, DNS, NTP, SSH, utilisateurs
    ├── 02-interfaces.cfg      # Interfaces physiques, VLANs, adresses IP
    ├── 03-nat.cfg             # Règles SNAT / DNAT
    ├── 04-firewall.cfg        # Groupes et règles de filtrage (nftables)
    └── 05-services.cfg        # Serveur DHCP, relais DNS, routage


# Script orchestrateur (deploy.sh)

Ce script ouvre une session CLI VyOS unique, charge chaque fichier .cfg par ordre alphabétique, valide l'ensemble des dépendances en une passe (commit), puis sauvegarde dans /config/config.boot (save).

Rendez le script exécutable :

```bash
chmod +x /config/scripts/provisioning/deploy.sh
```

# Modules de commandes set

Les fichiers .cfg contiennent uniquement des commandes set (et éventuellement delete pour l'idempotence) ainsi que des commentaires


# Points clés pour l'automatisation en production

## Idempotence lors des ré-exécutions : 
Dans VyOS, relancer une commande set déjà présente est sans effet (pas d'erreur).
 En revanche, si vous supprimez une entrée de votre fichier (par exemple un serveur DNS ou une règle de pare-feu), elle restera active sur le routeur tant que vous n'aurez pas exécuté un delete ciblé (comme delete system name-server avant de redéfinir la liste).
 
 ## Intégration Zero-Touch (Cloud-init / Ansible) :Cloud-init :
  - Vous pouvez cloner votre dépôt Git dans /config/scripts/provisioning/ via runcmd au premier démarrage et appeler ./deploy.sh (le script basculera automatiquement sur vyattacfg grâce à l'en-tête). 
  -  Ansible : La collection officielle vyos.vyos (vyos.vyos.vyos_config) permet également d'envoyer directement ces fichiers .cfg via le paramètre src: en gérant nativement les diffs et les sauvegardes.

  ## Extraction de l'existant :
   Pour transformer une configuration déjà en place sur un VyOS de test en fichiers modulaires, exécutez show configuration commands | match "^set firewall" (ou interfaces, nat, service) en mode opérationnel.
