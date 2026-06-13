# Connecteur Odoo

## Objectif

Preparer une synchro Salesforce vers Odoo. Le cas courant est `Account` Salesforce vers le modele Odoo `res.partner`.

## Ce qu'il faut preparer cote Odoo

- URL de l'instance Odoo.
- Nom de la base Odoo.
- Utilisateur technique.
- API key ou mot de passe technique selon la version.
- Mode API choisi: JSON-RPC, XML-RPC ou module REST installe.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `Odoo`.
4. URL de base: `https://odoo.example.com`.
5. Configurer l'auth selon le choix technique.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Odoo`.
4. Cliquer sur `Installer`.
5. Le template sert de cadrage mais le connecteur dedie reste a implementer.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Odoo` |
| Named Credential | `Odoo` |
| Base URL | `https://odoo.example.com` |
| Salesforce Object | `Account` |
| External Object | `res.partner` |
| Endpoint Path | `/jsonrpc` |
| HTTP Method | `POST` |
| Payload Mode | `Envelope` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| JSON-RPC general | `POST` | `/jsonrpc` |
| XML-RPC common | `POST` | `/xmlrpc/2/common` |
| XML-RPC object | `POST` | `/xmlrpc/2/object` |

## Mappings de depart

| Salesforce | Odoo |
| --- | --- |
| `Name` | `name` |
| `Phone` | `phone` |
| `Website` | `website` |

## Points d'attention

- Odoo n'est pas une API REST simple par defaut.
- Il faut souvent envoyer le modele, la methode et les args dans le payload.
- Pour une production, prevoir un adaptateur Odoo dedie.

## Documentation officielle

- https://www.odoo.com/documentation/18.0/developer/reference/external_api.html

