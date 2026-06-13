# Connecteur Xero

## Objectif

Synchroniser des comptes Salesforce vers les contacts Xero. Le cas de depart est `Account` Salesforce vers `Contacts` Xero.

## Ce qu'il faut preparer cote Xero

- Un compte Xero.
- Une application Xero Developer.
- Un tenant Xero connecte.
- Le `tenant id`.
- Les champs obligatoires pour les contacts.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `Xero`.
4. URL de base: `https://api.xero.com`.
5. Configurer OAuth 2.0.
6. Ajouter le header `xero-tenant-id` selon la configuration Salesforce retenue.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Xero`.
4. Cliquer sur `Installer`.
5. Ouvrir le systeme cree.
6. Verifier le Named Credential `Xero`.
7. Ouvrir le flux et verifier l'endpoint `/api.xro/2.0/Contacts`.
8. Cliquer sur `Valider`.
9. Activer apres un test sur un seul compte.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Xero` |
| Named Credential | `Xero` |
| Base URL | `https://api.xero.com` |
| Salesforce Object | `Account` |
| External Object | `Contacts` |
| Endpoint Path | `/api.xro/2.0/Contacts` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer ou modifier des contacts | `POST` | `/api.xro/2.0/Contacts` |
| Lire les contacts | `GET` | `/api.xro/2.0/Contacts` |
| Lire un contact | `GET` | `/api.xro/2.0/Contacts/{contactId}` |

## Mappings de depart

| Salesforce | Xero |
| --- | --- |
| `Name` | `Name` |
| `Phone` | `Phones.PhoneNumber` |
| `Website` | `Website` |

## Exemple de payload attendu

```json
{
  "Name": "Acme France",
  "Phones": {
    "PhoneNumber": "+33123456789"
  },
  "Website": "https://www.acme.example"
}
```

## Points d'attention

- Le header `xero-tenant-id` est indispensable.
- Xero peut accepter plusieurs contacts dans un meme payload selon le format utilise.
- Verifier les limites API Xero avant de planifier une synchro frequente.

## Documentation officielle

- https://developer.xero.com/documentation/api/accounting/contacts

