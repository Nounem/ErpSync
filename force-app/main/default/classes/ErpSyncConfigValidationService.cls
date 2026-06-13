public with sharing class ErpSyncConfigValidationService {
    public static ValidationResult validateFlow(Id flowId) {
        ValidationResult result = new ValidationResult();
        if (flowId == null) {
            result.addError('A flow id is required.');
            return result;
        }

        IntegrationFlow__c flow = loadFlow(flowId);
        if (flow == null) {
            result.addError('Integration flow was not found.');
            return result;
        }

        validateSystem(flow, result);
        validateFlowBasics(flow, result);

        List<IntegrationMapping__c> mappings = loadMappings(flow.Id);
        validateMappings(flow, mappings, result);

        result.success = result.errors.isEmpty();
        result.message = result.success
            ? 'Configuration valide.'
            : 'Configuration invalide: ' + String.join(result.errors, ' | ');
        return result;
    }

    private static IntegrationFlow__c loadFlow(Id flowId) {
        List<IntegrationFlow__c> flows = [
            SELECT Id, Name, IntegrationSystem__c, SalesforceObject__c, ExternalObject__c,
                Direction__c, IsActive__c, TriggerMode__c, BatchSize__c, EndpointPath__c,
                HttpMethod__c, PayloadMode__c, PayloadRootKey__c, ScheduleFrequencyMinutes__c,
                IntegrationSystem__r.Id,
                IntegrationSystem__r.Name,
                IntegrationSystem__r.ConnectorType__c,
                IntegrationSystem__r.Status__c,
                IntegrationSystem__r.BaseUrl__c,
                IntegrationSystem__r.NamedCredentialName__c
            FROM IntegrationFlow__c
            WHERE Id = :flowId
            LIMIT 1
        ];
        return flows.isEmpty() ? null : flows[0];
    }

    private static List<IntegrationMapping__c> loadMappings(Id flowId) {
        return [
            SELECT Id, Name, SalesforceField__c, ExternalField__c, Direction__c, IsActive__c,
                IsRequired__c, DefaultValue__c, TransformType__c, NullBehavior__c,
                IsExternalKey__c, SortOrder__c
            FROM IntegrationMapping__c
            WHERE IntegrationFlow__c = :flowId
            ORDER BY SortOrder__c, CreatedDate
        ];
    }

    private static void validateSystem(IntegrationFlow__c flow, ValidationResult result) {
        if (flow.IntegrationSystem__c == null || flow.IntegrationSystem__r == null) {
            result.addError('Le flux doit etre rattache a un systeme d integration.');
            return;
        }

        if (flow.IntegrationSystem__r.Status__c != 'Active') {
            result.addWarning('Le systeme d integration n est pas actif.');
        }

        String connectorType = flow.IntegrationSystem__r.ConnectorType__c;
        if (String.isBlank(connectorType)) {
            result.addError('Le type de connecteur est obligatoire.');
            return;
        }

        if (ErpSyncConnectorCatalog.isGenericRestCompatible(connectorType)) {
            if (String.isBlank(flow.IntegrationSystem__r.NamedCredentialName__c)
                && String.isBlank(flow.IntegrationSystem__r.BaseUrl__c)) {
                result.addError(connectorType + ' necessite un Named Credential ou une Base URL.');
            }
            if (connectorType != 'Generic REST') {
                result.addWarning('Le connecteur ' + connectorType + ' utilise l adaptateur Generic REST: verifier endpoint, auth et payload.');
            }
        } else {
            result.addWarning('Le connecteur ' + connectorType + ' est declare dans le catalogue mais necessite un adaptateur dedie.');
        }
    }

    private static void validateFlowBasics(IntegrationFlow__c flow, ValidationResult result) {
        if (!flow.IsActive__c) {
            result.addWarning('Le flux est inactif.');
        }
        if (flow.Direction__c != 'Salesforce to External') {
            result.addError('Seul le sens Salesforce to External est supporte par le moteur MVP.');
        }
        if (String.isBlank(flow.SalesforceObject__c)) {
            result.addError('L objet Salesforce est obligatoire.');
        }
        if (String.isBlank(flow.ExternalObject__c)) {
            result.addError('L objet externe est obligatoire.');
        }
        if (flow.PayloadMode__c == 'Root Key' && String.isBlank(flow.PayloadRootKey__c)) {
            result.addError('Payload Root Key est obligatoire lorsque Payload Mode vaut Root Key.');
        }
        if (flow.BatchSize__c != null && (flow.BatchSize__c < 1 || flow.BatchSize__c > 200)) {
            result.addWarning('La taille de batch sera bornee entre 1 et 200.');
        }
        if (flow.TriggerMode__c == 'Scheduled' && flow.ScheduleFrequencyMinutes__c != null && flow.ScheduleFrequencyMinutes__c < 5) {
            result.addWarning('La frequence planifiee minimale appliquee sera de 5 minutes.');
        }
    }

    private static void validateMappings(IntegrationFlow__c flow, List<IntegrationMapping__c> mappings, ValidationResult result) {
        List<IntegrationMapping__c> activeMappings = new List<IntegrationMapping__c>();
        for (IntegrationMapping__c mapping : mappings) {
            if (mapping.IsActive__c) {
                activeMappings.add(mapping);
            }
        }

        if (activeMappings.isEmpty()) {
            result.addError('Au moins un mapping actif est obligatoire.');
            return;
        }

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType sourceType = globalDescribe.get(flow.SalesforceObject__c);
        if (sourceType == null) {
            result.addError('Objet Salesforce inconnu: ' + flow.SalesforceObject__c);
            return;
        }

        Schema.DescribeSObjectResult objectDescribe = sourceType.getDescribe();
        if (!objectDescribe.isAccessible()) {
            result.addError('Aucun acces lecture sur l objet Salesforce: ' + flow.SalesforceObject__c);
            return;
        }

        Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        Set<String> externalFields = new Set<String>();
        Boolean hasExternalKey = false;
        for (IntegrationMapping__c mapping : activeMappings) {
            validateMapping(flow, mapping, fieldMap, externalFields, result);
            hasExternalKey = hasExternalKey || mapping.IsExternalKey__c;
        }

        if (!hasExternalKey) {
            result.addWarning('Aucun mapping n est marque comme cle externe.');
        }
    }

    private static void validateMapping(
        IntegrationFlow__c flow,
        IntegrationMapping__c mapping,
        Map<String, Schema.SObjectField> fieldMap,
        Set<String> externalFields,
        ValidationResult result
    ) {
        String label = String.isBlank(mapping.Name) ? String.valueOf(mapping.Id) : mapping.Name;
        if (String.isBlank(mapping.SalesforceField__c)) {
            result.addError('Mapping ' + label + ': champ Salesforce obligatoire.');
            return;
        }
        if (String.isBlank(mapping.ExternalField__c)) {
            result.addError('Mapping ' + label + ': champ externe obligatoire.');
            return;
        }
        if (!fieldMap.containsKey(mapping.SalesforceField__c)) {
            result.addError('Mapping ' + label + ': champ Salesforce inconnu ' + mapping.SalesforceField__c + '.');
            return;
        }
        if (!fieldMap.get(mapping.SalesforceField__c).getDescribe().isAccessible()) {
            result.addError('Mapping ' + label + ': pas d acces lecture au champ ' + mapping.SalesforceField__c + '.');
        }
        if (externalFields.contains(mapping.ExternalField__c)) {
            result.addWarning('Le champ externe ' + mapping.ExternalField__c + ' est mappe plusieurs fois.');
        }
        externalFields.add(mapping.ExternalField__c);

        if (mapping.TransformType__c == 'Custom Apex') {
            result.addWarning('La transformation Custom Apex est reservee a une implementation dediee.');
        }
        if (mapping.NullBehavior__c == 'Use Default' && String.isBlank(mapping.DefaultValue__c)) {
            result.addWarning('Mapping ' + label + ': Use Default est configure sans valeur par defaut.');
        }
    }

    public class ValidationResult {
        @AuraEnabled public Boolean success = true;
        @AuraEnabled public String message;
        @AuraEnabled public List<String> errors = new List<String>();
        @AuraEnabled public List<String> warnings = new List<String>();

        public void addError(String error) {
            errors.add(error);
            success = false;
        }

        public void addWarning(String warning) {
            warnings.add(warning);
        }
    }
}
