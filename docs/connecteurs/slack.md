# Connecteur Slack

## Objectif

Envoyer un message Slack depuis Salesforce. Le cas de depart est une notification vers `chat.postMessage`.

## Ce qu'il faut preparer cote Slack

- Un workspace Slack.
- Une Slack App.
- Un bot token.
- Le scope `chat:write`.
- L'identifiant du canal cible, par exemple `C0123456789`.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `Slack`.
4. URL de base: `https://slack.com/api`.
5. Ajouter le bot token dans Salesforce.
6. Ne pas mettre le token dans ErpSync.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Slack`.
4. Cliquer sur `Installer`.
5. Ouvrir le flux cree.
6. Remplacer les mappings pour obtenir au minimum `channel` et `text`.
7. Cliquer sur `Valider`.
8. Tester dans un canal de recette.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Slack` |
| Named Credential | `Slack` |
| Base URL | `https://slack.com/api` |
| Salesforce Object | `Account`, `Case` ou autre |
| External Object | `chat.postMessage` |
| Endpoint Path | `/chat.postMessage` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Envoyer un message | `POST` | `/chat.postMessage` |
| Lire les infos canal | `GET` | `/conversations.info` |
| Lister les canaux | `GET` | `/conversations.list` |

## Mappings de depart

| Salesforce | Slack |
| --- | --- |
| `Name` ou `Subject` | `text` |
| Champ fixe ou custom | `channel` |

## Exemple de payload attendu

```json
{
  "channel": "C0123456789",
  "text": "Nouveau compte Salesforce: Acme France"
}
```

## Points d'attention

- `channel` est obligatoire.
- Le template installe une base de travail, mais il faut ajouter le canal et composer le message.
- Tester dans un canal non critique avant production.
- Eviter d'envoyer des donnees personnelles sensibles dans Slack.

## Documentation officielle

- https://docs.slack.dev/reference/methods/chat.postMessage/

