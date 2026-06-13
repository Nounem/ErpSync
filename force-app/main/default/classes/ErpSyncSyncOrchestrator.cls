public with sharing class ErpSyncSyncOrchestrator {
    private static final Integer DEFAULT_BATCH_SIZE = 50;
    private static final Integer MAX_BATCH_SIZE = 200;

    public static void run(Id executionId) {
        if (executionId == null) {
            return;
        }

        Datetime startedAt = System.now();
        Long startedMs = startedAt.getTime();
        Integer totalRecords = 0;
        Integer successCount = 0;
        List<SyncError__c> errors = new List<SyncError__c>();
        List<SyncRecordLog__c> recordLogs = new List<SyncRecordLog__c>();
        Map<String, IntegrationRecordLink__c> recordLinksByKey = new Map<String, IntegrationRecordLink__c>();
        SyncExecution__c execution;
        IntegrationFlow__c flow;
        IntegrationSystem__c systemRecord;

        try {
            execution = loadExecution(executionId);
            flow = execution.IntegrationFlow__r;
            if (flow == null) {
                throw new SyncConfigurationException('The sync execution is not linked to an integration flow.');
            }

            systemRecord = flow.IntegrationSystem__r;
            if (systemRecord == null) {
                throw new SyncConfigurationException('The integration flow is not linked to an integration system.');
            }

            validateFlow(flow, systemRecord);

            ErpSyncConnector connector = ErpSyncConnectorFactory.create(systemRecord);
            ErpSyncConnectorResult connectionCheck = connector.checkConnection(systemRecord);
            if (!connectionCheck.success) {
                errors.add(buildGlobalError(execution, flow, systemRecord, connectionCheck));
            } else {
                List<IntegrationMapping__c> mappings = loadMappings(flow.Id);
                List<SObject> sourceRecords = querySourceRecords(flow, mappings);
                totalRecords = sourceRecords.size();

                for (SObject sourceRecord : sourceRecords) {
                    Map<String, Object> payload;
                    try {
                        payload = ErpSyncFieldMapper.toPayload(sourceRecord, mappings);
                        ErpSyncConnectorRequest request = new ErpSyncConnectorRequest(
                            systemRecord,
                            flow,
                            sourceRecord,
                            payload,
                            execution.Id,
                            execution.CorrelationId__c
                        );
                        ErpSyncConnectorResult result = connector.send(request);
                        if (result.success) {
                            successCount++;
                            IntegrationRecordLink__c link = buildRecordLink(
                                execution,
                                flow,
                                systemRecord,
                                sourceRecord,
                                result.externalRecordId,
                                'Success',
                                null
                            );
                            recordLinksByKey.put(link.LinkKey__c, link);
                            recordLogs.add(buildSuccessRecordLog(execution, flow, systemRecord, sourceRecord, payload, result));
                        } else {
                            errors.add(buildRecordError(execution, flow, systemRecord, sourceRecord, payload, result));
                            IntegrationRecordLink__c link = buildRecordLink(
                                execution,
                                flow,
                                systemRecord,
                                sourceRecord,
                                result.externalRecordId,
                                'Error',
                                result.message
                            );
                            recordLinksByKey.put(link.LinkKey__c, link);
                            recordLogs.add(buildFailureRecordLog(execution, flow, systemRecord, sourceRecord, payload, result));
                        }
                    } catch (ErpSyncFieldMapper.MappingException ex) {
                        errors.add(buildExceptionError(execution, flow, systemRecord, sourceRecord, payload, 'Mapping', ex));
                        IntegrationRecordLink__c link = buildRecordLink(
                            execution,
                            flow,
                            systemRecord,
                            sourceRecord,
                            null,
                            'Error',
                            ex.getMessage()
                        );
                        recordLinksByKey.put(link.LinkKey__c, link);
                        recordLogs.add(buildExceptionRecordLog(execution, flow, systemRecord, sourceRecord, payload, 'Mapping', ex));
                    } catch (Exception ex) {
                        errors.add(buildExceptionError(execution, flow, systemRecord, sourceRecord, payload, 'Technical', ex));
                        IntegrationRecordLink__c link = buildRecordLink(
                            execution,
                            flow,
                            systemRecord,
                            sourceRecord,
                            null,
                            'Error',
                            ex.getMessage()
                        );
                        recordLinksByKey.put(link.LinkKey__c, link);
                        recordLogs.add(buildExceptionRecordLog(execution, flow, systemRecord, sourceRecord, payload, 'Technical', ex));
                    }
                }
            }
        } catch (SyncConfigurationException ex) {
            errors.add(buildExceptionError(execution, flow, systemRecord, null, null, 'Mapping', ex));
        } catch (Exception ex) {
            errors.add(buildExceptionError(execution, flow, systemRecord, null, null, 'Technical', ex));
        }

        Datetime finishedAt = System.now();
        String finalStatus = resolveStatus(totalRecords, successCount, errors.size());
        if (!errors.isEmpty()) {
            insert errors;
        }

        if (!recordLinksByKey.isEmpty()) {
            List<IntegrationRecordLink__c> recordLinks = recordLinksByKey.values();
            upsert recordLinks IntegrationRecordLink__c.LinkKey__c;
            attachRecordLinks(recordLogs, recordLinksByKey, flow, systemRecord);
        }

        if (!recordLogs.isEmpty()) {
            insert recordLogs;
        }

        if (execution != null) {
            execution.Status__c = finalStatus;
            execution.StartedAt__c = execution.StartedAt__c == null ? startedAt : execution.StartedAt__c;
            execution.FinishedAt__c = finishedAt;
            execution.TotalRecords__c = totalRecords;
            execution.SuccessCount__c = successCount;
            execution.ErrorCount__c = errors.size();
            execution.DurationMs__c = finishedAt.getTime() - startedMs;
            execution.Summary__c = buildSummary(finalStatus, totalRecords, successCount, errors.size());
            update execution;
        }

        if (flow != null) {
            flow.LastRunAt__c = startedAt;
            update flow;
        }
        if (systemRecord != null && finalStatus == 'Success') {
            systemRecord.LastSuccessfulSync__c = finishedAt;
            update systemRecord;
        }
    }

    private static SyncExecution__c loadExecution(Id executionId) {
        return [
            SELECT Id, Status__c, StartedAt__c, CorrelationId__c,
                IntegrationFlow__c,
                IntegrationFlow__r.Id,
                IntegrationFlow__r.Name,
                IntegrationFlow__r.IntegrationSystem__c,
                IntegrationFlow__r.SalesforceObject__c,
                IntegrationFlow__r.ExternalObject__c,
                IntegrationFlow__r.Direction__c,
                IntegrationFlow__r.IsActive__c,
                IntegrationFlow__r.TriggerMode__c,
                IntegrationFlow__r.BatchSize__c,
                IntegrationFlow__r.EndpointPath__c,
                IntegrationFlow__r.HttpMethod__c,
                IntegrationFlow__r.PayloadMode__c,
                IntegrationFlow__r.PayloadRootKey__c,
                IntegrationFlow__r.IntegrationSystem__r.Id,
                IntegrationFlow__r.IntegrationSystem__r.Name,
                IntegrationFlow__r.IntegrationSystem__r.ConnectorType__c,
                IntegrationFlow__r.IntegrationSystem__r.Status__c,
                IntegrationFlow__r.IntegrationSystem__r.BaseUrl__c,
                IntegrationFlow__r.IntegrationSystem__r.NamedCredentialName__c
            FROM SyncExecution__c
            WHERE Id = :executionId
            LIMIT 1
        ];
    }

    private static void validateFlow(IntegrationFlow__c flow, IntegrationSystem__c systemRecord) {
        if (systemRecord.Status__c != 'Active') {
            throw new SyncConfigurationException('The integration system must be active.');
        }
        if (!flow.IsActive__c) {
            throw new SyncConfigurationException('The integration flow must be active.');
        }
        if (flow.Direction__c != 'Salesforce to External') {
            throw new SyncConfigurationException('Only Salesforce to External flows are supported in this MVP.');
        }
        if (String.isBlank(flow.SalesforceObject__c)) {
            throw new SyncConfigurationException('Salesforce object is required.');
        }
        if (String.isBlank(flow.ExternalObject__c)) {
            throw new SyncConfigurationException('External object is required.');
        }
    }

    private static List<IntegrationMapping__c> loadMappings(Id flowId) {
        List<IntegrationMapping__c> mappings = [
            SELECT Id, Name, SalesforceField__c, ExternalField__c, Direction__c, IsActive__c,
                IsRequired__c, DefaultValue__c, TransformType__c, NullBehavior__c,
                IsExternalKey__c, SortOrder__c
            FROM IntegrationMapping__c
            WHERE IntegrationFlow__c = :flowId
                AND IsActive__c = true
            ORDER BY SortOrder__c, CreatedDate
        ];

        if (mappings.isEmpty()) {
            throw new SyncConfigurationException('At least one active mapping is required.');
        }
        return mappings;
    }

    private static List<SObject> querySourceRecords(IntegrationFlow__c flow, List<IntegrationMapping__c> mappings) {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType sourceType = globalDescribe.get(flow.SalesforceObject__c);
        if (sourceType == null) {
            throw new SyncConfigurationException('Unknown Salesforce object: ' + flow.SalesforceObject__c);
        }

        Schema.DescribeSObjectResult objectDescribe = sourceType.getDescribe();
        if (!objectDescribe.isAccessible()) {
            throw new SyncConfigurationException('No read access to object: ' + flow.SalesforceObject__c);
        }

        Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        Set<String> fields = new Set<String>{ 'Id' };
        for (IntegrationMapping__c mapping : mappings) {
            if (String.isBlank(mapping.SalesforceField__c) || String.isBlank(mapping.ExternalField__c)) {
                throw new SyncConfigurationException('Mapping fields cannot be empty.');
            }
            if (!fieldMap.containsKey(mapping.SalesforceField__c)) {
                throw new SyncConfigurationException('Unknown field: ' + mapping.SalesforceField__c);
            }
            if (!fieldMap.get(mapping.SalesforceField__c).getDescribe().isAccessible()) {
                throw new SyncConfigurationException('No read access to field: ' + mapping.SalesforceField__c);
            }
            fields.add(mapping.SalesforceField__c);
        }

        List<String> fieldNames = new List<String>(fields);
        fieldNames.sort();
        Integer batchSize = resolveBatchSize(flow.BatchSize__c);
        String soql = 'SELECT ' + String.join(fieldNames, ', ') + ' FROM ' + flow.SalesforceObject__c;
        if (fieldMap.containsKey('LastModifiedDate')) {
            soql += ' ORDER BY LastModifiedDate DESC';
        }
        soql += ' LIMIT ' + String.valueOf(batchSize);
        return Database.query(soql);
    }

    private static Integer resolveBatchSize(Decimal configuredBatchSize) {
        Integer batchSize = configuredBatchSize == null ? DEFAULT_BATCH_SIZE : configuredBatchSize.intValue();
        if (batchSize < 1) {
            return 1;
        }
        if (batchSize > MAX_BATCH_SIZE) {
            return MAX_BATCH_SIZE;
        }
        return batchSize;
    }

    private static SyncError__c buildGlobalError(
        SyncExecution__c execution,
        IntegrationFlow__c flow,
        IntegrationSystem__c systemRecord,
        ErpSyncConnectorResult result
    ) {
        SyncError__c errorRecord = baseError(execution, flow, systemRecord);
        errorRecord.ErrorType__c = result.errorType;
        errorRecord.ErrorMessage__c = truncateLongText(result.message);
        errorRecord.TechnicalDetails__c = truncateLongText(result.responseBody);
        errorRecord.IsRetryable__c = result.retryable;
        return errorRecord;
    }

    private static SyncError__c buildRecordError(
        SyncExecution__c execution,
        IntegrationFlow__c flow,
        IntegrationSystem__c systemRecord,
        SObject sourceRecord,
        Map<String, Object> payload,
        ErpSyncConnectorResult result
    ) {
        SyncError__c errorRecord = baseError(execution, flow, systemRecord);
        errorRecord.ErrorType__c = result.errorType;
        errorRecord.ErrorMessage__c = truncateLongText(result.message);
        errorRecord.TechnicalDetails__c = truncateLongText(result.responseBody);
        errorRecord.IsRetryable__c = result.retryable;
        errorRecord.ExternalRecordId__c = result.externalRecordId;
        if (sourceRecord != null) {
            errorRecord.SalesforceRecordId__c = String.valueOf(sourceRecord.get('Id'));
        }
        if (payload != null) {
            errorRecord.Payload__c = truncateLongText(JSON.serialize(payload));
        }
        return errorRecord;
    }

    private static SyncRecordLog__c buildSuccessRecordLog(
        SyncExecution__c execution,
        IntegrationFlow__c flow,
        IntegrationSystem__c systemRecord,
        SObject sourceRecord,
        Map<String, Object> payload,
        ErpSyncConnectorResult result
    ) {
        SyncRecordLog__c log = baseRecordLog(execution, flow, systemRecord, sourceRecord, payload);
        log.Status__c = 'Success';
        log.ExternalRecordId__c = result.externalRecordId;
        log.Message__c = truncateLongText(result.message);
        return log;
    }

    private static SyncRecordLog__c buildFailureRecordLog(
        SyncExecution__c execution,
        IntegrationFlow__c flow,
        IntegrationSystem__c systemRecord,
        SObject sourceRecord,
        Map<String, Object> payload,
        ErpSyncConnectorResult result
    ) {
        SyncRecordLog__c log = baseRecordLog(execution, flow, systemRecord, sourceRecord, payload);
        log.Status__c = 'Error';
        log.ErrorType__c = result.errorType;
        log.ExternalRecordId__c = result.externalRecordId;
        log.Message__c = truncateLongText(result.message);
        return log;
    }

    private static SyncRecordLog__c buildExceptionRecordLog(
        SyncExecution__c execution,
        IntegrationFlow__c flow,
        IntegrationSystem__c systemRecord,
        SObject sourceRecord,
        Map<String, Object> payload,
        String errorType,
        Exception ex
    ) {
        SyncRecordLog__c log = baseRecordLog(execution, flow, systemRecord, sourceRecord, payload);
        log.Status__c = 'Error';
        log.ErrorType__c = errorType;
        log.Message__c = truncateLongText(ex.getMessage());
        return log;
    }

    private static SyncRecordLog__c baseRecordLog(
        SyncExecution__c execution,
        IntegrationFlow__c flow,
        IntegrationSystem__c systemRecord,
        SObject sourceRecord,
        Map<String, Object> payload
    ) {
        SyncRecordLog__c log = new SyncRecordLog__c();
        log.SyncExecution__c = execution == null ? null : execution.Id;
        log.IntegrationFlow__c = flow == null ? null : flow.Id;
        log.IntegrationSystem__c = systemRecord == null ? null : systemRecord.Id;
        log.SalesforceRecordId__c = sourceRecord == null ? null : String.valueOf(sourceRecord.get('Id'));
        log.ProcessedAt__c = System.now();
        log.CorrelationId__c = execution == null ? null : execution.CorrelationId__c;
        log.Payload__c = payload == null ? null : truncateLongText(JSON.serialize(payload));
        return log;
    }

    private static IntegrationRecordLink__c buildRecordLink(
        SyncExecution__c execution,
        IntegrationFlow__c flow,
        IntegrationSystem__c systemRecord,
        SObject sourceRecord,
        String externalRecordId,
        String status,
        String errorMessage
    ) {
        String salesforceRecordId = sourceRecord == null ? null : String.valueOf(sourceRecord.get('Id'));
        IntegrationRecordLink__c link = new IntegrationRecordLink__c();
        link.LinkKey__c = buildLinkKey(systemRecord, flow, salesforceRecordId);
        link.IntegrationSystem__c = systemRecord == null ? null : systemRecord.Id;
        link.IntegrationFlow__c = flow == null ? null : flow.Id;
        link.SalesforceRecordId__c = salesforceRecordId;
        link.SalesforceObject__c = flow == null ? null : flow.SalesforceObject__c;
        if (!String.isBlank(externalRecordId)) {
            link.ExternalRecordId__c = externalRecordId;
        }
        link.ExternalObject__c = flow == null ? null : flow.ExternalObject__c;
        link.LastSyncedAt__c = System.now();
        link.LastSyncStatus__c = status;
        link.LastCorrelationId__c = execution == null ? null : execution.CorrelationId__c;
        link.LastErrorMessage__c = truncateLongText(errorMessage);
        return link;
    }

    private static void attachRecordLinks(
        List<SyncRecordLog__c> recordLogs,
        Map<String, IntegrationRecordLink__c> recordLinksByKey,
        IntegrationFlow__c flow,
        IntegrationSystem__c systemRecord
    ) {
        for (SyncRecordLog__c log : recordLogs) {
            if (String.isBlank(log.SalesforceRecordId__c)) {
                continue;
            }
            String linkKey = buildLinkKey(systemRecord, flow, log.SalesforceRecordId__c);
            IntegrationRecordLink__c link = recordLinksByKey.get(linkKey);
            if (link != null) {
                log.IntegrationRecordLink__c = link.Id;
            }
        }
    }

    private static SyncError__c buildExceptionError(
        SyncExecution__c execution,
        IntegrationFlow__c flow,
        IntegrationSystem__c systemRecord,
        SObject sourceRecord,
        Map<String, Object> payload,
        String errorType,
        Exception ex
    ) {
        SyncError__c errorRecord = baseError(execution, flow, systemRecord);
        errorRecord.ErrorType__c = errorType;
        errorRecord.ErrorMessage__c = truncateLongText(ex.getMessage());
        errorRecord.TechnicalDetails__c = truncateLongText(ex.getStackTraceString());
        errorRecord.IsRetryable__c = errorType != 'Mapping';
        if (sourceRecord != null) {
            errorRecord.SalesforceRecordId__c = String.valueOf(sourceRecord.get('Id'));
        }
        if (payload != null) {
            errorRecord.Payload__c = truncateLongText(JSON.serialize(payload));
        }
        return errorRecord;
    }

    private static SyncError__c baseError(
        SyncExecution__c execution,
        IntegrationFlow__c flow,
        IntegrationSystem__c systemRecord
    ) {
        SyncError__c errorRecord = new SyncError__c();
        errorRecord.SyncExecution__c = execution == null ? null : execution.Id;
        errorRecord.IntegrationFlow__c = flow == null ? null : flow.Id;
        errorRecord.IntegrationSystem__c = systemRecord == null ? null : systemRecord.Id;
        errorRecord.Status__c = 'Open';
        errorRecord.RetryCount__c = 0;
        errorRecord.IsRetryable__c = true;
        errorRecord.CorrelationId__c = execution == null ? null : execution.CorrelationId__c;
        return errorRecord;
    }

    private static String resolveStatus(Integer totalRecords, Integer successCount, Integer errorCount) {
        if (errorCount == 0) {
            return 'Success';
        }
        if (successCount > 0) {
            return 'Partial Success';
        }
        return 'Failed';
    }

    private static String buildSummary(String status, Integer totalRecords, Integer successCount, Integer errorCount) {
        return 'Status=' + status
            + ', total=' + totalRecords
            + ', success=' + successCount
            + ', errors=' + errorCount;
    }

    private static String buildLinkKey(IntegrationSystem__c systemRecord, IntegrationFlow__c flow, String salesforceRecordId) {
        String systemId = systemRecord == null ? 'NO_SYSTEM' : String.valueOf(systemRecord.Id);
        String flowId = flow == null ? 'NO_FLOW' : String.valueOf(flow.Id);
        return systemId + ':' + flowId + ':' + salesforceRecordId;
    }

    private static String truncateLongText(String value) {
        if (value == null || value.length() <= 32768) {
            return value;
        }
        return value.substring(0, 32768);
    }

    private class SyncConfigurationException extends Exception {
    }
}
