# Analyse du besoin - Application Salesforce LWC configurable d'integration ERP/CRM

## 1. Contexte

Le projet ErpSync vise a mettre en place une application Salesforce configurable permettant de connecter Salesforce a un ou plusieurs systemes externes, par exemple Odoo, HubSpot, ou d'autres ERP/CRM/metiers.

L'objectif principal est de fournir une interface d'administration dans Salesforce, construite en Lightning Web Components (LWC), permettant a un administrateur fonctionnel ou technique de configurer les connexions, les objets a synchroniser, les mappings de champs, les regles de synchronisation, ainsi que le suivi des erreurs et des traitements.

HubSpot est plutot une plateforme CRM/marketing/sales qu'un ERP au sens strict, tandis qu'Odoo couvre davantage un perimetre ERP/CRM. Le besoin doit donc etre pense comme une plateforme generique d'integration Salesforce vers systemes externes, et non comme une integration specifique a un seul outil.

## 2. Vision produit

Creer une application Salesforce administrable, extensible et industrialisable, capable de:

- Declarer plusieurs systemes externes.
- Configurer les objets Salesforce et externes a synchroniser.
- Gerer les mappings de champs sans redeploiement.
- Declencher des synchronisations manuelles, programmees ou evenementielles.
- Suivre l'etat des integrations dans une interface admin.
- Centraliser les logs, erreurs, retries et alertes.
- Ajouter progressivement de nouveaux connecteurs sans reconstruire le coeur de l'application.

La cible n'est pas seulement une integration technique, mais une console d'exploitation d'integration dans Salesforce.

## 3. Objectifs metier

- Reduire les doubles saisies entre Salesforce et les ERP/CRM externes.
- Fiabiliser les donnees clients, contacts, societes, opportunites, devis, commandes, factures ou produits selon le perimetre retenu.
- Donner de l'autonomie aux administrateurs pour ajuster les mappings et parametres.
- Offrir une visibilite claire sur les synchronisations reussies, en attente ou en erreur.
- Permettre une extension future vers d'autres systemes externes.
- Industrialiser les flux pour eviter des integrations point a point fragiles.

## 4. Parties prenantes

| Profil | Role | Attentes principales |
| --- | --- | --- |
| Administrateur Salesforce | Configure et surveille l'application | Interface claire, controle des mappings, logs exploitables |
| Responsable metier | Valide les objets et regles de synchronisation | Donnees fiables, processus coherents, erreurs visibles |
| Integrateur / developpeur Salesforce | Cree les connecteurs et la logique technique | Architecture extensible, classes Apex factorisees, tests |
| Equipe support | Analyse les incidents | Historique, messages d'erreur lisibles, relance des traitements |
| DSI / securite | Valide les acces et les flux | Authentification robuste, audit, respect des droits |

## 5. Perimetre fonctionnel cible

### 5.1 Gestion des systemes externes

L'application doit permettre de declarer plusieurs connexions externes:

- Nom du systeme: Odoo, HubSpot, autre.
- Type de connecteur.
- Environnement: sandbox, recette, production.
- URL de base de l'API.
- Mode d'authentification.
- Statut: actif, inactif, en maintenance.
- Limites techniques connues: quota API, taille de batch, timeout.
- Proprietaire fonctionnel et technique.

Recommandation Salesforce: stocker les secrets dans des Named Credentials / External Credentials, et non dans des objets custom ou Custom Metadata.

### 5.1.1 Catalogue initial des ERP et SaaS

Le besoin ne doit pas se limiter a Odoo et HubSpot. La console admin doit exposer un catalogue extensible couvrant les ERP, CRM, outils marketing, e-commerce, paiement, support et productivite les plus frequents.

Deux niveaux de support sont a distinguer:

- Support configurable via `Generic REST`: adapte aux APIs JSON simples, configurables par URL, endpoint, methode HTTP, mapping et mode de payload.
- Connecteur dedie: necessaire quand l'API impose une logique specifique, par exemple JSON-RPC, OData complexe, pagination metier, associations, format non JSON ou authentification particuliere.

Catalogue recommande:

| Systeme | Famille | Support recommande |
| --- | --- | --- |
| Brevo | Marketing / CRM | Generic REST, prioritaire pour contacts, events et eCommerce |
| HubSpot | CRM / Marketing | Generic REST au MVP, connecteur dedie ensuite pour associations |
| Odoo | ERP / CRM | Connecteur dedie recommande |
| Microsoft Dynamics 365 | ERP / CRM | Connecteur dedie recommande |
| Business Central | ERP / Finance | Generic REST/OData possible, conventions a cadrer |
| SAP | ERP | Connecteur dedie recommande |
| Oracle NetSuite | ERP / Finance | Connecteur dedie recommande |
| Sage | ERP / Finance | Connecteur dedie selon produit Sage |
| QuickBooks | Comptabilite | Generic REST possible |
| Xero | Comptabilite | Generic REST possible |
| Zoho | CRM / Suite | Generic REST possible |
| Pipedrive | CRM | Generic REST possible |
| Shopify | Commerce | Generic REST possible avec vigilance, GraphQL a privilegier pour nouvelles apps |
| WooCommerce | Commerce | Generic REST possible |
| Stripe | Paiement | Connecteur dedie recommande, payload form-encoded |
| PayPal | Paiement | Generic REST possible |
| Mailchimp | Marketing | Generic REST possible |
| Klaviyo | Marketing | Generic REST possible |
| Zendesk | Support | Generic REST possible |
| Freshdesk | Support | Generic REST possible |
| Jira | ITSM / Projet | Generic REST possible |
| Slack / Teams | Notifications | Webhook ou Generic REST |
| Notion / Airtable | Productivite / Base | Generic REST possible |

Brevo doit etre explicitement prevu dans le MVP technique car son API couvre plusieurs cas utiles: contacts, messages transactionnels, campagnes, tracking, eCommerce et webhooks. Pour Brevo, le mode de payload `Raw Mapping` ou `Root Key` est important afin d'envoyer les champs dans la structure attendue par l'endpoint.

Chaque entree du catalogue doit pouvoir fournir un template installable:

- Connecteur pre-rempli en `Inactive`.
- Base URL exemple et nom de Named Credential suggere.
- Flux pre-rempli en `Inactive`.
- Endpoint, methode HTTP et mode de payload proposes.
- Mappings de depart sur des objets standards Salesforce.
- Notes d'aide pour l'administrateur.

Le client ne doit donc pas partir d'une page blanche. Il installe un template, modifie les valeurs propres a son environnement, cree le Named Credential, valide le flux, puis active la synchronisation.

### 5.2 Catalogue des objets synchronisables

L'application doit permettre de configurer les objets concernes:

- Salesforce Account vers societe externe.
- Salesforce Contact vers contact externe.
- Salesforce Lead vers lead externe.
- Salesforce Product2 vers produit externe.
- Salesforce Pricebook / PricebookEntry vers tarifs externes.
- Opportunity vers opportunite/devis externe.
- Order vers commande externe.
- Invoice externe vers objet Salesforce custom, si necessaire.
- Tout objet custom Salesforce utile au processus.

Le perimetre exact doit etre valide par lot fonctionnel. Il est recommande de commencer par un noyau simple: comptes, contacts, produits, opportunites ou commandes selon la priorite metier.

### 5.3 Mappings de champs configurables

L'interface admin doit permettre de definir des mappings:

- Objet source.
- Objet cible.
- Champ source.
- Champ cible.
- Sens de synchronisation.
- Transformation eventuelle.
- Champ obligatoire ou optionnel.
- Valeur par defaut.
- Regle de validation.
- Gestion des valeurs nulles.
- Priorite en cas de conflit.

Exemples:

| Salesforce | Systeme externe | Regle |
| --- | --- | --- |
| Account.Name | Odoo res.partner.name | Obligatoire |
| Account.Phone | HubSpot phone | Optionnel |
| Contact.Email | Contact externe email | Cle de rapprochement possible |
| Product2.ProductCode | Produit externe sku | Identifiant metier |

Les transformations simples peuvent etre configurables: trim, uppercase, format date, concatenation simple, conversion de booleen, mapping de picklists. Les transformations complexes doivent rester codees dans Apex via une strategie extensible pour eviter une interface trop difficile a maintenir.

### 5.4 Sens de synchronisation

Chaque flux doit pouvoir etre defini selon un sens:

- Salesforce vers systeme externe.
- Systeme externe vers Salesforce.
- Bidirectionnel.

Pour le bidirectionnel, il faut definir clairement:

- La source de verite par objet ou par champ.
- Les regles de resolution de conflit.
- Le comportement si les deux systemes ont ete modifies depuis la derniere synchronisation.
- La gestion des suppressions.

Recommandation: eviter le bidirectionnel complet au MVP, sauf besoin metier critique. Un bidirectionnel mal cadre est souvent la principale source d'erreurs de donnees.

### 5.5 Declenchement des synchronisations

Les modes attendus:

- Manuel depuis l'interface admin.
- Programme via Apex Scheduler.
- Asynchrone via Queueable Apex ou Batch Apex.
- Evenementiel depuis Salesforce apres creation/modification d'enregistrements.
- Webhook entrant depuis les systemes externes, si disponible.

Il faut prevoir des options de configuration:

- Activer/desactiver un flux.
- Frequence.
- Taille des lots.
- Nombre maximal de tentatives.
- Delai entre retries.
- Fenetre horaire d'execution.
- Priorite d'execution.

### 5.6 Journalisation et suivi des erreurs

La console admin doit offrir une vue claire sur:

- Executions recentes.
- Statut: succes, succes partiel, erreur, en attente, annule.
- Nombre d'enregistrements traites.
- Nombre d'enregistrements en erreur.
- Duree.
- Systeme concerne.
- Objet concerne.
- Message d'erreur lisible.
- Payload technique consultable selon le profil utilisateur.
- Possibilite de relancer un enregistrement, un lot ou une execution complete.

Types d'erreurs a distinguer:

- Erreur d'authentification.
- Erreur reseau ou timeout.
- Quota API atteint.
- Erreur de validation Salesforce.
- Erreur de validation externe.
- Mapping manquant ou invalide.
- Donnee obligatoire absente.
- Conflit de donnees.
- Doublon.
- Erreur technique inattendue.

### 5.6.1 Cycle d'execution d'une synchronisation

Le fonctionnement cible d'une synchronisation est le suivant:

1. Un utilisateur, un scheduler ou un retry demande l'execution d'un flux actif.
2. ErpSync cree un `SyncExecution__c` avec un correlation id.
3. Le moteur charge le `IntegrationFlow__c`, le `IntegrationSystem__c` et les mappings actifs.
4. Le moteur lit les records Salesforce selon l'objet et la taille de batch configuree.
5. Chaque record est transforme en payload JSON via les mappings.
6. Le connecteur construit l'endpoint externe avec le Named Credential et l'endpoint du flux.
7. L'appel HTTP est execute.
8. En cas de succes, ErpSync met a jour le lien Salesforce/externe et cree un log record.
9. En cas d'echec, ErpSync cree une erreur actionnable et indique si un retry est possible.
10. L'execution globale est terminee avec un statut succes, succes partiel ou erreur.

Le MVP execute le sens `Salesforce to External`. Les sens `External to Salesforce` et `Bidirectional` restent dans le modele mais necessitent une phase de cadrage plus stricte.

### 5.7 Relance et reprise sur erreur

L'application doit permettre:

- Retry automatique selon une politique configurable.
- Retry manuel depuis l'interface.
- Mise en quarantaine d'un enregistrement en erreur persistante.
- Ignorer une erreur avec justification.
- Rejouer un payload apres correction du mapping ou de la donnee.
- Historiser les tentatives.

Une erreur ne doit pas bloquer tout un flux si elle concerne seulement un enregistrement, sauf pour les erreurs globales comme authentification ou configuration invalide.

### 5.8 Tableau de bord admin

L'interface LWC devrait contenir au minimum:

- Page d'accueil avec indicateurs de sante.
- Liste des connecteurs.
- Detail d'un connecteur.
- Configuration des flux.
- Configuration des mappings.
- Historique des executions.
- File d'erreurs.
- Detail d'une erreur.
- Actions de retry, pause, activation/desactivation.

Indicateurs utiles:

- Derniere synchronisation reussie par connecteur.
- Nombre d'erreurs ouvertes.
- Taux de succes sur 24h / 7 jours.
- Duree moyenne d'execution.
- Nombre d'enregistrements synchronises.
- Flux en retard ou bloques.

## 6. Exigences non fonctionnelles

### 6.1 Securite

- Utiliser Named Credentials / External Credentials pour les secrets et tokens.
- Ne jamais stocker les mots de passe ou tokens en clair dans des objets custom.
- Gerer les droits par Permission Sets.
- Restreindre la consultation des payloads sensibles.
- Masquer les donnees personnelles dans les logs si necessaire.
- Tracer les actions administrateur importantes.
- Respecter les politiques de gouvernance Salesforce: CRUD, FLS, sharing.

Modele d'authentification recommande:

- Le secret reste dans Salesforce Setup, dans un Named Credential ou External Credential.
- `IntegrationSystem__c.NamedCredentialName__c` contient uniquement le nom logique du Named Credential.
- Le connecteur Apex appelle `callout:NomDuNamedCredential` et ajoute `IntegrationFlow__c.EndpointPath__c`.
- Les modes API Key, Bearer Token, OAuth 2.0 ou Basic Auth sont configures dans Salesforce, pas dans ErpSync.
- `BaseUrl__c` ne doit pas contenir de token et doit rester une information technique ou un fallback non sensible.

### 6.2 Performance et limites Salesforce

L'architecture doit tenir compte des limites Salesforce:

- Limites de callouts Apex.
- Limites de temps CPU.
- Taille maximale des heap.
- DML par transaction.
- Requetes SOQL.
- Traitement asynchrone pour les volumes importants.
- Pagination cote API externe.

Recommandation:

- Utiliser Queueable Apex pour les traitements unitaires ou par petits lots.
- Utiliser Batch Apex pour les volumes importants.
- Utiliser Platform Events ou objets de file interne si le besoin de decouplage augmente.
- Eviter les traitements synchrones longs depuis LWC.

### 6.3 Scalabilite

L'application doit pouvoir supporter:

- Plusieurs connecteurs actifs.
- Plusieurs flux par connecteur.
- Plusieurs mappings par flux.
- Des volumes variables selon les objets.
- Des connecteurs ajoutes dans le temps.

Le coeur de synchronisation doit etre generique. Les specificites HubSpot, Odoo ou autre doivent etre isolees dans des adaptateurs/connecteurs.

### 6.4 Maintenabilite

- Separation claire entre UI LWC, services Apex, configuration, connecteurs et logs.
- Tests unitaires Apex sur les connecteurs, mappings, retries et erreurs.
- Documentation de chaque flux.
- Versionning des configurations sensibles.
- Convention de nommage stable.

### 6.5 Observabilite

- Logs fonctionnels consultables dans Salesforce.
- Logs techniques exploitables par l'equipe de support.
- Correlation ID par execution.
- Suivi par record Salesforce et par ID externe.
- Conservation configurable de l'historique.
- Alertes email, Slack, Teams ou autre canal si souhaite.

## 7. Architecture cible recommandee

### 7.1 Vue d'ensemble

Architecture logique:

```text
LWC Admin Console
        |
        v
Apex Admin Services
        |
        v
Configuration Layer
Custom Metadata + Custom Objects
        |
        v
Sync Orchestrator Apex
        |
        +--> Connector Adapter: Odoo
        +--> Connector Adapter: HubSpot
        +--> Connector Adapter: Brevo / REST SaaS
        +--> Connector Adapter: Generic REST
        |
        v
Named Credentials / External Credentials
        |
        v
External APIs
```

### 7.2 Composants Salesforce

| Couche | Technologie | Role |
| --- | --- | --- |
| Interface admin | LWC | Configuration, monitoring, actions |
| Services backend | Apex | Lecture/ecriture config, lancement sync |
| Orchestration | Apex Queueable / Batch / Scheduler | Execution asynchrone |
| Connecteurs | Apex classes | Adaptation API externe |
| Configuration stable | Custom Metadata Types | Types de connecteurs, templates, constantes |
| Configuration admin | Custom Objects | Instances connecteurs, flux, mappings |
| Secrets | Named Credentials / External Credentials | Authentification securisee |
| Logs | Custom Objects | Executions, erreurs, retries |
| Notifications | Email / Platform Events / Flow | Alertes et reactions |

### 7.3 Principe d'adaptateur connecteur

Chaque systeme externe doit implementer une interface Apex commune:

```text
ConnectorAdapter
- authenticate/checkConnection
- describeObjects
- fetchRecords
- createRecord
- updateRecord
- upsertRecord
- deleteRecord
- transformResponse
- normalizeError
```

Le coeur de synchronisation ne doit pas connaitre les details de chaque API externe. Il doit demander au connecteur d'executer une operation standardisee.

### 7.4 Gestion des APIs externes

Pour Odoo:

- Verifier le protocole cible: JSON-RPC, XML-RPC ou REST selon l'installation.
- Gerer base de donnees, utilisateur, token/API key selon configuration.
- Modeles typiques: res.partner, product.template, sale.order, account.move.

Pour HubSpot:

- Utiliser OAuth ou Private App Token selon la strategie d'entreprise.
- Gerer les objets CRM: companies, contacts, deals, products, line items.
- Tenir compte des associations HubSpot entre objets.

Pour Brevo:

- Utiliser API key ou OAuth via Named Credential.
- Cibler les endpoints contacts, events, campagnes, eCommerce ou objets custom selon le besoin.
- Permettre un payload direct ou avec racine, par exemple `attributes`, pour s'adapter aux endpoints.
- Prevoir les webhooks Brevo dans une phase ulterieure pour les retours d'evenements.

Pour autres systemes:

- Prevoir un connecteur REST generique pour les cas simples.
- Prevoir des connecteurs dedies lorsque l'API a une logique metier forte.

## 8. Modele de donnees propose

### 8.1 Objets de configuration

| Objet propose | Type | Description |
| --- | --- | --- |
| IntegrationSystem__c | Custom Object | Instance d'un systeme externe configure |
| IntegrationFlow__c | Custom Object | Flux de synchronisation pour un systeme |
| IntegrationMapping__c | Custom Object | Mapping objet/champ |
| IntegrationTransform__c | Custom Object ou metadata | Regles de transformation |
| IntegrationSchedule__c | Custom Object | Planification fonctionnelle |
| ConnectorTemplate__mdt | Custom Metadata | Types de connecteurs disponibles |
| FieldTransformType__mdt | Custom Metadata | Types de transformations supportees |

### 8.2 Objets de suivi

| Objet propose | Description |
| --- | --- |
| SyncExecution__c | Une execution globale de synchronisation |
| SyncBatch__c | Un lot dans une execution |
| SyncRecordLog__c | Resultat par enregistrement |
| SyncError__c | Erreur detaillee et actionnable |
| RetryPolicy__c | Politique de retry si configurable par admin |

### 8.3 Champs essentiels

IntegrationSystem__c:

- Name
- ConnectorType__c
- Environment__c
- BaseUrl__c
- NamedCredentialName__c
- Status__c
- LastSuccessfulSync__c
- OwnerFunctional__c
- OwnerTechnical__c

IntegrationFlow__c:

- Name
- IntegrationSystem__c
- SalesforceObject__c
- ExternalObject__c
- Direction__c
- IsActive__c
- TriggerMode__c
- BatchSize__c
- ConflictStrategy__c
- ExternalIdField__c

IntegrationMapping__c:

- IntegrationFlow__c
- SalesforceField__c
- ExternalField__c
- Direction__c
- IsRequired__c
- DefaultValue__c
- TransformType__c
- NullBehavior__c
- IsExternalKey__c

SyncExecution__c:

- IntegrationSystem__c
- IntegrationFlow__c
- Status__c
- StartedAt__c
- FinishedAt__c
- TotalRecords__c
- SuccessCount__c
- ErrorCount__c
- CorrelationId__c

SyncError__c:

- SyncExecution__c
- SyncRecordLog__c
- ErrorType__c
- ErrorMessage__c
- TechnicalDetails__c
- Payload__c
- RetryCount__c
- IsRetryable__c
- Status__c
- NextRetryAt__c

## 9. Interface admin LWC

### 9.1 Navigation proposee

- Dashboard.
- Connecteurs.
- Catalogue de templates.
- Aide guidee.
- Flux.
- Mappings.
- Executions.
- Erreurs.
- Parametres.

### 9.2 Ecran Dashboard

Contenu:

- Sante globale des integrations.
- Connecteurs actifs/inactifs.
- Dernieres executions.
- Erreurs ouvertes.
- Actions rapides: lancer une sync, tester une connexion.

### 9.3 Ecran Connecteurs

Fonctions:

- Creer/modifier un connecteur.
- Associer un Named Credential.
- Tester la connexion.
- Activer/desactiver.
- Voir les flux rattaches.

### 9.4 Ecran Flux

Fonctions:

- Creer un flux.
- Choisir objet Salesforce et objet externe.
- Definir le sens.
- Definir le mode de declenchement.
- Definir batch size et politique de retry.
- Voir le statut d'execution.

### 9.5 Ecran Mappings

Fonctions:

- Selection de l'objet Salesforce.
- Selection des champs Salesforce.
- Saisie ou recuperation des champs externes.
- Definition des transformations.
- Validation du mapping.
- Detection des champs obligatoires non mappes.

### 9.6 Ecran Erreurs

Fonctions:

- Recherche et filtres.
- Detail erreur lisible.
- Payload technique masque/visible selon droit.
- Boutons retry, ignorer, marquer resolu.
- Historique des tentatives.

## 10. Strategie de synchronisation

### 10.1 Identification des enregistrements

Chaque relation entre Salesforce et un systeme externe doit etre historisee:

- ID Salesforce.
- ID externe.
- Systeme externe.
- Objet externe.
- Derniere date de synchronisation.
- Dernier hash de donnees optionnel.

Il est recommande d'utiliser des champs External ID Salesforce lorsque Salesforce recoit des donnees externes. Pour des relations multiples vers plusieurs systemes, un objet de liaison dedie peut etre plus propre qu'un seul champ externe sur l'objet metier.

### 10.2 Creation, mise a jour, suppression

Regles a definir:

- Creation Salesforce vers externe.
- Creation externe vers Salesforce.
- Update si correspondance trouvee.
- Upsert si identifiant externe disponible.
- Suppression physique ou desactivation logique.
- Archivage des liens externes.

### 10.3 Gestion des conflits

Strategies possibles:

- Salesforce gagne toujours.
- Systeme externe gagne toujours.
- Derniere modification gagne.
- Champ par champ selon source de verite.
- Blocage et revue manuelle.

Recommandation: commencer avec une strategie simple par flux, puis evoluer vers du champ par champ si necessaire.

## 11. Securite et gouvernance des donnees

Questions a traiter:

- Quelles donnees personnelles sont synchronisees ?
- Quel systeme est source de verite ?
- Quelle duree de retention des logs ?
- Les payloads contiennent-ils des donnees sensibles ?
- Qui peut consulter les erreurs techniques ?
- Qui peut relancer une synchronisation ?
- Les flux doivent-ils respecter des contraintes RGPD ?

Mesures recommandees:

- Permission Set `ErpSync Admin`.
- Permission Set `ErpSync Monitor`.
- Permission Set `ErpSync Operator`.
- Masquage des payloads pour les profils non techniques.
- Nettoyage automatique des logs anciens.
- Audit des modifications de configuration.

## 12. Alerting et exploitation

Alertes recommandees:

- Authentification echouee.
- Taux d'erreur superieur a un seuil.
- Flux non execute depuis X heures/jours.
- Quota API proche de la limite.
- Erreurs persistantes apres retries.
- Mapping invalide.

Canaux possibles:

- Email Salesforce.
- Notification Salesforce.
- Slack / Teams via webhook.
- Creation automatique de Case ou tache de support.

## 13. Decoupage MVP recommande

### MVP 1 - Socle technique et admin minimal

- Objet IntegrationSystem__c.
- Objet IntegrationFlow__c.
- Objet IntegrationMapping__c.
- Objets SyncExecution__c et SyncError__c.
- Console LWC avec connecteurs, flux, mappings, executions, erreurs.
- Catalogue des connecteurs courants, incluant Brevo et les principaux ERP/SaaS.
- Connecteur REST generique avec payload `Envelope`, `Raw Mapping` et `Root Key`.
- Test de connexion.
- Sync manuelle.
- Logs et erreurs basiques.

### MVP 2 - Synchronisation industrialisee

- Traitements Queueable/Batch.
- Scheduler.
- Retry automatique.
- Validation avancee des mappings.
- Tableau de bord.
- Gestion des droits.
- Nettoyage des logs.

### MVP 3 - Connecteurs metier

- Connecteur Odoo dedie.
- Connecteur HubSpot dedie.
- Connecteurs dedies pour ERP/API complexes: SAP, NetSuite, Dynamics, Stripe si priorise.
- Gestion des associations/relations.
- Templates de mappings par connecteur.
- Assistant de configuration.

### MVP 4 - Supervision avancee

- Alertes.
- Rejeu avance des erreurs.
- Historique detaille par enregistrement.
- Comparaison de donnees Salesforce/externe.
- Gestion de conflits.
- Webhooks entrants.

## 14. User stories principales

### Administration connecteurs

- En tant qu'administrateur, je veux creer un connecteur vers un systeme externe afin de l'utiliser dans mes flux de synchronisation.
- En tant qu'administrateur, je veux tester la connexion afin de verifier que la configuration est valide.
- En tant qu'administrateur, je veux desactiver un connecteur afin de stopper temporairement les synchronisations.

### Configuration des flux

- En tant qu'administrateur, je veux creer un flux Account vers Odoo afin de synchroniser mes clients.
- En tant qu'administrateur, je veux definir le sens de synchronisation afin de controler la source de verite.
- En tant qu'administrateur, je veux planifier un flux afin qu'il s'execute automatiquement.

### Mapping

- En tant qu'administrateur, je veux mapper les champs Salesforce et externes afin d'adapter la synchronisation a mon modele de donnees.
- En tant qu'administrateur, je veux valider un mapping afin d'eviter les erreurs au moment de l'execution.
- En tant qu'administrateur, je veux configurer des transformations simples afin d'adapter les formats de donnees.

### Monitoring

- En tant qu'operateur, je veux voir les synchronisations en erreur afin de les corriger rapidement.
- En tant qu'operateur, je veux relancer une erreur apres correction afin de finaliser le traitement.
- En tant que responsable metier, je veux voir les taux de succes afin de suivre la qualite des integrations.

## 15. Regles de gestion a clarifier

- Quels objets sont prioritaires pour le premier lot ?
- Quel systeme est source de verite pour chaque objet ?
- Les suppressions doivent-elles etre synchronisees ?
- Faut-il gerer les doublons automatiquement ou via revue manuelle ?
- Quelles donnees sont obligatoires dans chaque systeme ?
- Quels volumes quotidiens sont attendus ?
- Quels SLA de synchronisation sont attendus ?
- Quelle retention des logs est souhaitee ?
- Quels connecteurs doivent etre disponibles au lancement ?
- Les systemes externes disposent-ils d'environnements de test ?

## 16. Risques et points d'attention

| Risque | Impact | Mitigation |
| --- | --- | --- |
| Bidirectionnel mal defini | Donnees incoherentes | Definir source de verite et conflits avant implementation |
| Secrets mal stockes | Risque securite | Utiliser Named Credentials / External Credentials |
| Mappings trop libres | Erreurs difficiles a diagnostiquer | Encadrer les transformations et valider la configuration |
| Volumes importants | Limites Salesforce | Batch/Queueable, pagination, decouplage |
| API externes heterogenes | Complexite connecteurs | Pattern adaptateur et templates par connecteur |
| Logs trop verbeux | Stockage couteux, donnees sensibles | Retention, masquage, niveau de log configurable |
| Absence d'environnement de test | Risque production | Prevoir sandbox et jeux de donnees de test |

## 17. Criteres d'acceptation globaux

L'application sera consideree comme conforme si:

- Un administrateur peut declarer au moins un systeme externe.
- Un administrateur peut configurer au moins un flux et ses mappings.
- Une synchronisation peut etre lancee manuellement.
- Les resultats d'execution sont visibles dans Salesforce.
- Les erreurs sont centralisees, lisibles et relancables.
- Les secrets ne sont pas stockes en clair.
- L'architecture permet d'ajouter un nouveau connecteur sans reecrire le coeur.
- Les traitements longs sont asynchrones.
- Les droits d'acces distinguent administration, monitoring et exploitation.

## 18. Proposition de backlog initial

| Priorite | Epic | Description |
| --- | --- | --- |
| P0 | Socle configuration | Objets de configuration, permissions, services Apex |
| P0 | Console LWC admin | Dashboard, connecteurs, flux, mappings |
| P0 | Orchestrateur sync | Lancement manuel, execution asynchrone, logs |
| P0 | Gestion erreurs | SyncError, detail erreur, retry manuel |
| P0 | Catalogue connecteurs | Brevo, HubSpot, Odoo, ERP majeurs et SaaS courants |
| P1 | Connecteur prioritaire | Brevo/HubSpot via REST ou Odoo dedie selon choix metier |
| P1 | Scheduler | Planification des flux |
| P1 | Retry automatique | Politique de retry configurable |
| P1 | Validation mappings | Controle champs obligatoires et types |
| P2 | Alerting | Emails/notifications/canal externe |
| P2 | Templates | Modeles de mappings par connecteur |
| P2 | Webhooks | Reception d'evenements externes |

## 19. Recommandation d'approche

La meilleure approche consiste a construire d'abord un socle generique Salesforce, puis a ajouter les connecteurs un par un.

Ordre recommande:

1. Cadrer le premier processus metier prioritaire.
2. Definir les objets et la source de verite.
3. Construire le modele de configuration et de logs.
4. Construire la console LWC admin.
5. Implementer un premier connecteur.
6. Ajouter les traitements asynchrones et retries.
7. Industrialiser la supervision.
8. Generaliser vers d'autres connecteurs.

Cette approche evite de figer trop tot l'application autour d'un seul outil comme Odoo ou HubSpot, tout en permettant de livrer rapidement une premiere valeur.

## 20. Questions de cadrage pour la suite

- Quel est le premier systeme externe a connecter: Odoo, HubSpot ou un autre ?
- Quels objets doivent etre synchronises en premier ?
- Le besoin prioritaire est-il Salesforce vers externe, externe vers Salesforce, ou bidirectionnel ?
- Quels volumes sont attendus par jour et par objet ?
- Y a-t-il des contraintes de temps reel ou un batch planifie suffit-il ?
- Dispose-t-on deja des credentials et environnements de test ?
- Faut-il prevoir une distribution sous forme de package Salesforce ?
- Quels profils utilisateurs doivent acceder a l'interface admin ?
- Les erreurs doivent-elles creer automatiquement des tickets support ?
- Quelle est la strategie de gouvernance des donnees personnelles ?
