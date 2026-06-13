# Connecteur Pipedrive

## Objectif

Synchroniser des comptes Salesforce vers les organisations Pipedrive. Le cas de depart est `Account` Salesforce vers `organizations` Pipedrive.

## Ce qu'il faut preparer cote Pipedrive

- Un compte Pipedrive.
- Une app OAuth ou un token API selon la politique client.
- La liste des champs organisation utiles.
- Les champs personnalises Pipedrive si necessaire.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `Pipedrive`.
4. URL de base: `https://api.pipedrive.com`.
5. Configurer OAuth ou un header/token gere par Salesforce.
6. Eviter les tokens dans l'URL.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Pipedrive`.
4. Cliquer sur `Installer`.
5. Ouvrir le flux cree.
6. Verifier l'endpoint.
7. Cliquer sur `Valider`.
8. Activer apres un test sur un seul compte.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Pipedrive` |
| Named Credential | `Pipedrive` |
| Base URL | `https://api.pipedrive.com` |
| Salesforce Object | `Account` |
| External Object | `organizations` |
| Endpoint Path | `/api/v2/organizations` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer une organisation | `POST` | `/api/v2/organizations` |
| Lire les organisations | `GET` | `/api/v2/organizations` |
| Lire une organisation | `GET` | `/api/v2/organizations/{id}` |
| Modifier une organisation | `PATCH` | `/api/v2/organizations/{id}` |

## Mappings de depart

| Salesforce | Pipedrive |
| --- | --- |
| `Name` | `name` |
| `Phone` | `phone` |
| `Website` | `website` |

## Exemple de payload attendu

```json
{
  "name": "Acme France",
  "phone": "+33123456789",
  "website": "https://www.acme.example"
}
```

## Points d'attention

- Si une ancienne installation contient `/v1/organizations`, remplacer par `/api/v2/organizations` pour suivre l'API actuelle.
- Les champs personnalises Pipedrive utilisent des cles techniques, pas toujours des noms lisibles.
- Pour relier une organisation a une personne ou a une affaire, creer un flux separe.

## Documentation officielle

- https://developers.pipedrive.com/docs/api/v1/Organizations
