# Connecteur Oracle NetSuite

## Objectif

Preparer une synchro Salesforce vers NetSuite. Le cas de depart est `Account` Salesforce vers `customer` NetSuite.

## Ce qu'il faut preparer cote NetSuite

- Account ID NetSuite.
- REST Web Services active.
- Integration record NetSuite.
- Role et permissions pour customer.
- OAuth 2.0 ou token based auth selon la politique client.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Creer un Named Credential nomme `NetSuite`.
3. URL de base: `https://account.suitetalk.api.netsuite.com`.
4. Remplacer `account` par l'account id NetSuite reel.
5. Configurer OAuth ou token based auth.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Oracle NetSuite`.
4. Cliquer sur `Installer`.
5. Remplacer l'URL exemple et verifier les mappings.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Oracle NetSuite` |
| Named Credential | `NetSuite` |
| Base URL | `https://account.suitetalk.api.netsuite.com` |
| Salesforce Object | `Account` |
| External Object | `customer` |
| Endpoint Path | `/services/rest/record/v1/customer` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer customer | `POST` | `/services/rest/record/v1/customer` |
| Lire customer | `GET` | `/services/rest/record/v1/customer/{id}` |
| Modifier customer | `PATCH` | `/services/rest/record/v1/customer/{id}` |
| Supprimer customer | `DELETE` | `/services/rest/record/v1/customer/{id}` |

## Mappings de depart

| Salesforce | NetSuite |
| --- | --- |
| `Name` | `companyName` |
| `Phone` | `phone` |
| `Website` | `url` |

## Points d'attention

- Les champs obligatoires dependent du formulaire NetSuite et des preferences client.
- Les limites de gouvernance NetSuite doivent etre suivies.
- Prevoir un adaptateur dedie pour les relations, subsidiaries et custom records.

## Documentation officielle

- https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/chapter_1540391670.html

