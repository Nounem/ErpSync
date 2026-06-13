# Connecteur Stripe

## Objectif

Preparer une synchro Salesforce vers les clients Stripe. Le cas de depart est `Account` Salesforce vers `customers` Stripe.

## Ce qu'il faut preparer cote Stripe

- Un compte Stripe.
- Une API key de test.
- Une API key de production separee.
- La decision sur l'objet source Salesforce: `Account` ou `Contact`.
- Les champs metadata utiles.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `Stripe`.
4. URL de base: `https://api.stripe.com`.
5. Configurer l'API key dans Salesforce.
6. Ne jamais mettre l'API key Stripe dans ErpSync.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Stripe`.
4. Cliquer sur `Installer`.
5. Ouvrir le flux cree.
6. Verifier l'endpoint `/v1/customers`.
7. Garder le flux inactif tant que le mode payload Stripe n'est pas valide.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Stripe` |
| Named Credential | `Stripe` |
| Base URL | `https://api.stripe.com` |
| Salesforce Object | `Account` |
| External Object | `customers` |
| Endpoint Path | `/v1/customers` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer un customer | `POST` | `/v1/customers` |
| Lire les customers | `GET` | `/v1/customers` |
| Lire un customer | `GET` | `/v1/customers/{id}` |
| Modifier un customer | `POST` | `/v1/customers/{id}` |
| Supprimer un customer | `DELETE` | `/v1/customers/{id}` |

## Mappings de depart

| Salesforce | Stripe |
| --- | --- |
| `Name` | `name` |
| `Phone` | `phone` |
| `Website` | `metadata.website` |

## Exemple de payload attendu

Stripe attend souvent un corps `application/x-www-form-urlencoded`, par exemple:

```text
name=Acme%20France&phone=%2B33123456789&metadata[website]=https%3A%2F%2Fwww.acme.example
```

## Points d'attention

- Stripe n'est pas un simple JSON REST pour la creation de customer.
- Le template sert de cadrage, mais un adaptateur dedie Stripe est recommande avant production.
- Toujours tester avec les API keys de test.
- Ne jamais synchroniser des donnees de carte bancaire dans ErpSync.

## Documentation officielle

- https://docs.stripe.com/api/customers/create

