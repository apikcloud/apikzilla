# apikzilla

CLI pour gérer vos sauvegardes Odoo via Apikcloud.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/apikcloud/apikzilla/main/install.sh | bash
```

Fonctionne sur Linux et macOS (x86_64 et arm64). Relancez la même commande pour mettre à jour.

## Utilisation

```bash
# Lister les sauvegardes d'une instance
apikzilla list --token <TOKEN> --instance <INSTANCE>

# Télécharger la dernière sauvegarde
apikzilla download --token <TOKEN> --instance <INSTANCE>

# Télécharger une sauvegarde précise
apikzilla download --token <TOKEN> --instance <INSTANCE> --name <NOM>

# Envoyer une sauvegarde
apikzilla upload --token <TOKEN> --instance <INSTANCE> --file <FICHIER.zip>

# Vérifier l'intégrité d'une archive
apikzilla check --file <FICHIER.zip>
```

Votre `TOKEN` est disponible dans votre espace client Apikcloud.
