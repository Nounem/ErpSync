# Connecteur Zoho

## Objectif

Synchroniser des comptes Salesforce vers Zoho CRM. Le cas de depart est `Account` Salesforce vers le module `Accounts` Zoho.

## Ce qu'il faut preparer cote Zoho

- Un compte Zoho CRM.
- Une application OAuth Zoho.
- Le data center Zoho du client: US, EU, IN, AU, etc.
- Les API names des champs Zoho.
- Le module cible: `Accounts`, `Contacts`, `Deals`, etc.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `Zoho`.
4. URL de base selon le data center.
5. Pour US: `https://www.zohoapis.com`.
6. Pour EU: `https://www.zohoapis.eu`.
7. Configurer OAuth avec les scopes CRM necessaires.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Zoho`.
4. Cliquer sur `Installer`.
5. Ouvrir le systeme cree.
6. Adapter la `BaseUrl__c` au data center.
7. Ouvrir le flux et verifier le module.
8. Cliquer sur `Valider`.
9. Activer apres verification des champs obligatoires.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Zoho` |
| Named Credential | `Zoho` |
| Base URL | `https://www.zohoapis.com` |
| Salesforce Object | `Account` |
| External Object | `Accounts` |
| Endpoint Path | `/crm/v8/Accounts` |
| HTTP Method | `POST` |
| Payload Mode | `Root Key` |
| Payload Root Key | `data` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer des comptes | `POST` | `/crm/v8/Accounts` |
| Lire des comptes | `GET` | `/crm/v8/Accounts` |
| Lire un compte | `GET` | `/crm/v8/Accounts/{recordId}` |
| Modifier un compte | `PUT` | `/crm/v8/Accounts/{recordId}` |

## Mappings de depart

| Salesforce | Zoho |
| --- | --- |
| `Name` | `Account_Name` |
| `Phone` | `Phone` |
| `Website` | `Website` |

## Exemple de payload attendu

Avec `Payload Mode = Root Key` et `Payload Root Key = data`, ErpSync doit produire un corps proche de:

```json
{
  "data": [
    {
      "Account_Name": "Acme France",
      "Phone": "+33123456789",
      "Website": "https://www.acme.example"
    }
  ]
}
```

## Points d'attention

- Le champ obligatoire du module Accounts est `Account_Name`.
- Zoho utilise les noms API des champs, pas les libelles visibles.
- Si une ancienne installation contient `/crm/v6/Accounts`, passer sur `/crm/v8/Accounts` si l'org Zoho est compatible.
- Le format `data` est un tableau. Si la version actuelle d'ErpSync envoie un objet simple sous `data`, prevoir une evolution de payload pour le batch Zoho.

## Documentation officielle

- https://www.zoho.com/crm/developer/docs/api/v8/insert-records.html
