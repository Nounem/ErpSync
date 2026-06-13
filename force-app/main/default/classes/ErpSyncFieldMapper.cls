public with sharing class ErpSyncFieldMapper {
    public static Map<String, Object> toPayload(SObject sourceRecord, List<IntegrationMapping__c> mappings) {
        if (sourceRecord == null) {
            throw new MappingException('Source record is required.');
        }

        Map<String, Object> payload = new Map<String, Object>();
        for (IntegrationMapping__c mapping : mappings) {
            if (mapping == null || !mapping.IsActive__c) {
                continue;
            }

            Object value = sourceRecord.get(mapping.SalesforceField__c);
            if (isEmptyValue(value)) {
                ValueDecision decision = handleEmptyValue(mapping, payload);
                if (decision.skip) {
                    continue;
                }
                value = decision.value;
            } else {
                value = transformValue(value, mapping.TransformType__c);
            }

            putPayloadValue(payload, mapping.ExternalField__c, value);
        }
        return payload;
    }

    private static ValueDecision handleEmptyValue(IntegrationMapping__c mapping, Map<String, Object> payload) {
        if (mapping.NullBehavior__c == 'Use Default') {
            return new ValueDecision(false, transformValue(mapping.DefaultValue__c, mapping.TransformType__c));
        }

        if (mapping.NullBehavior__c == 'Clear Target') {
            putPayloadValue(payload, mapping.ExternalField__c, null);
            return new ValueDecision(true, null);
        }

        if (mapping.NullBehavior__c == 'Error' || mapping.IsRequired__c) {
            throw new MappingException('Required field is empty: ' + mapping.SalesforceField__c);
        }

        return new ValueDecision(true, null);
    }

    private static Object transformValue(Object value, String transformType) {
        if (value == null || String.isBlank(transformType) || transformType == 'None') {
            return value;
        }

        if (transformType == 'Trim') {
            return String.valueOf(value).trim();
        }
        if (transformType == 'Uppercase') {
            return String.valueOf(value).toUpperCase();
        }
        if (transformType == 'Lowercase') {
            return String.valueOf(value).toLowerCase();
        }
        if (transformType == 'Date Format') {
            return String.valueOf(value);
        }

        return value;
    }

    private static Boolean isEmptyValue(Object value) {
        return value == null || (value instanceof String && String.isBlank((String) value));
    }

    private static void putPayloadValue(Map<String, Object> payload, String externalField, Object value) {
        if (String.isBlank(externalField) || !externalField.contains('.')) {
            payload.put(externalField, value);
            return;
        }

        List<String> pathParts = externalField.split('\\.');
        Map<String, Object> currentMap = payload;
        for (Integer index = 0; index < pathParts.size(); index++) {
            String pathPart = pathParts[index];
            if (String.isBlank(pathPart)) {
                throw new MappingException('Invalid external field path: ' + externalField);
            }

            if (index == pathParts.size() - 1) {
                currentMap.put(pathPart, value);
                continue;
            }

            Object existingValue = currentMap.get(pathPart);
            if (existingValue == null) {
                Map<String, Object> childMap = new Map<String, Object>();
                currentMap.put(pathPart, childMap);
                currentMap = childMap;
            } else if (existingValue instanceof Map<String, Object>) {
                currentMap = (Map<String, Object>) existingValue;
            } else {
                throw new MappingException('External field path conflicts with an existing value: ' + externalField);
            }
        }
    }

    public class MappingException extends Exception {
    }

    private class ValueDecision {
        public Boolean skip;
        public Object value;

        public ValueDecision(Boolean skip, Object value) {
            this.skip = skip;
            this.value = value;
        }
    }
}
