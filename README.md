# ErpSync

[![Deploy to Salesforce](https://img.shields.io/badge/Deploy%20to-Salesforce-00A1E0?style=for-the-badge&logo=salesforce&logoColor=white)](https://githubsfdeploy.herokuapp.com?owner=Nounem&repo=ErpSync)

Application Salesforce LWC configurable pour connecter Salesforce a un ou plusieurs systemes externes de type ERP/CRM, avec configuration admin, synchronisation, suivi des executions et gestion des erreurs.

Le bouton ci-dessus deploie les metadonnees Salesforce depuis GitHub. Apres le deploiement, assigner le permission set `ErpSync_Admin` a l'utilisateur administrateur.

## Documentation projet

- [Analyse du besoin - Application Salesforce LWC configurable d'integration ERP/CRM](docs/analyse-besoin-erp-sync.md)

## Premier socle implemente

Le projet contient maintenant un premier MVP Salesforce:

- Objets de configuration: `IntegrationSystem__c`, `IntegrationFlow__c`, `IntegrationMapping__c`.
- Objets de suivi: `SyncExecution__c`, `SyncError__c`.
- Application Lightning `ErpSync` et onglet `ErpSync Admin`.
- Permission set `ErpSync_Admin`.
- Console LWC `erpSyncAdminConsole`.
- Controller Apex `ErpSyncAdminController` et test `ErpSyncAdminControllerTest`.
- Moteur de synchronisation asynchrone `ErpSyncSyncQueueable` / `ErpSyncSyncOrchestrator`.
- Connecteur MVP `Generic REST` base sur Named Credential ou Base URL.
- Catalogue admin des connecteurs courants: Brevo, HubSpot, Odoo, Dynamics, SAP, NetSuite, Sage, QuickBooks, Xero, Shopify, WooCommerce, Stripe, PayPal, Mailchimp, Klaviyo, Zendesk, Freshdesk, Jira, Slack, Notion, Airtable, etc.
- Installation de templates depuis le catalogue: connecteur, flux et mappings de depart crees en inactif.
- Onglet `Aide` dans la console admin pour guider synchro, authentification, templates et payload.
- Support configurable des SaaS REST via `Generic REST`, avec modes de payload `Envelope`, `Raw Mapping` et `Root Key`.
- Support des champs externes imbriques via notation point, par exemple `attributes.FIRSTNAME`.
- Mapping Salesforce vers payload externe avec transformations simples.
- Tests Apex du moteur: `ErpSyncSyncOrchestratorTest`.
- Scheduler Apex `ErpSyncScheduler` pour flux planifies et retries dus.
- Test connexion depuis la console admin.
- Suivi record-level avec `IntegrationRecordLink__c` et `SyncRecordLog__c`.
- Validation de configuration des flux depuis la console admin.

Limites actuelles: le moteur execute le sens `Salesforce to External`. Les SaaS JSON REST comme Brevo ou HubSpot peuvent etre configures via l adaptateur `Generic REST`; les ERP plus complexes ou APIs avec formats specifiques, comme Odoo, SAP, NetSuite ou Stripe, restent prevus comme adaptateurs dedies.

### Exemple Brevo

- Systeme: `Connector Type = Brevo`, `Named Credential = Brevo`, `Base URL = https://api.brevo.com/v3` si aucun Named Credential n encapsule deja l URL.
- Flux contacts: `Endpoint Path = /contacts`, `HTTP Method = POST`.
- Payload recommande: `Raw Mapping`, avec `Email -> email`, `FirstName -> attributes.FIRSTNAME`, `LastName -> attributes.LASTNAME`.

## Fonctionnement de la synchronisation

1. L administrateur installe ou cree un connecteur, puis renseigne le `Named Credential`.
2. Il cree ou ajuste un flux: objet Salesforce, objet externe, endpoint, methode HTTP, payload.
3. Il configure les mappings: champ Salesforce vers champ externe, transformation, obligatoire, cle externe.
4. Il valide le flux depuis la console, puis active le systeme et le flux.
5. Une execution manuelle, planifiee ou retry cree un `SyncExecution__c`.
6. Le moteur lit les records Salesforce, construit le payload, appelle l API externe, puis cree les logs, liens records et erreurs.

## Authentification

ErpSync ne stocke pas les secrets. Le champ `NamedCredentialName__c` reference un Named Credential Salesforce. Les tokens, API keys, secrets OAuth ou credentials Basic doivent etre geres par Salesforce dans Named Credentials / External Credentials.

Lors d un callout, Apex construit l endpoint comme suit:

```text
callout:NomDuNamedCredential + EndpointPath__c
```

Le champ `BaseUrl__c` reste utile comme information ou pour des tests non sensibles, mais le mode recommande est le Named Credential.

## Commandes utiles

Authentifier une org Salesforce:

```bash
sf org login web --alias erpsync-dev --set-default
```

Deployer le socle:

```bash
sf project deploy start --source-dir force-app --target-org erpsync-dev
```

Assigner le permission set:

```bash
sf org assign permset --name ErpSync_Admin --target-org erpsync-dev
```

Executer le test Apex:

```bash
sf apex run test --class-names ErpSyncAdminControllerTest --class-names ErpSyncSyncOrchestratorTest --class-names ErpSyncSchedulerAndRetryTest --class-names ErpSyncConfigValidationServiceTest --result-format human --target-org erpsync-dev --wait 10
```

Installer le scheduler horaire:

```bash
sf apex run --file scripts/schedule-erpsync.apex --target-org erpsync-dev
```

Retirer le scheduler:

```bash
sf apex run --file scripts/unschedule-erpsync.apex --target-org erpsync-dev
```

## Salesforce DX

Le projet utilise la structure standard Salesforce DX avec le repertoire source `force-app`.
