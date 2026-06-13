# Connecteur Brevo

## Objectif

Synchroniser des contacts Salesforce vers Brevo. Le cas le plus simple est `Contact` Salesforce vers `contacts` Brevo.

## Ce qu'il faut preparer cote Brevo

- Un compte Brevo.
- Une API key ou une application OAuth.
- La liste des attributs Brevo utiles: `FIRSTNAME`, `LASTNAME`, `SMS`, etc.
- Une decision sur le champ cle: en general `Email`.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Chercher `Named Credentials`.
3. Creer un Named Credential nomme `Brevo`.
4. URL de base: `https://api.brevo.com/v3`.
5. Ajouter l'API key dans les headers selon la configuration Salesforce choisie.
6. Ne pas mettre l'API key dans ErpSync.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `Brevo`.
4. Cliquer sur `Installer`.
5. Le connecteur et le flux sont crees en `Inactive`.
6. Verifier le Named Credential, l'endpoint et les mappings.
7. Cliquer sur `Valider`.
8. Activer le systeme puis le flux.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `Brevo` |
| Named Credential | `Brevo` |
| Base URL | `https://api.brevo.com/v3` |
| Salesforce Object | `Contact` |
| External Object | `contacts` |
| Endpoint Path | `/contacts` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer un contact | `POST` | `/contacts` |
| Lire un contact | `GET` | `/contacts/{identifier}` |
| Mettre a jour un contact | `PUT` | `/contacts/{identifier}` |
| Supprimer un contact | `DELETE` | `/contacts/{identifier}` |

## Mappings de depart

| Salesforce | Brevo |
| --- | --- |
| `Email` | `email` |
| `FirstName` | `attributes.FIRSTNAME` |
| `LastName` | `attributes.LASTNAME` |
| `Phone` | `attributes.SMS` |

## Exemple de payload attendu

```json
{
  "email": "ada@example.com",
  "attributes": {
    "FIRSTNAME": "Ada",
    "LASTNAME": "Lovelace"
  }
}
```

## Points d'attention

- Les attributs Brevo doivent exister dans Brevo avant la synchro.
- `Email` doit etre propre et unique.
- Pour les campagnes, eCommerce ou events, creer des flux separes.

## Documentation officielle

- https://developers.brevo.com/docs/getting-started
- https://developers.brevo.com/reference/createcontact

