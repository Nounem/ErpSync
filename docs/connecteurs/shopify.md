# Connecteur Shopify

## Objectif

Synchroniser des contacts Salesforce vers les clients Shopify. Le cas de depart est `Contact` Salesforce vers `customers` Shopify.

## Ce qu'il faut preparer cote Shopify

- Une boutique Shopify.
- Une app admin Shopify.
- Un admin access token.
- Le nom de domaine boutique: `your-shop.myshopify.com`.
- Les scopes necessaires pour lire ou ecrire les clients.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `Shopify`.
4. URL de base: `https://your-shop.myshopify.com/admin/api/2026-01`.
5. Remplacer `your-shop` par le nom de la boutique.
6. Ajouter le token admin dans Salesforce, pas dans ErpSync.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Shopify`.
4. Cliquer sur `Installer`.
5. Ouvrir le systeme cree.
6. Remplacer la boutique exemple.
7. Ouvrir le flux et verifier `/customers.json`.
8. Cliquer sur `Valider`.
9. Activer apres un test sur un contact de test.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Shopify` |
| Named Credential | `Shopify` |
| Base URL | `https://your-shop.myshopify.com/admin/api/2026-01` |
| Salesforce Object | `Contact` |
| External Object | `customers` |
| Endpoint Path | `/customers.json` |
| HTTP Method | `POST` |
| Payload Mode | `Root Key` |
| Payload Root Key | `customer` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer un client | `POST` | `/customers.json` |
| Lire les clients | `GET` | `/customers.json` |
| Lire un client | `GET` | `/customers/{customer_id}.json` |
| Modifier un client | `PUT` | `/customers/{customer_id}.json` |

## Mappings de depart

| Salesforce | Shopify |
| --- | --- |
| `Email` | `email` |
| `FirstName` | `first_name` |
| `LastName` | `last_name` |
| `Phone` | `phone` |

## Exemple de payload attendu

```json
{
  "customer": {
    "email": "ada@example.com",
    "first_name": "Ada",
    "last_name": "Lovelace",
    "phone": "+33123456789"
  }
}
```

## Points d'attention

- Shopify REST Admin est legacy pour certaines nouvelles apps; GraphQL Admin est souvent recommande pour les nouveaux projets.
- Verifier les scopes avant le premier test.
- Ne jamais utiliser une boutique de production pour les premiers essais.

## Documentation officielle

- https://shopify.dev/docs/api/admin-rest/latest/resources/customer

