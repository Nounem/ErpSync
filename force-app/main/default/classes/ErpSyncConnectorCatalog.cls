public with sharing class ErpSyncConnectorCatalog {
    private static final Set<String> GENERIC_REST_CONNECTOR_TYPES = new Set<String>{
        'Generic REST',
        'HubSpot',
        'Brevo',
        'Business Central',
        'QuickBooks',
        'Xero',
        'Pipedrive',
        'Shopify',
        'WooCommerce',
        'PayPal',
        'Mailchimp',
        'Klaviyo',
        'Zendesk',
        'Freshdesk',
        'Jira',
        'Slack',
        'Notion'
    };

    public static Boolean isGenericRestCompatible(String connectorType) {
        return !String.isBlank(connectorType) && GENERIC_REST_CONNECTOR_TYPES.contains(connectorType);
    }

    public static CatalogItem getItem(String connectorType) {
        if (String.isBlank(connectorType)) {
            return null;
        }
        for (CatalogItem item : listItems()) {
            if (item.connectorType == connectorType) {
                return item;
            }
        }
        return null;
    }

    public static List<CatalogItem> listItems() {
        return new List<CatalogItem>{
            item(
                'Generic REST', 'Technique', 'Generic REST', 'Named Credential / Base URL',
                'https://api.example.com', 'Ready', 'ErpSync_Generic', '/records', 'POST',
                'Envelope', null, 'Account', 'records',
                'Connecteur configurable pour APIs JSON simples.',
                'Creer un Named Credential vers l API cible, puis ajuster endpoint, payload et mappings.',
                accountMappings('name', 'phone', 'website')
            ),
            item(
                'Brevo', 'Marketing / CRM', 'Generic REST', 'API Key ou OAuth via Named Credential',
                'https://api.brevo.com/v3', 'Ready via Generic REST', 'Brevo', '/contacts', 'POST',
                'Raw Mapping', null, 'Contact', 'contacts',
                'Contacts, campagnes, events, eCommerce et objets custom selon endpoint.',
                'Pour les contacts Brevo, garder email au niveau racine et les attributs dans attributes.*.',
                contactMappings('email', 'attributes.FIRSTNAME', 'attributes.LASTNAME', 'attributes.SMS')
            ),
            item(
                'HubSpot', 'CRM / Marketing', 'Generic REST', 'Private app token ou OAuth via Named Credential',
                'https://api.hubapi.com', 'Ready via Generic REST', 'HubSpot', '/crm/v3/objects/contacts', 'POST',
                'Raw Mapping', null, 'Contact', 'contacts',
                'Utiliser le payload properties; les APIs date-versionnees peuvent etre adoptees apres verification.',
                'HubSpot attend un objet properties; les associations seront un connecteur dedie ensuite.',
                contactMappings('properties.email', 'properties.firstname', 'properties.lastname', 'properties.phone')
            ),
            item(
                'Odoo', 'ERP', 'Dedicated planned', 'API key / session selon edition',
                'https://odoo.example.com', 'Adapter planned', 'Odoo', '/jsonrpc', 'POST',
                'Envelope', null, 'Account', 'res.partner',
                'JSON-RPC et logique modele/recordset a traiter dans un adaptateur dedie.',
                'Le template sert de cadrage; le connecteur Odoo dedie devra gerer database, model et method.',
                accountMappings('name', 'phone', 'website')
            ),
            item(
                'Microsoft Dynamics 365', 'ERP / CRM', 'Dedicated planned', 'OAuth via Named Credential',
                'https://your-org.crm.dynamics.com', 'Adapter planned', 'Dynamics365', '/api/data/v9.2/accounts', 'POST',
                'Raw Mapping', null, 'Account', 'accounts',
                'OData, pagination et upsert a normaliser par adaptateur.',
                'Commencer en REST simple si besoin, puis isoler OData et relations dans un adaptateur dedie.',
                accountMappings('name', 'telephone1', 'websiteurl')
            ),
            item(
                'Business Central', 'ERP / Finance', 'Generic REST', 'OAuth via Named Credential',
                'https://api.businesscentral.dynamics.com', 'Ready via Generic REST', 'BusinessCentral', '/v2.0/production/api/v2.0/companies(COMPANY_ID)/customers', 'POST',
                'Raw Mapping', null, 'Account', 'customers',
                'APIs OData utilisables, prevoir conventions par environnement/company.',
                'Renseigner environment et COMPANY_ID dans l endpoint avant activation.',
                accountMappings('displayName', 'phoneNumber', 'website')
            ),
            item(
                'SAP', 'ERP', 'Dedicated planned', 'OAuth/SAML/Basic selon gateway',
                'https://sap.example.com', 'Adapter planned', 'SAP', '/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_BusinessPartner', 'POST',
                'Raw Mapping', null, 'Account', 'A_BusinessPartner',
                'OData/BAPI/PI-PO et securite necessitent un design specifique.',
                'Valider le service SAP expose, le mode auth et les champs obligatoires avant activation.',
                accountMappings('OrganizationBPName1', 'PhoneNumber', 'WebsiteURL')
            ),
            item(
                'Oracle NetSuite', 'ERP / Finance', 'Dedicated planned', 'OAuth 2.0 / Token based auth',
                'https://account.suitetalk.api.netsuite.com', 'Adapter planned', 'NetSuite', '/services/rest/record/v1/customer', 'POST',
                'Raw Mapping', null, 'Account', 'customer',
                'SuiteTalk REST, records et gouvernance API a isoler.',
                'Remplacer account par le compte NetSuite reel et verifier les mandatory fields par record type.',
                accountMappings('companyName', 'phone', 'url')
            ),
            item(
                'Sage', 'ERP / Finance', 'Dedicated planned', 'OAuth via Named Credential',
                'https://api.accounting.sage.com', 'Adapter planned', 'Sage', '/v3.1/contacts', 'POST',
                'Raw Mapping', null, 'Account', 'contacts',
                'Variantes Sage multiples, mapping a cadrer par produit.',
                'Identifier Sage Business Cloud, X3 ou autre produit avant de figer endpoint et payload.',
                accountMappings('name', 'telephone', 'website')
            ),
            item(
                'QuickBooks', 'Comptabilite', 'Generic REST', 'OAuth via Named Credential',
                'https://quickbooks.api.intuit.com', 'Ready via Generic REST', 'QuickBooks', '/v3/company/COMPANY_ID/customer', 'POST',
                'Raw Mapping', null, 'Account', 'Customer',
                'Flux simples possibles, contraintes mineures a gerer par endpoint.',
                'Remplacer COMPANY_ID et verifier les minorversion/headers dans le Named Credential.',
                accountMappings('DisplayName', 'PrimaryPhone.FreeFormNumber', 'WebAddr.URI')
            ),
            item(
                'Xero', 'Comptabilite', 'Generic REST', 'OAuth via Named Credential',
                'https://api.xero.com', 'Ready via Generic REST', 'Xero', '/api.xro/2.0/Contacts', 'POST',
                'Raw Mapping', null, 'Account', 'Contacts',
                'Prevoir tenant id et limites API dans le Named Credential ou endpoint.',
                'Ajouter le header xero-tenant-id dans la configuration auth avant activation.',
                accountMappings('Name', 'Phones.PhoneNumber', 'Website')
            ),
            item(
                'Zoho', 'CRM / Suite', 'Dedicated planned', 'OAuth via Named Credential',
                'https://www.zohoapis.com', 'Adapter planned', 'Zoho', '/crm/v8/Accounts', 'POST',
                'Root Key', 'data', 'Account', 'Accounts',
                'Adapter par region Zoho et module cible; le body officiel attend data comme tableau.',
                'Changer la base URL si le data center Zoho est EU/IN/AU et prevoir un payload array avant activation.',
                accountMappings('Account_Name', 'Phone', 'Website')
            ),
            item(
                'Pipedrive', 'CRM', 'Generic REST', 'API token ou OAuth via Named Credential',
                'https://api.pipedrive.com', 'Ready via Generic REST', 'Pipedrive', '/api/v2/organizations', 'POST',
                'Raw Mapping', null, 'Account', 'organizations',
                'Objets CRM simples via payload JSON.',
                'Utiliser OAuth/Named Credential pour eviter les tokens dans l URL.',
                accountMappings('name', 'phone', 'website')
            ),
            item(
                'Shopify', 'Commerce', 'Generic REST', 'Admin access token via Named Credential',
                'https://your-shop.myshopify.com/admin/api/2026-01', 'Ready with caveat', 'Shopify', '/customers.json', 'POST',
                'Root Key', 'customer', 'Contact', 'customers',
                'REST Admin est legacy; GraphQL est a privilegier pour nouvelles apps publiques.',
                'Remplacer your-shop et preferer GraphQL si le client cree une nouvelle app publique.',
                contactMappings('email', 'first_name', 'last_name', 'phone')
            ),
            item(
                'WooCommerce', 'Commerce', 'Generic REST', 'Consumer key/secret via Named Credential',
                'https://your-store.example.com/wp-json/wc/v3', 'Ready via Generic REST', 'WooCommerce', '/customers', 'POST',
                'Raw Mapping', null, 'Contact', 'customers',
                'Produits, clients et commandes via REST JSON.',
                'Configurer consumer key/secret dans le Named Credential et remplacer le domaine boutique.',
                contactMappings('email', 'first_name', 'last_name', 'billing.phone')
            ),
            item(
                'Stripe', 'Paiement', 'Dedicated planned', 'API key via Named Credential',
                'https://api.stripe.com', 'Adapter planned', 'Stripe', '/v1/customers', 'POST',
                'Raw Mapping', null, 'Account', 'customers',
                'API REST avec corps form-encoded: necessite un mode payload dedie.',
                'Le template documente la cible; un adaptateur Stripe doit encoder le body en form-urlencoded.',
                accountMappings('name', 'phone', 'metadata.website')
            ),
            item(
                'PayPal', 'Paiement', 'Generic REST', 'OAuth via Named Credential',
                'https://api-m.paypal.com', 'Ready via Generic REST', 'PayPal', '/v1/customer/partners/merchant-integrations', 'POST',
                'Raw Mapping', null, 'Account', 'merchant-integrations',
                'Flux JSON possibles, sandbox/live a separer.',
                'Utiliser api-m.sandbox.paypal.com pour recette et api-m.paypal.com pour production.',
                accountMappings('business_name', 'phone', 'website')
            ),
            item(
                'Mailchimp', 'Marketing', 'Generic REST', 'API key via Named Credential',
                'https://us1.api.mailchimp.com/3.0', 'Ready via Generic REST', 'Mailchimp', '/lists/LIST_ID/members', 'POST',
                'Raw Mapping', null, 'Contact', 'members',
                'Audiences, members et tags via endpoints REST.',
                'Remplacer us1 et LIST_ID; completer status via mapping/default ou transformation dediee.',
                contactMappings('email_address', 'merge_fields.FNAME', 'merge_fields.LNAME', 'merge_fields.PHONE')
            ),
            item(
                'Klaviyo', 'Marketing', 'Generic REST', 'Private API key via Named Credential',
                'https://a.klaviyo.com/api', 'Ready via Generic REST', 'Klaviyo', '/profiles', 'POST',
                'Raw Mapping', null, 'Contact', 'profiles',
                'Profils et events avec version API a renseigner dans headers Named Credential.',
                'Ajouter les headers revision et authorization dans le Named Credential.',
                contactMappings('data.attributes.email', 'data.attributes.first_name', 'data.attributes.last_name', 'data.attributes.phone_number')
            ),
            item(
                'Zendesk', 'Support', 'Generic REST', 'OAuth/API token via Named Credential',
                'https://your-subdomain.zendesk.com/api/v2', 'Ready via Generic REST', 'Zendesk', '/organizations.json', 'POST',
                'Root Key', 'organization', 'Account', 'organizations',
                'Tickets, users et organizations via REST JSON.',
                'Remplacer your-subdomain et choisir organizations ou users selon l objet Salesforce source.',
                accountMappings('name', 'phone', 'details')
            ),
            item(
                'Freshdesk', 'Support', 'Generic REST', 'API key via Named Credential',
                'https://your-domain.freshdesk.com/api/v2', 'Ready via Generic REST', 'Freshdesk', '/companies', 'POST',
                'Raw Mapping', null, 'Account', 'companies',
                'Tickets, contacts et companies via REST JSON.',
                'Remplacer your-domain et verifier les champs custom Freshdesk par portail.',
                accountMappings('name', 'phone', 'domains')
            ),
            item(
                'Jira', 'ITSM / Projet', 'Generic REST', 'OAuth/API token via Named Credential',
                'https://your-site.atlassian.net/rest/api/3', 'Ready via Generic REST', 'Jira', '/issue', 'POST',
                'Raw Mapping', null, 'Account', 'issue',
                'Issues et projets avec payload JSON imbrique selon endpoint.',
                'Ajuster project key, issue type et champs obligatoires Jira dans les mappings.',
                accountMappings('fields.summary', 'fields.description', 'fields.customfield_website')
            ),
            item(
                'Slack', 'Collaboration', 'Generic REST', 'Bot token via Named Credential',
                'https://slack.com/api', 'Ready via Generic REST', 'Slack', '/chat.postMessage', 'POST',
                'Raw Mapping', null, 'Account', 'chat.postMessage',
                'Notifications et sync simples, verifier scopes par action.',
                'Prevoir un mapping vers channel et text ou une transformation dediee pour composer le message.',
                accountMappings('text', 'phone', 'website')
            ),
            item(
                'Notion', 'Productivite', 'Generic REST', 'Integration token via Named Credential',
                'https://api.notion.com/v1', 'Ready via Generic REST', 'Notion', '/pages', 'POST',
                'Raw Mapping', null, 'Account', 'pages',
                'Pages/databases avec payload JSON souvent imbrique.',
                'Ajouter Notion-Version en header et adapter parent.database_id avant activation.',
                accountMappings('properties.Name.title.0.text.content', 'properties.Phone.phone_number', 'properties.Website.url')
            ),
            item(
                'Airtable', 'Base de donnees', 'Dedicated planned', 'Personal access token via Named Credential',
                'https://api.airtable.com/v0', 'Adapter planned', 'Airtable', '/BASE_ID/TABLE_ID', 'POST',
                'Raw Mapping', null, 'Account', 'records',
                'Airtable attend un payload records[] avec fields.',
                'Remplacer BASE_ID et TABLE_ID puis prevoir un payload array records avant activation.',
                accountMappings('fields.Name', 'fields.Phone', 'fields.Website')
            ),
            item(
                'Other', 'Autre', 'Generic REST / Dedicated', 'Selon API',
                'https://api.vendor.com', 'Configurable', 'VendorAPI', '/records', 'POST',
                'Envelope', null, 'Account', 'records',
                'Ajouter le type en picklist ou utiliser Generic REST.',
                'Partir du template generic, puis documenter auth, endpoint et payload du fournisseur.',
                accountMappings('name', 'phone', 'website')
            )
        };
    }

    private static CatalogItem item(
        String connectorType,
        String category,
        String adapter,
        String auth,
        String baseUrlExample,
        String supportStatus,
        String suggestedNamedCredentialName,
        String suggestedEndpointPath,
        String suggestedHttpMethod,
        String suggestedPayloadMode,
        String suggestedPayloadRootKey,
        String suggestedSalesforceObject,
        String suggestedExternalObject,
        String notes,
        String guide,
        List<MappingTemplate> mappingTemplates
    ) {
        CatalogItem catalogItem = new CatalogItem();
        catalogItem.connectorType = connectorType;
        catalogItem.category = category;
        catalogItem.adapter = adapter;
        catalogItem.auth = auth;
        catalogItem.baseUrlExample = baseUrlExample;
        catalogItem.supportStatus = supportStatus;
        catalogItem.suggestedNamedCredentialName = suggestedNamedCredentialName;
        catalogItem.suggestedEndpointPath = suggestedEndpointPath;
        catalogItem.suggestedHttpMethod = suggestedHttpMethod;
        catalogItem.suggestedPayloadMode = suggestedPayloadMode;
        catalogItem.suggestedPayloadRootKey = suggestedPayloadRootKey;
        catalogItem.suggestedSalesforceObject = suggestedSalesforceObject;
        catalogItem.suggestedExternalObject = suggestedExternalObject;
        catalogItem.notes = notes;
        catalogItem.guide = guide;
        catalogItem.mappingTemplates = mappingTemplates;
        catalogItem.templateSummary = suggestedSalesforceObject + ' -> ' + suggestedExternalObject;
        catalogItem.mappingSummary = summarizeMappings(mappingTemplates);
        return catalogItem;
    }

    private static List<MappingTemplate> accountMappings(String nameField, String phoneField, String websiteField) {
        return new List<MappingTemplate>{
            mapping('Name', nameField, true, true, 10),
            mapping('Phone', phoneField, false, false, 20),
            mapping('Website', websiteField, false, false, 30)
        };
    }

    private static List<MappingTemplate> contactMappings(String emailField, String firstNameField, String lastNameField, String phoneField) {
        return new List<MappingTemplate>{
            mapping('Email', emailField, true, true, 10),
            mapping('FirstName', firstNameField, false, false, 20),
            mapping('LastName', lastNameField, false, false, 30),
            mapping('Phone', phoneField, false, false, 40)
        };
    }

    private static MappingTemplate mapping(
        String salesforceField,
        String externalField,
        Boolean isRequired,
        Boolean isExternalKey,
        Integer sortOrder
    ) {
        MappingTemplate mappingTemplate = new MappingTemplate();
        mappingTemplate.salesforceField = salesforceField;
        mappingTemplate.externalField = externalField;
        mappingTemplate.isRequired = isRequired;
        mappingTemplate.isExternalKey = isExternalKey;
        mappingTemplate.sortOrder = sortOrder;
        mappingTemplate.transformType = 'Trim';
        mappingTemplate.nullBehavior = isRequired ? 'Error' : 'Ignore';
        return mappingTemplate;
    }

    private static String summarizeMappings(List<MappingTemplate> mappingTemplates) {
        List<String> summaries = new List<String>();
        for (MappingTemplate mappingTemplate : mappingTemplates) {
            summaries.add(mappingTemplate.salesforceField + ' -> ' + mappingTemplate.externalField);
        }
        return String.join(summaries, ', ');
    }

    public class CatalogItem {
        @AuraEnabled public String connectorType;
        @AuraEnabled public String category;
        @AuraEnabled public String adapter;
        @AuraEnabled public String auth;
        @AuraEnabled public String baseUrlExample;
        @AuraEnabled public String supportStatus;
        @AuraEnabled public String suggestedNamedCredentialName;
        @AuraEnabled public String suggestedEndpointPath;
        @AuraEnabled public String suggestedHttpMethod;
        @AuraEnabled public String suggestedPayloadMode;
        @AuraEnabled public String suggestedPayloadRootKey;
        @AuraEnabled public String suggestedSalesforceObject;
        @AuraEnabled public String suggestedExternalObject;
        @AuraEnabled public String templateSummary;
        @AuraEnabled public String mappingSummary;
        @AuraEnabled public String notes;
        @AuraEnabled public String guide;
        @AuraEnabled public List<MappingTemplate> mappingTemplates;
    }

    public class MappingTemplate {
        @AuraEnabled public String salesforceField;
        @AuraEnabled public String externalField;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public Boolean isExternalKey;
        @AuraEnabled public Integer sortOrder;
        @AuraEnabled public String transformType;
        @AuraEnabled public String nullBehavior;
    }
}
