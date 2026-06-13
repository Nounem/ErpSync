# Connecteur Notion

## Objectif

Creer des pages Notion depuis Salesforce. Le cas de depart est `Account` Salesforce vers `pages` Notion.

## Ce qu'il faut preparer cote Notion

- Un workspace Notion.
- Une integration Notion.
- Un token d'integration.
- Une database cible.
- Le `database_id`.
- Les proprietes exactes de la database: `Name`, `Phone`, `Website`, etc.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `Notion`.
4. URL de base: `https://api.notion.com/v1`.
5. Ajouter le token d'integration dans Salesforce.
6. Ajouter le header `Notion-Version`.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Notion`.
4. Cliquer sur `Installer`.
5. Ouvrir le flux cree.
6. Ajouter le `parent.database_id`.
7. Verifier les proprietes Notion.
8. Cliquer sur `Valider`.
9. Garder le flux inactif tant que le payload Notion n'est pas complet.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Notion` |
| Named Credential | `Notion` |
| Base URL | `https://api.notion.com/v1` |
| Salesforce Object | `Account` |
| External Object | `pages` |
| Endpoint Path | `/pages` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer une page | `POST` | `/pages` |
| Lire une page | `GET` | `/pages/{page_id}` |
| Modifier une page | `PATCH` | `/pages/{page_id}` |
| Query une database | `POST` | `/databases/{database_id}/query` |

## Mappings de depart

| Salesforce | Notion |
| --- | --- |
| `Name` | `properties.Name.title.0.text.content` |
| `Phone` | `properties.Phone.phone_number` |
| `Website` | `properties.Website.url` |

## Exemple de payload attendu

Notion demande un payload imbrique avec des tableaux:

```json
{
  "parent": {
    "database_id": "DATABASE_ID"
  },
  "properties": {
    "Name": {
      "title": [
        {
          "text": {
            "content": "Acme France"
          }
        }
      ]
    }
  }
}
```

## Points d'attention

- Notion demande le header `Notion-Version`.
- ErpSync sait construire des objets imbriques avec la notation point, mais les tableaux Notion demandent une evolution ou un adaptateur dedie.
- Le nom des proprietes doit correspondre exactement a la database.
- Le token doit avoir acces a la page ou database cible.

## Documentation officielle

- https://developers.notion.com/reference/post-page

