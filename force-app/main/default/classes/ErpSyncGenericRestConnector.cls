public with sharing class ErpSyncGenericRestConnector implements ErpSyncConnector {
    private static final Integer TIMEOUT_MS = 60000;

    public ErpSyncConnectorResult send(ErpSyncConnectorRequest request) {
        if (request == null || request.systemRecord == null || request.flow == null) {
            return ErpSyncConnectorResult.failure('Mapping', 'Connector request is incomplete.', false, null, null);
        }

        String endpoint = buildEndpoint(request.systemRecord, request.flow);
        if (String.isBlank(endpoint)) {
            return ErpSyncConnectorResult.failure(
                'Authentication',
                'A Named Credential or Base URL is required for this REST connector.',
                false,
                null,
                null
            );
        }

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(endpoint);
        httpRequest.setMethod(resolveMethod(request.flow.HttpMethod__c));
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setTimeout(TIMEOUT_MS);
        httpRequest.setBody(JSON.serialize(buildBody(request)));

        try {
            HttpResponse response = new Http().send(httpRequest);
            Integer statusCode = response.getStatusCode();
            String body = response.getBody();
            if (statusCode >= 200 && statusCode < 300) {
                return ErpSyncConnectorResult.success(
                    statusCode,
                    response.getStatus(),
                    body,
                    extractExternalRecordId(body)
                );
            }
            return ErpSyncConnectorResult.failure(
                classifyHttpError(statusCode),
                response.getStatus(),
                isRetryable(statusCode),
                statusCode,
                body
            );
        } catch (CalloutException ex) {
            return ErpSyncConnectorResult.failure('Network', ex.getMessage(), true, null, null);
        }
    }

    public ErpSyncConnectorResult checkConnection(IntegrationSystem__c systemRecord) {
        if (systemRecord == null) {
            return ErpSyncConnectorResult.failure('Authentication', 'Integration system is missing.', false, null, null);
        }
        if (String.isBlank(systemRecord.NamedCredentialName__c) && String.isBlank(systemRecord.BaseUrl__c)) {
            return ErpSyncConnectorResult.failure(
                'Authentication',
                'A Named Credential or Base URL is required for this REST connector.',
                false,
                null,
                null
            );
        }
        return ErpSyncConnectorResult.success(null, 'Generic REST configuration is present.', null, null);
    }

    private static Object buildBody(ErpSyncConnectorRequest request) {
        if (request.flow.PayloadMode__c == 'Raw Mapping') {
            return request.payload;
        }

        if (request.flow.PayloadMode__c == 'Root Key' && !String.isBlank(request.flow.PayloadRootKey__c)) {
            Map<String, Object> rootedBody = new Map<String, Object>();
            rootedBody.put(request.flow.PayloadRootKey__c.trim(), request.payload);
            return rootedBody;
        }

        Map<String, Object> body = new Map<String, Object>();
        body.put('correlationId', request.correlationId);
        body.put('executionId', request.executionId);
        body.put('salesforceObject', request.flow.SalesforceObject__c);
        body.put('externalObject', request.flow.ExternalObject__c);
        body.put('salesforceRecordId', request.sourceRecord == null ? null : request.sourceRecord.get('Id'));
        body.put('data', request.payload);
        return body;
    }

    private static String buildEndpoint(IntegrationSystem__c systemRecord, IntegrationFlow__c flow) {
        String base;
        if (!String.isBlank(systemRecord.NamedCredentialName__c)) {
            base = 'callout:' + systemRecord.NamedCredentialName__c.trim();
        } else {
            base = systemRecord.BaseUrl__c;
        }

        if (String.isBlank(base)) {
            return null;
        }

        String path = String.isBlank(flow.EndpointPath__c) ? '' : flow.EndpointPath__c.trim();
        if (String.isBlank(path)) {
            return base;
        }
        return base.endsWith('/') || path.startsWith('/') ? base + path : base + '/' + path;
    }

    private static String resolveMethod(String configuredMethod) {
        return String.isBlank(configuredMethod) ? 'POST' : configuredMethod;
    }

    private static String classifyHttpError(Integer statusCode) {
        if (statusCode == 401 || statusCode == 403) {
            return 'Authentication';
        }
        if (statusCode == 409) {
            return 'Conflict';
        }
        if (statusCode == 429) {
            return 'Quota';
        }
        if (statusCode >= 400 && statusCode < 500) {
            return 'External Validation';
        }
        if (statusCode >= 500) {
            return 'Network';
        }
        return 'Technical';
    }

    private static Boolean isRetryable(Integer statusCode) {
        return statusCode == 408 || statusCode == 409 || statusCode == 429 || statusCode >= 500;
    }

    private static String extractExternalRecordId(String body) {
        if (String.isBlank(body)) {
            return null;
        }

        try {
            Object parsed = JSON.deserializeUntyped(body);
            Map<String, Object> parsedMap = (Map<String, Object>) parsed;
            if (parsedMap.containsKey('id')) {
                return String.valueOf(parsedMap.get('id'));
            }
            if (parsedMap.containsKey('externalId')) {
                return String.valueOf(parsedMap.get('externalId'));
            }
        } catch (Exception ex) {
            return null;
        }
        return null;
    }
}
