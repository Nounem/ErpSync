# Connecteur Zendesk

## Objectif

Synchroniser des comptes Salesforce vers les organisations Zendesk. Le cas de depart est `Account` Salesforce vers `organizations` Zendesk.

## Ce qu'il faut preparer cote Zendesk

- Un sous-domaine Zendesk.
- Une app OAuth ou un API token.
- Les permissions pour creer/modifier les organizations.
- La liste des champs custom si le client en utilise.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `Zendesk`.
4. URL de base: `https://your-subdomain.zendesk.com/api/v2`.
5. Remplacer `your-subdomain`.
6. Configurer OAuth ou API token dans Salesforce.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Zendesk`.
4. Cliquer sur `Installer`.
5. Ouvrir le systeme cree.
6. Remplacer le sous-domaine.
7. Ouvrir le flux et verifier `/organizations.json`.
8. Cliquer sur `Valider`.
9. Activer apres test.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Zendesk` |
| Named Credential | `Zendesk` |
| Base URL | `https://your-subdomain.zendesk.com/api/v2` |
| Salesforce Object | `Account` |
| External Object | `organizations` |
| Endpoint Path | `/organizations.json` |
| HTTP Method | `POST` |
| Payload Mode | `Root Key` |
| Payload Root Key | `organization` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer une organization | `POST` | `/organizations.json` |
| Lire les organizations | `GET` | `/organizations.json` |
| Lire une organization | `GET` | `/organizations/{organization_id}.json` |
| Modifier une organization | `PUT` | `/organizations/{organization_id}.json` |

## Mappings de depart

| Salesforce | Zendesk |
| --- | --- |
| `Name` | `name` |
| `Phone` | `phone` |
| `Website` | `details` |

## Exemple de payload attendu

```json
{
  "organization": {
    "name": "Acme France",
    "phone": "+33123456789",
    "details": "https://www.acme.example"
  }
}
```

## Points d'attention

- Zendesk distingue les users, organizations et tickets. Creer un flux par objet.
- Les champs custom Zendesk utilisent des cles specifiques.
- Verifier les droits du token avant le test.

## Documentation officielle

- https://developer.zendesk.com/api-reference/ticketing/organizations/organizations/

