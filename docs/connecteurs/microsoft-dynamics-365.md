# Connecteur Microsoft Dynamics 365

## Objectif

Preparer une synchro Salesforce vers Dynamics 365 / Dataverse. Le cas de depart est `Account` Salesforce vers `accounts` Dataverse.

## Ce qu'il faut preparer cote Microsoft

- URL de l'environnement, par exemple `https://your-org.crm.dynamics.com`.
- Application Entra ID pour OAuth.
- Client ID, secret/certificat et permissions Dataverse.
- Table cible, par exemple `accounts`.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Creer un External Credential OAuth si possible.
3. Creer un Named Credential nomme `Dynamics365`.
4. URL de base: `https://your-org.crm.dynamics.com`.
5. Lier l'auth OAuth au Named Credential.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Microsoft Dynamics 365`.
4. Cliquer sur `Installer`.
5. Remplacer l'URL exemple par l'URL client.
6. Verifier le flux et les mappings.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Microsoft Dynamics 365` |
| Named Credential | `Dynamics365` |
| Base URL | `https://your-org.crm.dynamics.com` |
| Salesforce Object | `Account` |
| External Object | `accounts` |
| Endpoint Path | `/api/data/v9.2/accounts` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer un account | `POST` | `/api/data/v9.2/accounts` |
| Lire un account | `GET` | `/api/data/v9.2/accounts({id})` |
| Modifier un account | `PATCH` | `/api/data/v9.2/accounts({id})` |
| Supprimer un account | `DELETE` | `/api/data/v9.2/accounts({id})` |

## Mappings de depart

| Salesforce | Dynamics |
| --- | --- |
| `Name` | `name` |
| `Phone` | `telephone1` |
| `Website` | `websiteurl` |

## Points d'attention

- Dynamics utilise OData: les relations et upserts peuvent necessiter un adaptateur dedie.
- Verifier les noms logiques des tables et champs dans Dataverse.
- Tester d'abord sur sandbox.

## Documentation officielle

- https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/overview

