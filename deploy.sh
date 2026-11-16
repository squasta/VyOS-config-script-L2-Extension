#!/bin/vbash

# Sécurité critique VyOS : bascule automatiquement sur le groupe 'vyattacfg'.
# Lancer un script de config en tant que root (via sudo ou systemd) sans ce groupe
# corrompt les permissions actives et bloque toute modification manuelle future ("Set failed").
if [ "$(id -g -n)" != 'vyattacfg' ] ; then
    exec sg vyattacfg -c "/bin/vbash $(readlink -f "$0") $*"
fi

# Note : récupérer d'éventuels arguments ($1, $2...) AVANT de sourcer script-template,
# car ce fichier écrase les variables positionnelles.
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
MODULES_DIR="${SCRIPT_DIR}/modules"

# Chargement des fonctions CLI internes de VyOS
source /opt/vyatta/etc/functions/script-template

echo "=== Démarrage du déploiement de la configuration VyOS ==="
configure

# Sourçage séquentiel des modules de commandes 'set'
for module in "${MODULES_DIR}"/*.cfg; do
    if [ -f "$module" ]; then
        echo "-> Chargement du module : $(basename "$module")"
        source "$module"
    fi
done

echo "-> Validation et application (commit)..."
commit

if [ $? -eq 0 ]; then
    echo "-> Sauvegarde dans /config/config.boot (save)..."
    save
    exit
    echo "=== Déploiement terminé avec succès ==="
else
    echo "ERREUR : Le commit a échoué. Annulation des modifications (discard)."
    discard
    exit 1
fi