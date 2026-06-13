# Connecteur SAP

## Objectif

Preparer une integration Salesforce vers SAP. Le cas de depart est `Account` vers Business Partner.

## Ce qu'il faut preparer cote SAP

- Systeme SAP cible: S/4HANA Cloud, S/4HANA on-premise ou SAP Gateway.
- Service OData expose, par exemple Business Partner.
- Methode d'auth: OAuth, Basic, principal propagation, etc.
- Liste des champs obligatoires SAP.

## Ou faire l'authentification dans Salesforce

1. Aller dans `Setup`.
2. Creer un Named Credential nomme `SAP`.
3. URL de base: l'URL SAP Gateway ou API Management.
4. Configurer l'auth selon le choix DSI.

## Ou configurer dans ErpSync

1. Application `ErpSync`.
2. Onglet `Catalogue`.
3. Ligne `SAP`.
4. Cliquer sur `Installer`.
5. Remplacer l'URL et confirmer le service OData cible.

## Template conseille

| Champ ErpSync | Valeur |
| --- | --- |
| Connector Type | `SAP` |
| Named Credential | `SAP` |
| Base URL | `https://sap.example.com` |
| Salesforce Object | `Account` |
| External Object | `A_BusinessPartner` |
| Endpoint Path | `/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_BusinessPartner` |
| HTTP Method | `POST` |
| Payload Mode | `Raw Mapping` |

## Endpoints utiles

| Action | Methode | Endpoint |
| --- | --- | --- |
| Creer Business Partner | `POST` | `/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_BusinessPartner` |
| Lire Business Partner | `GET` | `/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_BusinessPartner('{id}')` |
| Modifier Business Partner | `PATCH` | `/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_BusinessPartner('{id}')` |

## Mappings de depart

| Salesforce | SAP |
| --- | --- |
| `Name` | `OrganizationBPName1` |
| `Phone` | `PhoneNumber` |
| `Website` | `WebsiteURL` |

## Points d'attention

- SAP demande souvent des champs obligatoires supplementaires.
- Les structures SAP peuvent etre profondes et normalisees.
- Prevoir un adaptateur dedie pour la production.

## Documentation officielle

- https://api.sap.com/api/API_BUSINESS_PARTNER/overview

