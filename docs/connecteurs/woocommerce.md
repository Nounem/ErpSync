# Connecteur WooCommerce

## Objectif

Synchroniser des contacts Salesforce vers les clients WooCommerce. Le cas de depart est `Contact` Salesforce vers `customers` WooCommerce.

## Ce qu'il faut preparer cote WooCommerce

- Un site WordPress avec WooCommerce.
- Une cle `Consumer Key`.
- Un secret `Consumer Secret`.
- L'URL publique du site.
- Le HTTPS actif.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `WooCommerce`.
4. URL de base: `https://your-store.example.com/wp-json/wc/v3`.
5. Configurer l'authentification avec la consumer key et le consumer secret.
6. Ne pas stocker ces valeurs dans ErpSync.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `WooCommerce`.
4. Cliquer sur `Installer`.
5. Ouvrir le systeme cree.
6. Remplacer le domaine exemple par le domaine du client.
7. Ouvrir le flux et verifier `/customers`.
8. Cliquer sur `Valider`.
9. Activer apres test.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `WooCommerce` |
| Named Credential | `WooCommerce` |
| Base URL | `https://your-store.example.com/wp-json/wc/v3` |
| Salesforce Object | `Contact` |
| External Object | `customers` |
| Endpoint Path | `/customers` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer un client | `POST` | `/customers` |
| Lire les clients | `GET` | `/customers` |
| Lire un client | `GET` | `/customers/{id}` |
| Modifier un client | `PUT` | `/customers/{id}` |
| Supprimer un client | `DELETE` | `/customers/{id}` |

## Mappings de depart

| Salesforce | WooCommerce |
| --- | --- |
| `Email` | `email` |
| `FirstName` | `first_name` |
| `LastName` | `last_name` |
| `Phone` | `billing.phone` |

## Exemple de payload attendu

```json
{
  "email": "ada@example.com",
  "first_name": "Ada",
  "last_name": "Lovelace",
  "billing": {
    "phone": "+33123456789"
  }
}
```

## Points d'attention

- Le site doit etre accessible par Salesforce.
- Certains plugins de securite WordPress peuvent bloquer les appels API.
- Verifier si le client veut creer des clients, des commandes ou seulement mettre a jour les donnees existantes.

## Documentation officielle

- https://woocommerce.github.io/woocommerce-rest-api-docs/#customers

