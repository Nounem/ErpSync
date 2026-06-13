# Connecteur Other

## Objectif

Documenter un connecteur qui n'a pas encore de guide dedie. Ce fichier sert de modele pour tout ERP, CRM ou SaaS non liste.

## Ce qu'il faut preparer cote fournisseur

- Le nom exact du produit.
- La documentation API officielle.
- L'URL de base de l'API.
- Le type d'authentification: OAuth, API key, Basic, certificat, etc.
- Les endpoints a appeler.
- Les champs obligatoires.
- Les limites API.
- Un environnement sandbox si disponible.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential avec un nom court, par exemple `VendorAPI`.
4. Mettre l'URL de base du fournisseur.
5. Configurer OAuth, API key ou Basic selon la documentation.
6. Ne pas mettre de secret dans ErpSync.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Generic REST` ou `Other`.
4. Cliquer sur `Installer`.
5. Ouvrir le systeme cree.
6. Remplacer le Named Credential, l'URL et le type connecteur.
7. Ouvrir le flux et saisir l'endpoint exact.
8. Creer les mappings.
9. Cliquer sur `Valider`.
10. Activer apres un test sur un seul record.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Other` ou `Generic REST` |
| Named Credential | `VendorAPI` |
| Base URL | `https://api.vendor.com` |
| Salesforce Object | `Account` ou `Contact` |
| External Object | `records` |
| Endpoint Path | `/records` |
| HTTP Method | `POST` |
| Payload Mode | `Envelope`, `Raw Mapping` ou `Root Key` |

## Comment choisir le Payload Mode

| Cas | Mode conseille |
| --- | --- |
| L'API attend directement les champs | `Raw Mapping` |
| L'API attend un objet racine simple, comme `customer` | `Root Key` |
| L'API attend un format ErpSync standard avec metadata | `Envelope` |

## Questions a poser au client

- Quel objet Salesforce doit partir vers l'outil externe ?
- Quel objet externe doit etre cree ou mis a jour ?
- Quelle est la cle d'unicite ?
- Faut-il creer, mettre a jour, ou faire un upsert ?
- Que faire en cas de conflit ?
- Quel volume quotidien est attendu ?
- Qui recoit les erreurs ?

## Exemple de fiche connecteur a remplir

```text
Nom fournisseur:
Documentation API:
Base URL sandbox:
Base URL production:
Auth:
Named Credential Salesforce:
Endpoint creation:
Endpoint mise a jour:
Objet Salesforce:
Objet externe:
Champs obligatoires:
Limites API:
Owner fonctionnel:
Owner technique:
```

## Points d'attention

- Si l'API n'est pas JSON REST simple, prevoir un adaptateur dedie.
- Si l'API demande des tableaux complexes, un format XML, SOAP, CSV ou form-urlencoded, ne pas promettre une activation directe via `Generic REST`.
- Toujours documenter les decisions dans le guide du connecteur avant la mise en production.

