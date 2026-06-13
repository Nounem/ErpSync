# Connecteur Jira

## Objectif

Creer des tickets Jira depuis Salesforce. Le cas de depart du template est `Account` Salesforce vers une `issue` Jira, mais en pratique on utilisera souvent `Case` Salesforce.

## Ce qu'il faut preparer cote Jira

- Un site Atlassian Cloud.
- Une app OAuth ou un API token.
- La cle projet Jira, par exemple `SUP`.
- Le type de ticket, par exemple `Task` ou `Bug`.
- Les champs obligatoires du projet.
- Les IDs des champs custom si necessaire.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `Jira`.
4. URL de base: `https://your-site.atlassian.net/rest/api/3`.
5. Remplacer `your-site`.
6. Configurer OAuth ou Basic/API token dans Salesforce.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Jira`.
4. Cliquer sur `Installer`.
5. Ouvrir le flux cree.
6. Remplacer ou completer les mappings `project` et `issuetype`.
7. Cliquer sur `Valider`.
8. Tester sur un enregistrement Salesforce de test.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Jira` |
| Named Credential | `Jira` |
| Base URL | `https://your-site.atlassian.net/rest/api/3` |
| Salesforce Object | `Account` ou `Case` |
| External Object | `issue` |
| Endpoint Path | `/issue` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer une issue | `POST` | `/issue` |
| Lire une issue | `GET` | `/issue/{issueIdOrKey}` |
| Modifier une issue | `PUT` | `/issue/{issueIdOrKey}` |
| Rechercher des issues | `GET` | `/search/jql` |

## Mappings de depart

| Salesforce | Jira |
| --- | --- |
| `Name` ou `Subject` | `fields.summary` |
| `Description` | `fields.description` |
| `Website` | `fields.customfield_website` |

## Exemple de payload attendu

Jira demande au minimum le projet, le type et le resume:

```json
{
  "fields": {
    "project": {
      "key": "SUP"
    },
    "issuetype": {
      "name": "Task"
    },
    "summary": "Demande client Acme France"
  }
}
```

## Points d'attention

- Le template ne connait pas la cle projet du client. Il faut l'ajouter avant activation.
- Jira Cloud utilise parfois le format Atlassian Document Format pour les descriptions riches.
- Pour un vrai support client, partir plutot de `Case` Salesforce que de `Account`.

## Documentation officielle

- https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/

