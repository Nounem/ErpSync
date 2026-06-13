# Connecteur QuickBooks

## Objectif

Synchroniser des comptes Salesforce vers les clients QuickBooks Online. Le cas de depart est `Account` Salesforce vers `Customer` QuickBooks.

## Ce qu'il faut preparer cote QuickBooks

- Un compte QuickBooks Online.
- Une application Intuit Developer.
- Le `Company ID` QuickBooks.
- Un environnement sandbox pour les tests.
- Les champs client obligatoires selon le dossier comptable.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `QuickBooks`.
4. URL de base: `https://quickbooks.api.intuit.com`.
5. Configurer OAuth 2.0 Intuit.
6. Ne pas mettre le `client secret` dans ErpSync.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `QuickBooks`.
4. Cliquer sur `Installer`.
5. Ouvrir le flux cree.
6. Remplacer `COMPANY_ID` par l'identifiant QuickBooks reel.
7. Verifier les mappings.
8. Cliquer sur `Valider`.
9. Activer le systeme puis le flux.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `QuickBooks` |
| Named Credential | `QuickBooks` |
| Base URL | `https://quickbooks.api.intuit.com` |
| Salesforce Object | `Account` |
| External Object | `Customer` |
| Endpoint Path | `/v3/company/COMPANY_ID/customer` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer un customer | `POST` | `/v3/company/{companyId}/customer` |
| Lire un customer | `GET` | `/v3/company/{companyId}/customer/{customerId}` |
| Modifier un customer | `POST` | `/v3/company/{companyId}/customer` |
| Requete SQL-like | `GET` | `/v3/company/{companyId}/query?query=select * from Customer` |

## Mappings de depart

| Salesforce | QuickBooks |
| --- | --- |
| `Name` | `DisplayName` |
| `Phone` | `PrimaryPhone.FreeFormNumber` |
| `Website` | `WebAddr.URI` |

## Exemple de payload attendu

```json
{
  "DisplayName": "Acme France",
  "PrimaryPhone": {
    "FreeFormNumber": "+33123456789"
  },
  "WebAddr": {
    "URI": "https://www.acme.example"
  }
}
```

## Points d'attention

- `COMPANY_ID` doit etre remplace avant activation.
- QuickBooks utilise parfois le parametre `minorversion`; le mettre dans l'endpoint si le client l'exige.
- Pour une mise a jour, QuickBooks demande souvent l'identifiant et le `SyncToken`.

## Documentation officielle

- https://developer.intuit.com/app/developer/qbo/docs/api/accounting/all-entities/customer

