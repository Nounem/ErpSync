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

