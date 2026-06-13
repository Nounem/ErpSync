# Connecteur Generic REST

## Quand l'utiliser

Utilise `Generic REST` quand le client a une API HTTP/JSON simple: une URL de base, un endpoint, une methode HTTP et un payload JSON.

## Ce qu'il faut preparer cote API externe

- URL de base de l'API, par exemple `https://api.example.com`.
- Methode d'authentification: API key, Bearer token, Basic Auth ou OAuth.
- Endpoint cible, par exemple `/records`.
- Exemple de payload attendu par l'API.
- Champ externe qui permet d'identifier un record, si disponible.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential, par exemple `ErpSync_Generic`.
4. Mettre l'URL de base de l'API.
5. Configurer l'authentification.
6. Ne jamais coller le secret dans ErpSync.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Generic REST`.
4. Cliquer sur `Installer`.
5. Ouvrir le connecteur cree.
6. Verifier `Named Credential Name = ErpSync_Generic`.
7. Verifier le flux cree et remplacer `/records` par le vrai endpoint.

## Template conseille

| Champ ErpSync | Valeur de depart |
| --- | --- |
| Connector Type | `Generic REST` |
| Named Credential | `ErpSync_Generic` |
| Base URL | `https://api.example.com` |
| Salesforce Object | `Account` |
| External Object | `records` |
| Endpoint Path | `/records` |
| HTTP Method | `POST` |
| Payload Mode | `Envelope` |

## Endpoints de depart

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer un record | `POST` | `/records` |
| Lire un record | `GET` | `/records/{id}` |
| Modifier un record | `PATCH` ou `PUT` | `/records/{id}` |
| Supprimer un record | `DELETE` | `/records/{id}` |

## Mappings de depart

| Salesforce | Externe |
| --- | --- |
| `Name` | `name` |
| `Phone` | `phone` |
| `Website` | `website` |

## Points d'attention

- Si l'API attend directement les champs, utiliser `Raw Mapping`.
- Si l'API attend une racine comme `data` ou `customer`, utiliser `Root Key`.
- Si l'API attend du form-urlencoded ou XML, un adaptateur dedie sera plus propre.

