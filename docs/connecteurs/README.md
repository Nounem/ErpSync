# Guides connecteurs ErpSync

Ce dossier contient un guide par connecteur. L'objectif est qu'un administrateur debutant sache:

- quoi preparer cote outil externe;
- ou creer l'authentification dans Salesforce;
- quoi modifier dans ErpSync apres avoir installe le template;
- quels endpoints utiliser pour demarrer;
- quels mappings verifier avant activation.

## Regle de securite commune

Ne jamais mettre de token, mot de passe, secret OAuth ou API key dans ErpSync. Les secrets doivent rester dans Salesforce Setup, via `Named Credentials` et si possible `External Credentials`.

Dans ErpSync, on met seulement:

- le nom du Named Credential dans `NamedCredentialName__c`;
- la `BaseUrl__c` a titre d'information ou fallback non sensible;
- l'`EndpointPath__c` du flux.

## Ordre conseille pour tous les connecteurs

1. Aller dans Salesforce Setup.
2. Creer le Named Credential du fournisseur.
3. Aller dans l'application `ErpSync`.
4. Ouvrir l'onglet `Catalogue`.
5. Cliquer sur `Installer` pour le connecteur.
6. Ouvrir le connecteur cree et remplacer les valeurs exemple.
7. Ouvrir le flux cree et verifier endpoint, payload et mappings.
8. Cliquer sur `Valider` dans la grille `Flux`.
9. Activer le connecteur puis le flux.
10. Lancer une premiere synchro manuelle sur un petit volume.

## Lire le niveau de compatibilite

Tous les guides donnent les bons endroits ou configurer Salesforce et les endpoints de depart. En revanche, tous les fournisseurs ne peuvent pas etre actives directement avec le moteur `Generic REST` actuel.

| Niveau | Signification |
| --- | --- |
| Direct `Generic REST` | Le payload JSON attendu est simple: objet direct ou objet sous une racine. |
| Direct avec ajustement | L'endpoint est simple, mais il faut ajouter un champ client, un scope, un header ou une valeur metier avant activation. |
| Adaptateur ou payload dedie | L'API attend un tableau JSON, du form-urlencoded, du JSON-RPC, des valeurs fixes obligatoires ou une logique metier specifique. Le guide sert alors de cadrage. |

## Synthese rapide

| Connecteur | Niveau actuel |
| --- | --- |
| Brevo | Direct `Generic REST` |
| HubSpot | Direct `Generic REST` |
| Microsoft Dynamics 365 | Direct `Generic REST` pour flux simples |
| Business Central | Direct `Generic REST` pour creation customer simple |
| QuickBooks | Direct `Generic REST` pour creation customer simple |
| Xero | Direct avec ajustement header `xero-tenant-id` |
| Pipedrive | Direct `Generic REST` |
| Shopify | Direct avec scopes Shopify et vigilance REST legacy |
| WooCommerce | Direct `Generic REST` |
| Zendesk | Direct `Generic REST` |
| Freshdesk | Direct avec ajustement si champ tableau `domains` |
| Slack | Direct avec champ Salesforce pour `channel` et `text` |
| Mailchimp | Direct avec ajustement pour `status` |
| Klaviyo | Adaptateur ou valeur fixe requise pour `data.type` |
| Zoho | Adaptateur ou payload array requis pour `data[]` |
| Airtable | Adaptateur ou payload array requis pour `records[]` |
| Notion | Adaptateur requis pour tableaux/proprietes complexes |
| Jira | Adaptateur ou champs Salesforce requis pour `project` et `issuetype` |
| Stripe | Adaptateur requis pour `application/x-www-form-urlencoded` |
| Odoo | Adaptateur requis pour JSON-RPC/metadonnees Odoo |
| SAP | Adaptateur recommande pour OData/SAP Gateway |
| Oracle NetSuite | Adaptateur recommande pour SuiteTalk REST |
| Sage | Adaptateur recommande selon produit Sage |
| PayPal | Cadrage par cas d'usage PayPal |

## Guides disponibles

- [Generic REST](generic-rest.md)
- [Brevo](brevo.md)
- [HubSpot](hubspot.md)
- [Odoo](odoo.md)
- [Microsoft Dynamics 365](microsoft-dynamics-365.md)
- [Business Central](business-central.md)
- [SAP](sap.md)
- [Oracle NetSuite](oracle-netsuite.md)
- [Sage](sage.md)
- [QuickBooks](quickbooks.md)
- [Xero](xero.md)
- [Zoho](zoho.md)
- [Pipedrive](pipedrive.md)
- [Shopify](shopify.md)
- [WooCommerce](woocommerce.md)
- [Stripe](stripe.md)
- [PayPal](paypal.md)
- [Mailchimp](mailchimp.md)
- [Klaviyo](klaviyo.md)
- [Zendesk](zendesk.md)
- [Freshdesk](freshdesk.md)
- [Jira](jira.md)
- [Slack](slack.md)
- [Notion](notion.md)
- [Airtable](airtable.md)
- [Other](other.md)
