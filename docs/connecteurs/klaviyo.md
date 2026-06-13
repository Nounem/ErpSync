# Connecteur Klaviyo

## Objectif

Synchroniser des contacts Salesforce vers les profils Klaviyo. Le cas de depart est `Contact` Salesforce vers `profiles` Klaviyo.

## Niveau de compatibilite ErpSync

L'endpoint `/profiles` est correct, mais Klaviyo attend un payload JSON:API avec `data.type = profile`. La version actuelle d'ErpSync ne cree pas encore proprement une valeur fixe sans champ Salesforce source. Garder le flux inactif tant que cette valeur n'est pas geree par un champ Salesforce, une evolution de mapping ou un adaptateur.

## Ce qu'il faut preparer cote Klaviyo

- Un compte Klaviyo.
- Une private API key.
- La revision API a utiliser.
- Les attributs de profil utiles.
- Les listes ou segments cibles si necessaire.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `Klaviyo`.
4. URL de base: `https://a.klaviyo.com/api`.
5. Ajouter le header d'autorisation avec la private API key selon la configuration Salesforce.
6. Ajouter le header `revision` attendu par Klaviyo.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Klaviyo`.
4. Cliquer sur `Installer`.
5. Ouvrir le systeme cree.
6. Verifier le Named Credential.
7. Ouvrir le flux et verifier `/profiles`.
8. Cliquer sur `Valider`.
9. Garder inactif tant que `data.type = profile` n'est pas gere.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Klaviyo` |
| Named Credential | `Klaviyo` |
| Base URL | `https://a.klaviyo.com/api` |
| Salesforce Object | `Contact` |
| External Object | `profiles` |
| Endpoint Path | `/profiles` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer un profil | `POST` | `/profiles` |
| Lire les profils | `GET` | `/profiles` |
| Lire un profil | `GET` | `/profiles/{id}` |
| Modifier un profil | `PATCH` | `/profiles/{id}` |

## Mappings de depart

| Salesforce | Klaviyo |
| --- | --- |
| `Email` | `data.attributes.email` |
| `FirstName` | `data.attributes.first_name` |
| `LastName` | `data.attributes.last_name` |
| `Phone` | `data.attributes.phone_number` |

## Exemple de payload attendu

```json
{
  "data": {
    "type": "profile",
    "attributes": {
      "email": "ada@example.com",
      "first_name": "Ada",
      "last_name": "Lovelace",
      "phone_number": "+33123456789"
    }
  }
}
```

## Points d'attention

- Klaviyo demande un header `revision`.
- Le champ `data.type = profile` doit etre present. Le template de mapping peut necessiter une valeur fixe ou une evolution de payload.
- Pour les listes, creer un flux separe apres la creation du profil.

## Documentation officielle

- https://developers.klaviyo.com/en/reference/create_profile
