# Connecteur Freshdesk

## Objectif

Synchroniser des comptes Salesforce vers les companies Freshdesk. Le cas de depart est `Account` Salesforce vers `companies` Freshdesk.

## Ce qu'il faut preparer cote Freshdesk

- Un compte Freshdesk.
- Le domaine Freshdesk du client.
- Une API key ou une configuration OAuth.
- Les champs custom de company si necessaire.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `Freshdesk`.
4. URL de base: `https://your-domain.freshdesk.com/api/v2`.
5. Remplacer `your-domain`.
6. Stocker l'API key uniquement dans Salesforce.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Freshdesk`.
4. Cliquer sur `Installer`.
5. Ouvrir le systeme cree.
6. Remplacer le domaine exemple.
7. Ouvrir le flux et verifier `/companies`.
8. Cliquer sur `Valider`.
9. Activer apres test.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Freshdesk` |
| Named Credential | `Freshdesk` |
| Base URL | `https://your-domain.freshdesk.com/api/v2` |
| Salesforce Object | `Account` |
| External Object | `companies` |
| Endpoint Path | `/companies` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer une company | `POST` | `/companies` |
| Lire les companies | `GET` | `/companies` |
| Lire une company | `GET` | `/companies/{company_id}` |
| Modifier une company | `PUT` | `/companies/{company_id}` |
| Supprimer une company | `DELETE` | `/companies/{company_id}` |

## Mappings de depart

| Salesforce | Freshdesk |
| --- | --- |
| `Name` | `name` |
| `Phone` | `phone` |
| `Website` | `domains` |

## Exemple de payload attendu

```json
{
  "name": "Acme France",
  "phone": "+33123456789",
  "domains": ["acme.example"]
}
```

## Points d'attention

- `domains` peut etre une liste. Le template simple peut necessiter une adaptation si Freshdesk exige un tableau.
- Freshdesk gere aussi contacts et tickets; utiliser un flux separe pour chaque objet.
- Les champs custom doivent etre verifies dans l'admin Freshdesk.

## Documentation officielle

- https://developers.freshdesk.com/api/#companies

