# Connecteur Mailchimp

## Objectif

Synchroniser des contacts Salesforce vers une audience Mailchimp. Le cas de depart est `Contact` Salesforce vers `members` Mailchimp.

## Niveau de compatibilite ErpSync

L'endpoint est compatible avec `Generic REST`, mais Mailchimp demande un `status` comme `subscribed` ou `pending`. Comme les mappings ErpSync actuels partent toujours d'un champ Salesforce, prevoir un champ Salesforce de statut marketing ou une evolution de valeur fixe avant activation.

## Ce qu'il faut preparer cote Mailchimp

- Un compte Mailchimp.
- Une API key ou une application OAuth.
- Le data center Mailchimp, par exemple `us1`, `us20`, etc.
- L'identifiant de l'audience: `LIST_ID`.
- Les merge fields: `FNAME`, `LNAME`, `PHONE`, etc.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `Mailchimp`.
4. URL de base: `https://us1.api.mailchimp.com/3.0`.
5. Remplacer `us1` par le data center reel de l'API key.
6. Stocker l'API key uniquement dans Salesforce.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Mailchimp`.
4. Cliquer sur `Installer`.
5. Ouvrir le flux cree.
6. Remplacer `LIST_ID`.
7. Ajouter la valeur de statut attendue via un champ Salesforce ou une evolution de mapping.
8. Cliquer sur `Valider`.
9. Activer apres test sur une audience de test.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Mailchimp` |
| Named Credential | `Mailchimp` |
| Base URL | `https://us1.api.mailchimp.com/3.0` |
| Salesforce Object | `Contact` |
| External Object | `members` |
| Endpoint Path | `/lists/LIST_ID/members` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Ajouter un membre | `POST` | `/lists/{list_id}/members` |
| Lire les membres | `GET` | `/lists/{list_id}/members` |
| Lire un membre | `GET` | `/lists/{list_id}/members/{subscriber_hash}` |
| Mettre a jour un membre | `PUT` | `/lists/{list_id}/members/{subscriber_hash}` |

## Mappings de depart

| Salesforce | Mailchimp |
| --- | --- |
| `Email` | `email_address` |
| `FirstName` | `merge_fields.FNAME` |
| `LastName` | `merge_fields.LNAME` |
| `Phone` | `merge_fields.PHONE` |

## Exemple de payload attendu

```json
{
  "email_address": "ada@example.com",
  "status": "subscribed",
  "merge_fields": {
    "FNAME": "Ada",
    "LNAME": "Lovelace",
    "PHONE": "+33123456789"
  }
}
```

## Points d'attention

- `status` est important. Utiliser `subscribed`, `pending` ou une valeur conforme a la politique opt-in du client.
- La version actuelle d'ErpSync ne cree pas encore une valeur fixe sans champ Salesforce source.
- Remplacer `LIST_ID` avant activation.
- Pour mettre a jour sans doublon, il faut calculer le `subscriber_hash` de l'email en minuscule.
- Respecter le consentement marketing et les obligations RGPD.

## Documentation officielle

- https://mailchimp.com/developer/marketing/api/list-members/add-member-to-list/
