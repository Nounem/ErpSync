# Connecteur Business Central

## Objectif

Synchroniser des comptes Salesforce vers Business Central. Le cas de depart est `Account` vers `companies` ou `customers` selon le besoin client.

## Ce qu'il faut preparer cote Business Central

- Tenant Microsoft.
- Environnement: sandbox ou production.
- Company Business Central cible.
- Application Entra ID pour OAuth.
- Objet API cible: customers, vendors, items, salesOrders, etc.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Creer l'External Credential OAuth Microsoft.
3. Creer un Named Credential nomme `BusinessCentral`.
4. URL de base: `https://api.businesscentral.dynamics.com`.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Business Central`.
4. Cliquer sur `Installer`.
5. Remplacer l'endpoint avec le tenant, l'environnement et la company.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Business Central` |
| Named Credential | `BusinessCentral` |
| Base URL | `https://api.businesscentral.dynamics.com` |
| Salesforce Object | `Account` |
| External Object | `companies` |
| Endpoint Path | `/v2.0/production/api/v2.0/companies` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Lister companies | `GET` | `/v2.0/{environment}/api/v2.0/companies` |
| Creer customer | `POST` | `/v2.0/{environment}/api/v2.0/companies({companyId})/customers` |
| Lire customer | `GET` | `/v2.0/{environment}/api/v2.0/companies({companyId})/customers({customerId})` |
| Modifier customer | `PATCH` | `/v2.0/{environment}/api/v2.0/companies({companyId})/customers({customerId})` |

## Mappings de depart

| Salesforce | Business Central |
| --- | --- |
| `Name` | `displayName` |
| `Phone` | `phoneNumber` |
| `Website` | `website` |

## Points d'attention

- Le template doit etre adapte avec le vrai `companyId`.
- Certains updates Business Central demandent un header ETag.
- Prevoir un flux par company si le client a plusieurs societes.

## Documentation officielle

- https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/api-reference/v2.0/

