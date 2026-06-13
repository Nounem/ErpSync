# Connecteur PayPal

## Objectif

Preparer une synchro ou une action Salesforce vers PayPal. Le template de depart cible `merchant-integrations`, mais le vrai flux depend beaucoup du besoin client.

## Ce qu'il faut preparer cote PayPal

- Un compte PayPal Developer.
- Une application REST PayPal.
- Un environnement sandbox.
- Le `client id` et le `client secret`.
- Le endpoint PayPal exact selon le cas: paiement, partenaire, order, merchant onboarding, etc.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `PayPal`.
4. Pour sandbox: `https://api-m.sandbox.paypal.com`.
5. Pour production: `https://api-m.paypal.com`.
6. Configurer OAuth 2.0 dans Salesforce.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `PayPal`.
4. Cliquer sur `Installer`.
5. Ouvrir le systeme cree.
6. Choisir sandbox ou production.
7. Ouvrir le flux et remplacer l'endpoint si le besoin n'est pas merchant integration.
8. Cliquer sur `Valider`.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `PayPal` |
| Named Credential | `PayPal` |
| Base URL sandbox | `https://api-m.sandbox.paypal.com` |
| Base URL production | `https://api-m.paypal.com` |
| Salesforce Object | `Account` |
| External Object | `merchant-integrations` |
| Endpoint Path | `/v1/customer/partners/merchant-integrations` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Obtenir un token OAuth | `POST` | `/v1/oauth2/token` |
| Creer une commande | `POST` | `/v2/checkout/orders` |
| Lire une commande | `GET` | `/v2/checkout/orders/{id}` |
| Capturer une commande | `POST` | `/v2/checkout/orders/{id}/capture` |

## Mappings de depart

| Salesforce | PayPal |
| --- | --- |
| `Name` | `business_name` |
| `Phone` | `phone` |
| `Website` | `website` |

## Points d'attention

- PayPal a plusieurs domaines fonctionnels. Ne pas activer le template sans confirmer le cas d'usage.
- Distinguer clairement sandbox et production.
- Les paiements demandent des controles metier et une gestion d'etat plus riche qu'une simple synchro.

## Documentation officielle

- https://developer.paypal.com/api/rest/

