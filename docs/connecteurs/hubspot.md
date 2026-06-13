# Connecteur HubSpot

## Objectif

Synchroniser des contacts Salesforce vers HubSpot CRM. Le cas de depart est `Contact` Salesforce vers `contacts` HubSpot.

## Ce qu'il faut preparer cote HubSpot

- Une Private App ou une application OAuth.
- Un token avec les scopes CRM necessaires.
- Les proprietes HubSpot a alimenter: `email`, `firstname`, `lastname`, `phone`.
- La version d'API cible. Le template utilise l'endpoint CRM v3 stable et verifie.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `HubSpot`.
4. URL de base: `https://api.hubapi.com`.
5. Configurer le Bearer token ou OAuth.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `HubSpot`.
4. Cliquer sur `Installer`.
5. Ouvrir le flux cree.
6. Confirmer l'endpoint et les mappings.
7. Valider puis activer.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `HubSpot` |
| Named Credential | `HubSpot` |
| Base URL | `https://api.hubapi.com` |
| Salesforce Object | `Contact` |
| External Object | `contacts` |
| Endpoint Path | `/crm/v3/objects/contacts` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer un contact | `POST` | `/crm/v3/objects/contacts` |
| Lire un contact | `GET` | `/crm/v3/objects/contacts/{contactId}` |
| Modifier un contact | `PATCH` | `/crm/v3/objects/contacts/{contactId}` |
| Chercher des contacts | `POST` | `/crm/v3/objects/contacts/search` |

## Mappings de depart

| Salesforce | HubSpot |
| --- | --- |
| `Email` | `properties.email` |
| `FirstName` | `properties.firstname` |
| `LastName` | `properties.lastname` |
| `Phone` | `properties.phone` |

## Exemple de payload attendu

```json
{
  "properties": {
    "email": "ada@example.com",
    "firstname": "Ada",
    "lastname": "Lovelace"
  }
}
```

## Points d'attention

- Les associations HubSpot, par exemple contact vers company, demandent une configuration dediee.
- Verifier les scopes HubSpot avant d'activer le flux.
- HubSpot propose aussi des APIs date-versionnees, par exemple `2026-03`. Pour une premiere mise en service, garder le v3 stable sauf decision technique explicite.

## Documentation officielle

- https://developers.hubspot.com/docs/api-reference/legacy/crm/objects/contacts/create-contact
- https://developers.hubspot.com/docs/api-reference/latest/overview
