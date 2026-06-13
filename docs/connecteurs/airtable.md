# Connecteur Airtable

## Objectif

Synchroniser des comptes Salesforce vers une table Airtable. Le cas de depart est `Account` Salesforce vers des `records` Airtable.

## Niveau de compatibilite ErpSync

L'endpoint Airtable est correct, mais le create records officiel attend un tableau `records`. Le moteur `Generic REST` actuel ne fabrique pas encore ce tableau automatiquement. Garder donc ce template comme cadrage et prevoir un mode payload array ou un adaptateur Airtable avant activation.

## Ce qu'il faut preparer cote Airtable

- Un compte Airtable.
- Une base Airtable.
- Une table cible.
- Un personal access token.
- Le `BASE_ID`.
- Le `TABLE_ID` ou le nom encode de la table.
- Les colonnes Airtable exactes.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `Airtable`.
4. URL de base: `https://api.airtable.com/v0`.
5. Stocker le personal access token dans Salesforce.
6. Ne pas mettre le token dans ErpSync.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Airtable`.
4. Cliquer sur `Installer`.
5. Ouvrir le flux cree.
6. Remplacer `BASE_ID` et `TABLE_ID`.
7. Verifier les noms de colonnes.
8. Cliquer sur `Valider`.
9. Garder inactif tant que le payload `records[]` n'est pas gere.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Airtable` |
| Named Credential | `Airtable` |
| Base URL | `https://api.airtable.com/v0` |
| Salesforce Object | `Account` |
| External Object | `records` |
| Endpoint Path | `/BASE_ID/TABLE_ID` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` pour cadrage, puis payload array requis |
| Payload Root Key | Non applicable |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer un record | `POST` | `/{baseId}/{tableIdOrName}` |
| Lire les records | `GET` | `/{baseId}/{tableIdOrName}` |
| Lire un record | `GET` | `/{baseId}/{tableIdOrName}/{recordId}` |
| Modifier un record | `PATCH` | `/{baseId}/{tableIdOrName}/{recordId}` |

## Mappings de depart

| Salesforce | Airtable |
| --- | --- |
| `Name` | `fields.Name` |
| `Phone` | `fields.Phone` |
| `Website` | `fields.Website` |

## Exemple de payload attendu

```json
{
  "records": [
    {
      "fields": {
        "Name": "Acme France",
        "Phone": "+33123456789",
        "Website": "https://www.acme.example"
      }
    }
  ]
}
```

## Points d'attention

- Les noms de colonnes Airtable sont sensibles aux espaces et majuscules.
- Remplacer `BASE_ID` et `TABLE_ID` avant activation.
- Airtable utilise `records` comme tableau; cela demande un mode payload dedie ou un adaptateur.

## Documentation officielle

- https://airtable.com/developers/web/api/create-records
