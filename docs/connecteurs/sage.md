# Connecteur Sage

## Objectif

Preparer une synchro Salesforce vers Sage Accounting. Le cas de depart est `Account` Salesforce vers `contacts` Sage.

## Ce qu'il faut preparer cote Sage

- Un compte Sage Business Cloud Accounting.
- Une application developpeur Sage.
- Un acces OAuth autorise pour la societe cible.
- La liste des champs obligatoires selon le type de contact.
- Le choix du produit Sage exact: Accounting, X3, 100, Intacct, etc.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `Sage`.
4. URL de base: `https://api.accounting.sage.com`.
5. Configurer OAuth avec les scopes demandes par Sage Accounting.
6. Ne pas mettre le client secret ou les tokens dans ErpSync.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Sage`.
4. Cliquer sur `Installer`.
5. Ouvrir le systeme cree.
6. Verifier `NamedCredentialName__c = Sage`.
7. Ouvrir le flux cree et verifier l'endpoint.
8. Cliquer sur `Valider`.
9. Activer seulement apres un test sur un compte Salesforce simple.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Sage` |
| Named Credential | `Sage` |
| Base URL | `https://api.accounting.sage.com` |
| Salesforce Object | `Account` |
| External Object | `contacts` |
| Endpoint Path | `/v3.1/contacts` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer un contact | `POST` | `/v3.1/contacts` |
| Lire les contacts | `GET` | `/v3.1/contacts` |
| Lire un contact | `GET` | `/v3.1/contacts/{contact_id}` |
| Modifier un contact | `PUT` | `/v3.1/contacts/{contact_id}` |

## Mappings de depart

| Salesforce | Sage |
| --- | --- |
| `Name` | `name` |
| `Phone` | `telephone` |
| `Website` | `website` |

## Exemple de payload attendu

```json
{
  "name": "Acme France",
  "telephone": "+33123456789",
  "website": "https://www.acme.example"
}
```

## Points d'attention

- Sage a plusieurs produits avec des APIs differentes. Ne pas reutiliser ce guide pour Sage X3 ou Sage Intacct sans cadrage.
- Selon la configuration Sage, le type de contact et l'adresse peuvent etre obligatoires.
- Le connecteur est marque `Adapter planned` dans le catalogue: utiliser ce template pour cadrer, puis prevoir un adaptateur dedie si le client a des regles comptables.

## Documentation officielle

- https://developer.sage.com/accounting/reference/contacts

