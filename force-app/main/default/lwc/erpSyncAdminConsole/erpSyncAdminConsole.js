import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getDashboardSummary from '@salesforce/apex/ErpSyncAdminController.getDashboardSummary';
import getSystems from '@salesforce/apex/ErpSyncAdminController.getSystems';
import getConnectorCatalog from '@salesforce/apex/ErpSyncAdminController.getConnectorCatalog';
import installConnectorTemplate from '@salesforce/apex/ErpSyncAdminController.installConnectorTemplate';
import getFlows from '@salesforce/apex/ErpSyncAdminController.getFlows';
import getMappings from '@salesforce/apex/ErpSyncAdminController.getMappings';
import getRecentExecutions from '@salesforce/apex/ErpSyncAdminController.getRecentExecutions';
import getOpenErrors from '@salesforce/apex/ErpSyncAdminController.getOpenErrors';
import getRecordLinks from '@salesforce/apex/ErpSyncAdminController.getRecordLinks';
import getRecordLogs from '@salesforce/apex/ErpSyncAdminController.getRecordLogs';
import startManualSync from '@salesforce/apex/ErpSyncAdminController.startManualSync';
import validateFlowConfiguration from '@salesforce/apex/ErpSyncAdminController.validateFlowConfiguration';
import scheduleRetry from '@salesforce/apex/ErpSyncAdminController.scheduleRetry';
import markErrorResolved from '@salesforce/apex/ErpSyncAdminController.markErrorResolved';
import testConnection from '@salesforce/apex/ErpSyncAdminController.testConnection';
import runDueScheduledFlows from '@salesforce/apex/ErpSyncAdminController.runDueScheduledFlows';
import runDueRetries from '@salesforce/apex/ErpSyncAdminController.runDueRetries';

const EMPTY_SUMMARY = {
    systemCount: 0,
    activeSystemCount: 0,
    flowCount: 0,
    activeFlowCount: 0,
    openErrorCount: 0,
    runningExecutionCount: 0,
    lastExecutionId: null,
    lastExecutionName: null,
    lastExecutionStatus: null,
    lastExecutionUrl: null
};

const HELP_SECTIONS = [
    {
        id: 'sync',
        title: 'Fonctionnement de la synchro',
        summary: 'Une synchronisation part d un flux actif, lit les records Salesforce, construit un payload via les mappings, appelle l API externe, puis journalise le resultat.',
        items: [
            'Connecteur: systeme externe, environnement, URL et Named Credential.',
            'Flux: objet Salesforce, objet externe, endpoint, methode HTTP et payload.',
            'Mappings: champs Salesforce vers champs externes, transformations et champs obligatoires.',
            'Execution: record global avec statut, compteurs, duree et correlation id.',
            'Logs et erreurs: detail par record, retry manuel ou retry planifie.'
        ]
    },
    {
        id: 'auth',
        title: 'Authentification',
        summary: 'ErpSync ne stocke pas les secrets. Les tokens, API keys et flux OAuth restent dans Salesforce Named Credentials / External Credentials.',
        items: [
            'Creer un Named Credential dans Setup avec la base URL du fournisseur.',
            'Configurer l auth: API key, OAuth, Basic ou bearer token selon le connecteur.',
            'Reporter uniquement le nom du Named Credential dans Integration System.',
            'A l execution, Apex appelle callout:NamedCredential + Endpoint Path.',
            'Base URL sans Named Credential sert surtout aux tests non sensibles.'
        ]
    },
    {
        id: 'templates',
        title: 'Pre-remplissage',
        summary: 'Le bouton Installer cree un connecteur, un flux et des mappings de depart en mode inactif pour que le client les ajuste.',
        items: [
            'Installer depuis le catalogue du connecteur choisi.',
            'Modifier Base URL, Named Credential, Endpoint Path et mappings.',
            'Valider le flux depuis la grille Flux.',
            'Activer le systeme et le flux seulement apres validation.',
            'Lancer manuellement une premiere execution de test.'
        ]
    },
    {
        id: 'payload',
        title: 'Payload',
        summary: 'Le mode payload controle le JSON envoye au systeme externe.',
        items: [
            'Envelope: ajoute correlationId, executionId, objets et data.',
            'Raw Mapping: envoie directement les champs mappes.',
            'Root Key: enveloppe les champs sous une cle racine, par exemple customer ou fields.',
            'Les champs externes avec points creent du JSON imbrique, par exemple attributes.FIRSTNAME.',
            'Brevo et HubSpot utilisent souvent Raw Mapping avec des objets imbriques.'
        ]
    }
];

export default class ErpSyncAdminConsole extends NavigationMixin(LightningElement) {
    summary = EMPTY_SUMMARY;
    systems = [];
    connectorCatalog = [];
    flows = [];
    mappings = [];
    executions = [];
    errors = [];
    recordLinks = [];
    recordLogs = [];
    helpSections = HELP_SECTIONS;
    errorMessage;
    isBusy = false;

    wiredSummary;
    wiredSystems;
    wiredConnectorCatalog;
    wiredFlows;
    wiredMappings;
    wiredExecutions;
    wiredErrors;
    wiredRecordLinks;
    wiredRecordLogs;

    systemColumns = [
        {
            label: 'Nom',
            fieldName: 'recordUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'name' }, target: '_self' }
        },
        { label: 'Type', fieldName: 'connectorType' },
        { label: 'Environnement', fieldName: 'environment' },
        { label: 'Statut', fieldName: 'status' },
        { label: 'Named Credential', fieldName: 'namedCredentialName' },
        { label: 'Derniere sync', fieldName: 'lastSuccessfulSync', type: 'date' },
        { label: 'Connexion', fieldName: 'lastConnectionStatus' },
        {
            type: 'button',
            fixedWidth: 120,
            typeAttributes: {
                label: 'Tester',
                name: 'test',
                iconName: 'utility:check',
                variant: 'neutral'
            }
        }
    ];

    flowColumns = [
        {
            label: 'Nom',
            fieldName: 'recordUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'name' }, target: '_self' }
        },
        { label: 'Systeme', fieldName: 'systemName' },
        { label: 'Salesforce', fieldName: 'salesforceObject' },
        { label: 'Externe', fieldName: 'externalObject' },
        { label: 'Sens', fieldName: 'direction' },
        { label: 'Actif', fieldName: 'isActive', type: 'boolean' },
        { label: 'Mode', fieldName: 'triggerMode' },
        { label: 'Frequence', fieldName: 'scheduleFrequencyMinutes', type: 'number' },
        { label: 'HTTP', fieldName: 'httpMethod' },
        { label: 'Payload', fieldName: 'payloadMode' },
        { label: 'Root', fieldName: 'payloadRootKey' },
        { label: 'Endpoint', fieldName: 'endpointPath' },
        {
            type: 'button',
            fixedWidth: 120,
            typeAttributes: {
                label: 'Lancer',
                name: 'start',
                iconName: 'utility:play',
                variant: 'brand-outline',
                disabled: { fieldName: 'runDisabled' }
            }
        },
        {
            type: 'button',
            fixedWidth: 120,
            typeAttributes: {
                label: 'Valider',
                name: 'validate',
                iconName: 'utility:success',
                variant: 'neutral'
            }
        }
    ];

    catalogColumns = [
        { label: 'Connecteur', fieldName: 'connectorType' },
        { label: 'Categorie', fieldName: 'category' },
        { label: 'Adaptateur', fieldName: 'adapter' },
        { label: 'Auth', fieldName: 'auth', wrapText: true },
        { label: 'Named Credential', fieldName: 'suggestedNamedCredentialName' },
        { label: 'Base URL', fieldName: 'baseUrlExample', wrapText: true },
        { label: 'Template', fieldName: 'templateSummary' },
        { label: 'Endpoint', fieldName: 'suggestedEndpointPath', wrapText: true },
        { label: 'Payload', fieldName: 'suggestedPayloadMode' },
        { label: 'Statut', fieldName: 'supportStatus' },
        {
            type: 'button',
            fixedWidth: 125,
            typeAttributes: {
                label: 'Installer',
                name: 'install',
                iconName: 'utility:download',
                variant: 'brand-outline'
            }
        }
    ];

    mappingColumns = [
        {
            label: 'Nom',
            fieldName: 'recordUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'name' }, target: '_self' }
        },
        { label: 'Flux', fieldName: 'flowName' },
        { label: 'Champ Salesforce', fieldName: 'salesforceField' },
        { label: 'Champ externe', fieldName: 'externalField' },
        { label: 'Transformation', fieldName: 'transformType' },
        { label: 'Null', fieldName: 'nullBehavior' },
        { label: 'Cle', fieldName: 'isExternalKey', type: 'boolean' },
        { label: 'Actif', fieldName: 'isActive', type: 'boolean' }
    ];

    executionColumns = [
        {
            label: 'Numero',
            fieldName: 'recordUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'name' }, target: '_self' }
        },
        { label: 'Systeme', fieldName: 'systemName' },
        { label: 'Flux', fieldName: 'flowName' },
        { label: 'Statut', fieldName: 'status' },
        { label: 'Debut', fieldName: 'startedAt', type: 'date' },
        { label: 'Fin', fieldName: 'finishedAt', type: 'date' },
        { label: 'Total', fieldName: 'totalRecords', type: 'number' },
        { label: 'Succes', fieldName: 'successCount', type: 'number' },
        { label: 'Erreurs', fieldName: 'errorCount', type: 'number' }
    ];

    errorColumns = [
        {
            label: 'Numero',
            fieldName: 'recordUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'name' }, target: '_self' }
        },
        { label: 'Systeme', fieldName: 'systemName' },
        { label: 'Flux', fieldName: 'flowName' },
        { label: 'Type', fieldName: 'errorType' },
        { label: 'Statut', fieldName: 'status' },
        { label: 'Message', fieldName: 'errorMessage', wrapText: true },
        { label: 'Retry', fieldName: 'retryCount', type: 'number' },
        {
            type: 'button',
            fixedWidth: 120,
            typeAttributes: {
                label: 'Retry',
                name: 'retry',
                iconName: 'utility:refresh',
                variant: 'neutral',
                disabled: { fieldName: 'retryDisabled' }
            }
        },
        {
            type: 'button',
            fixedWidth: 120,
            typeAttributes: {
                label: 'Resoudre',
                name: 'resolve',
                iconName: 'utility:check',
                variant: 'brand'
            }
        }
    ];

    recordLinkColumns = [
        {
            label: 'Numero',
            fieldName: 'recordUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'name' }, target: '_self' }
        },
        { label: 'Systeme', fieldName: 'systemName' },
        { label: 'Flux', fieldName: 'flowName' },
        { label: 'Objet SF', fieldName: 'salesforceObject' },
        { label: 'Record SF', fieldName: 'salesforceRecordId' },
        { label: 'Objet externe', fieldName: 'externalObject' },
        { label: 'Record externe', fieldName: 'externalRecordId' },
        { label: 'Statut', fieldName: 'lastSyncStatus' },
        { label: 'Derniere sync', fieldName: 'lastSyncedAt', type: 'date' },
        { label: 'Derniere erreur', fieldName: 'lastErrorMessage', wrapText: true }
    ];

    recordLogColumns = [
        {
            label: 'Numero',
            fieldName: 'recordUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'name' }, target: '_self' }
        },
        { label: 'Execution', fieldName: 'executionName' },
        { label: 'Systeme', fieldName: 'systemName' },
        { label: 'Flux', fieldName: 'flowName' },
        { label: 'Record SF', fieldName: 'salesforceRecordId' },
        { label: 'Record externe', fieldName: 'externalRecordId' },
        { label: 'Statut', fieldName: 'status' },
        { label: 'Type erreur', fieldName: 'errorType' },
        { label: 'Message', fieldName: 'message', wrapText: true },
        { label: 'Traite le', fieldName: 'processedAt', type: 'date' }
    ];

    @wire(getDashboardSummary)
    wireSummary(result) {
        this.wiredSummary = result;
        if (result.data) {
            this.summary = { ...EMPTY_SUMMARY, ...result.data };
            this.clearError();
        } else if (result.error) {
            this.handleWireError(result.error);
        }
    }

    @wire(getSystems)
    wireSystems(result) {
        this.wiredSystems = result;
        if (result.data) {
            this.systems = result.data;
            this.clearError();
        } else if (result.error) {
            this.handleWireError(result.error);
        }
    }

    @wire(getConnectorCatalog)
    wireConnectorCatalog(result) {
        this.wiredConnectorCatalog = result;
        if (result.data) {
            this.connectorCatalog = result.data;
            this.clearError();
        } else if (result.error) {
            this.handleWireError(result.error);
        }
    }

    @wire(getFlows)
    wireFlows(result) {
        this.wiredFlows = result;
        if (result.data) {
            this.flows = result.data.map((row) => ({
                ...row,
                runDisabled: !row.isActive
            }));
            this.clearError();
        } else if (result.error) {
            this.handleWireError(result.error);
        }
    }

    @wire(getMappings)
    wireMappings(result) {
        this.wiredMappings = result;
        if (result.data) {
            this.mappings = result.data;
            this.clearError();
        } else if (result.error) {
            this.handleWireError(result.error);
        }
    }

    @wire(getRecentExecutions)
    wireExecutions(result) {
        this.wiredExecutions = result;
        if (result.data) {
            this.executions = result.data;
            this.clearError();
        } else if (result.error) {
            this.handleWireError(result.error);
        }
    }

    @wire(getOpenErrors)
    wireErrors(result) {
        this.wiredErrors = result;
        if (result.data) {
            this.errors = result.data.map((row) => ({
                ...row,
                retryDisabled: !row.isRetryable
            }));
            this.clearError();
        } else if (result.error) {
            this.handleWireError(result.error);
        }
    }

    @wire(getRecordLinks)
    wireRecordLinks(result) {
        this.wiredRecordLinks = result;
        if (result.data) {
            this.recordLinks = result.data;
            this.clearError();
        } else if (result.error) {
            this.handleWireError(result.error);
        }
    }

    @wire(getRecordLogs)
    wireRecordLogs(result) {
        this.wiredRecordLogs = result;
        if (result.data) {
            this.recordLogs = result.data;
            this.clearError();
        } else if (result.error) {
            this.handleWireError(result.error);
        }
    }

    handleNewSystem() {
        this.navigateToNewRecord('IntegrationSystem__c');
    }

    handleNewFlow() {
        this.navigateToNewRecord('IntegrationFlow__c');
    }

    handleNewMapping() {
        this.navigateToNewRecord('IntegrationMapping__c');
    }

    handleRefresh() {
        this.refreshData();
    }

    handleRunDueScheduledFlows() {
        this.isBusy = true;
        runDueScheduledFlows()
            .then((count) => {
                this.showToast('Flux planifies', `${count} execution(s) placee(s) en file.`, 'success');
                return this.refreshData();
            })
            .catch((error) => this.handleActionError(error))
            .finally(() => {
                this.isBusy = false;
            });
    }

    handleRunDueRetries() {
        this.isBusy = true;
        runDueRetries()
            .then((count) => {
                this.showToast('Retries', `${count} retry/retries place(s) en file.`, 'success');
                return this.refreshData();
            })
            .catch((error) => this.handleActionError(error))
            .finally(() => {
                this.isBusy = false;
            });
    }

    handleFlowAction(event) {
        if (event.detail.action.name === 'start') {
            this.runFlow(event.detail.row);
        } else if (event.detail.action.name === 'validate') {
            this.validateFlow(event.detail.row);
        }
    }

    handleSystemAction(event) {
        if (event.detail.action.name === 'test') {
            this.testSystem(event.detail.row);
        }
    }

    handleCatalogAction(event) {
        if (event.detail.action.name === 'install') {
            this.installTemplate(event.detail.row);
        }
    }

    handleErrorAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName === 'retry') {
            this.retryError(row);
        } else if (actionName === 'resolve') {
            this.resolveError(row);
        }
    }

    runFlow(row) {
        this.isBusy = true;
        startManualSync({ flowId: row.id })
            .then(() => {
                this.showToast('Execution creee', 'Le flux a ete place en file.', 'success');
                return this.refreshData();
            })
            .catch((error) => this.handleActionError(error))
            .finally(() => {
                this.isBusy = false;
            });
    }

    validateFlow(row) {
        this.isBusy = true;
        validateFlowConfiguration({ flowId: row.id })
            .then((result) => {
                const variant = result.success ? 'success' : 'error';
                const warningText = result.warnings?.length ? ` Warnings: ${result.warnings.join(' | ')}` : '';
                this.showToast('Validation flux', `${result.message}${warningText}`, variant);
            })
            .catch((error) => this.handleActionError(error))
            .finally(() => {
                this.isBusy = false;
            });
    }

    testSystem(row) {
        this.isBusy = true;
        testConnection({ systemId: row.id })
            .then((result) => {
                const variant = result.success ? 'success' : 'warning';
                this.showToast('Test connexion', result.message, variant);
                return this.refreshData();
            })
            .catch((error) => this.handleActionError(error))
            .finally(() => {
                this.isBusy = false;
            });
    }

    installTemplate(row) {
        this.isBusy = true;
        installConnectorTemplate({ connectorType: row.connectorType })
            .then((result) => {
                this.showToast('Template installe', `${result.message} ${result.mappingCount} mapping(s).`, 'success');
                return this.refreshData().then(() => result);
            })
            .then((result) => {
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result.systemId,
                        objectApiName: 'IntegrationSystem__c',
                        actionName: 'view'
                    }
                });
            })
            .catch((error) => this.handleActionError(error))
            .finally(() => {
                this.isBusy = false;
            });
    }

    retryError(row) {
        this.isBusy = true;
        scheduleRetry({ errorId: row.id })
            .then(() => {
                this.showToast('Retry planifie', 'Une nouvelle tentative a ete programmee.', 'success');
                return this.refreshData();
            })
            .catch((error) => this.handleActionError(error))
            .finally(() => {
                this.isBusy = false;
            });
    }

    resolveError(row) {
        this.isBusy = true;
        markErrorResolved({
            errorId: row.id,
            resolutionNotes: 'Resolved from the ErpSync admin console.'
        })
            .then(() => {
                this.showToast('Erreur resolue', 'L erreur a ete marquee comme resolue.', 'success');
                return this.refreshData();
            })
            .catch((error) => this.handleActionError(error))
            .finally(() => {
                this.isBusy = false;
            });
    }

    refreshData() {
        const refreshes = [
            this.wiredSummary,
            this.wiredSystems,
            this.wiredConnectorCatalog,
            this.wiredFlows,
            this.wiredMappings,
            this.wiredExecutions,
            this.wiredErrors,
            this.wiredRecordLinks,
            this.wiredRecordLogs
        ]
            .filter((wireResult) => wireResult)
            .map((wireResult) => refreshApex(wireResult));

        return Promise.all(refreshes);
    }

    navigateToNewRecord(objectApiName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName,
                actionName: 'new'
            }
        });
    }

    handleWireError(error) {
        this.errorMessage = this.normalizeError(error);
    }

    handleActionError(error) {
        const message = this.normalizeError(error);
        this.errorMessage = message;
        this.showToast('Action impossible', message, 'error');
    }

    clearError() {
        this.errorMessage = undefined;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    normalizeError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(', ');
        }
        return error?.body?.message || error?.message || 'Erreur inattendue.';
    }
}
