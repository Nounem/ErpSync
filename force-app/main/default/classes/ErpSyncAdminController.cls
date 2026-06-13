public with sharing class ErpSyncAdminController {
    private static final Integer MAX_ROWS = 200;

    @AuraEnabled(cacheable=true)
    public static DashboardSummary getDashboardSummary() {
        requireReadable(IntegrationSystem__c.SObjectType);
        requireReadable(IntegrationFlow__c.SObjectType);
        requireReadable(SyncExecution__c.SObjectType);
        requireReadable(SyncError__c.SObjectType);

        DashboardSummary summary = new DashboardSummary();
        summary.systemCount = [SELECT COUNT() FROM IntegrationSystem__c];
        summary.activeSystemCount = [SELECT COUNT() FROM IntegrationSystem__c WHERE Status__c = 'Active'];
        summary.flowCount = [SELECT COUNT() FROM IntegrationFlow__c];
        summary.activeFlowCount = [SELECT COUNT() FROM IntegrationFlow__c WHERE IsActive__c = true];
        summary.openErrorCount = [
            SELECT COUNT()
            FROM SyncError__c
            WHERE Status__c IN ('Open', 'Retry Scheduled', 'Quarantined')
        ];
        summary.runningExecutionCount = [
            SELECT COUNT()
            FROM SyncExecution__c
            WHERE Status__c IN ('Queued', 'Running')
        ];

        List<SyncExecution__c> lastExecutions = [
            SELECT Id, Name, Status__c, StartedAt__c, FinishedAt__c
            FROM SyncExecution__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (!lastExecutions.isEmpty()) {
            SyncExecution__c lastExecution = lastExecutions[0];
            summary.lastExecutionId = lastExecution.Id;
            summary.lastExecutionName = lastExecution.Name;
            summary.lastExecutionStatus = lastExecution.Status__c;
            summary.lastExecutionAt = lastExecution.StartedAt__c;
            summary.lastExecutionUrl = buildRecordUrl(lastExecution.Id);
        }

        return summary;
    }

    @AuraEnabled(cacheable=true)
    public static List<SystemRow> getSystems() {
        requireReadable(IntegrationSystem__c.SObjectType);

        List<IntegrationSystem__c> systems = [
            SELECT Id, Name, ConnectorType__c, Environment__c, Status__c, BaseUrl__c,
                NamedCredentialName__c, LastSuccessfulSync__c, LastConnectionStatus__c,
                LastConnectionCheckAt__c
            FROM IntegrationSystem__c
            ORDER BY LastModifiedDate DESC
            LIMIT :MAX_ROWS
        ];

        List<SystemRow> rows = new List<SystemRow>();
        for (IntegrationSystem__c systemRecord : systems) {
            SystemRow row = new SystemRow();
            row.id = systemRecord.Id;
            row.name = systemRecord.Name;
            row.recordUrl = buildRecordUrl(systemRecord.Id);
            row.connectorType = systemRecord.ConnectorType__c;
            row.environment = systemRecord.Environment__c;
            row.status = systemRecord.Status__c;
            row.baseUrl = systemRecord.BaseUrl__c;
            row.namedCredentialName = systemRecord.NamedCredentialName__c;
            row.lastSuccessfulSync = systemRecord.LastSuccessfulSync__c;
            row.lastConnectionStatus = systemRecord.LastConnectionStatus__c;
            row.lastConnectionCheckAt = systemRecord.LastConnectionCheckAt__c;
            rows.add(row);
        }
        return rows;
    }

    @AuraEnabled(cacheable=true)
    public static List<FlowRow> getFlows() {
        requireReadable(IntegrationFlow__c.SObjectType);

        List<IntegrationFlow__c> flows = [
            SELECT Id, Name, IntegrationSystem__c, IntegrationSystem__r.Name,
                SalesforceObject__c, ExternalObject__c, Direction__c, IsActive__c,
                TriggerMode__c, BatchSize__c, ConflictStrategy__c, EndpointPath__c,
                HttpMethod__c, PayloadMode__c, PayloadRootKey__c,
                ScheduleFrequencyMinutes__c, LastRunAt__c, NextRunAt__c
            FROM IntegrationFlow__c
            ORDER BY LastModifiedDate DESC
            LIMIT :MAX_ROWS
        ];

        List<FlowRow> rows = new List<FlowRow>();
        for (IntegrationFlow__c flow : flows) {
            FlowRow row = new FlowRow();
            row.id = flow.Id;
            row.name = flow.Name;
            row.recordUrl = buildRecordUrl(flow.Id);
            row.integrationSystemId = flow.IntegrationSystem__c;
            row.systemName = flow.IntegrationSystem__r == null ? null : flow.IntegrationSystem__r.Name;
            row.salesforceObject = flow.SalesforceObject__c;
            row.externalObject = flow.ExternalObject__c;
            row.direction = flow.Direction__c;
            row.isActive = flow.IsActive__c;
            row.triggerMode = flow.TriggerMode__c;
            row.batchSize = flow.BatchSize__c;
            row.conflictStrategy = flow.ConflictStrategy__c;
            row.endpointPath = flow.EndpointPath__c;
            row.httpMethod = flow.HttpMethod__c;
            row.payloadMode = flow.PayloadMode__c;
            row.payloadRootKey = flow.PayloadRootKey__c;
            row.scheduleFrequencyMinutes = flow.ScheduleFrequencyMinutes__c;
            row.lastRunAt = flow.LastRunAt__c;
            row.nextRunAt = flow.NextRunAt__c;
            rows.add(row);
        }
        return rows;
    }

    @AuraEnabled(cacheable=true)
    public static List<ErpSyncConnectorCatalog.CatalogItem> getConnectorCatalog() {
        return ErpSyncConnectorCatalog.listItems();
    }

    @AuraEnabled
    public static TemplateInstallResult installConnectorTemplate(String connectorType) {
        if (String.isBlank(connectorType)) {
            throw new AuraHandledException('A connector type is required to install a template.');
        }
        requireCreateable(IntegrationSystem__c.SObjectType);
        requireCreateable(IntegrationFlow__c.SObjectType);
        requireCreateable(IntegrationMapping__c.SObjectType);

        ErpSyncConnectorCatalog.CatalogItem template = ErpSyncConnectorCatalog.getItem(connectorType);
        if (template == null) {
            throw new AuraHandledException('No connector template found for ' + connectorType + '.');
        }

        String suffix = String.valueOf(Datetime.now().getTime());
        IntegrationSystem__c systemRecord = new IntegrationSystem__c(
            Name = truncateText(template.connectorType + ' Template ' + suffix, 80),
            ConnectorType__c = template.connectorType,
            Environment__c = 'Sandbox',
            Status__c = 'Inactive',
            BaseUrl__c = template.baseUrlExample,
            NamedCredentialName__c = template.suggestedNamedCredentialName,
            DefaultBatchSize__c = 50,
            Notes__c = buildTemplateNotes(template)
        );
        insert systemRecord;

        IntegrationFlow__c flow = new IntegrationFlow__c(
            Name = truncateText(template.connectorType + ' - ' + template.templateSummary, 80),
            IntegrationSystem__c = systemRecord.Id,
            SalesforceObject__c = template.suggestedSalesforceObject,
            ExternalObject__c = template.suggestedExternalObject,
            Direction__c = 'Salesforce to External',
            IsActive__c = false,
            TriggerMode__c = 'Manual',
            EndpointPath__c = template.suggestedEndpointPath,
            HttpMethod__c = template.suggestedHttpMethod,
            PayloadMode__c = template.suggestedPayloadMode,
            PayloadRootKey__c = template.suggestedPayloadRootKey,
            BatchSize__c = 50,
            ConflictStrategy__c = 'Salesforce Wins',
            RetryMaxAttempts__c = 3,
            RetryDelayMinutes__c = 15
        );
        insert flow;

        List<IntegrationMapping__c> mappings = new List<IntegrationMapping__c>();
        for (ErpSyncConnectorCatalog.MappingTemplate mappingTemplate : template.mappingTemplates) {
            mappings.add(new IntegrationMapping__c(
                Name = truncateText(mappingTemplate.salesforceField + ' to ' + mappingTemplate.externalField, 80),
                IntegrationFlow__c = flow.Id,
                SalesforceField__c = mappingTemplate.salesforceField,
                ExternalField__c = mappingTemplate.externalField,
                Direction__c = 'Inherit From Flow',
                IsActive__c = true,
                IsRequired__c = mappingTemplate.isRequired,
                IsExternalKey__c = mappingTemplate.isExternalKey,
                TransformType__c = mappingTemplate.transformType,
                NullBehavior__c = mappingTemplate.nullBehavior,
                SortOrder__c = mappingTemplate.sortOrder
            ));
        }
        insert mappings;

        TemplateInstallResult result = new TemplateInstallResult();
        result.systemId = systemRecord.Id;
        result.flowId = flow.Id;
        result.mappingCount = mappings.size();
        result.systemUrl = buildRecordUrl(systemRecord.Id);
        result.flowUrl = buildRecordUrl(flow.Id);
        result.message = 'Template ' + template.connectorType + ' installe: connecteur et flux crees en inactif.';
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<MappingRow> getMappings() {
        requireReadable(IntegrationMapping__c.SObjectType);

        List<IntegrationMapping__c> mappings = [
            SELECT Id, Name, IntegrationFlow__c, IntegrationFlow__r.Name,
                SalesforceField__c, ExternalField__c, Direction__c, IsActive__c,
                IsRequired__c, TransformType__c, NullBehavior__c, IsExternalKey__c,
                SortOrder__c
            FROM IntegrationMapping__c
            ORDER BY IntegrationFlow__c, SortOrder__c, LastModifiedDate DESC
            LIMIT :MAX_ROWS
        ];

        List<MappingRow> rows = new List<MappingRow>();
        for (IntegrationMapping__c mapping : mappings) {
            MappingRow row = new MappingRow();
            row.id = mapping.Id;
            row.name = mapping.Name;
            row.recordUrl = buildRecordUrl(mapping.Id);
            row.integrationFlowId = mapping.IntegrationFlow__c;
            row.flowName = mapping.IntegrationFlow__r == null ? null : mapping.IntegrationFlow__r.Name;
            row.salesforceField = mapping.SalesforceField__c;
            row.externalField = mapping.ExternalField__c;
            row.direction = mapping.Direction__c;
            row.isActive = mapping.IsActive__c;
            row.isRequired = mapping.IsRequired__c;
            row.transformType = mapping.TransformType__c;
            row.nullBehavior = mapping.NullBehavior__c;
            row.isExternalKey = mapping.IsExternalKey__c;
            row.sortOrder = mapping.SortOrder__c;
            rows.add(row);
        }
        return rows;
    }

    @AuraEnabled(cacheable=true)
    public static List<ExecutionRow> getRecentExecutions() {
        requireReadable(SyncExecution__c.SObjectType);

        List<SyncExecution__c> executions = [
            SELECT Id, Name, IntegrationSystem__c, IntegrationSystem__r.Name,
                IntegrationFlow__c, IntegrationFlow__r.Name, Status__c, StartedAt__c,
                FinishedAt__c, TotalRecords__c, SuccessCount__c, ErrorCount__c,
                DurationMs__c, CorrelationId__c
            FROM SyncExecution__c
            ORDER BY CreatedDate DESC
            LIMIT :MAX_ROWS
        ];

        List<ExecutionRow> rows = new List<ExecutionRow>();
        for (SyncExecution__c execution : executions) {
            ExecutionRow row = new ExecutionRow();
            row.id = execution.Id;
            row.name = execution.Name;
            row.recordUrl = buildRecordUrl(execution.Id);
            row.integrationSystemId = execution.IntegrationSystem__c;
            row.systemName = execution.IntegrationSystem__r == null ? null : execution.IntegrationSystem__r.Name;
            row.integrationFlowId = execution.IntegrationFlow__c;
            row.flowName = execution.IntegrationFlow__r == null ? null : execution.IntegrationFlow__r.Name;
            row.status = execution.Status__c;
            row.startedAt = execution.StartedAt__c;
            row.finishedAt = execution.FinishedAt__c;
            row.totalRecords = execution.TotalRecords__c;
            row.successCount = execution.SuccessCount__c;
            row.errorCount = execution.ErrorCount__c;
            row.durationMs = execution.DurationMs__c;
            row.correlationId = execution.CorrelationId__c;
            rows.add(row);
        }
        return rows;
    }

    @AuraEnabled(cacheable=true)
    public static List<ErrorRow> getOpenErrors() {
        requireReadable(SyncError__c.SObjectType);

        List<SyncError__c> errors = [
            SELECT Id, Name, SyncExecution__c, SyncExecution__r.Name,
                IntegrationSystem__c, IntegrationSystem__r.Name, IntegrationFlow__c,
                IntegrationFlow__r.Name, Status__c, ErrorType__c, ErrorMessage__c,
                SalesforceRecordId__c, ExternalRecordId__c, RetryCount__c,
                IsRetryable__c, NextRetryAt__c, RetryExecution__c, CorrelationId__c
            FROM SyncError__c
            WHERE Status__c IN ('Open', 'Retry Scheduled', 'Quarantined')
            ORDER BY CreatedDate DESC
            LIMIT :MAX_ROWS
        ];

        List<ErrorRow> rows = new List<ErrorRow>();
        for (SyncError__c errorRecord : errors) {
            ErrorRow row = new ErrorRow();
            row.id = errorRecord.Id;
            row.name = errorRecord.Name;
            row.recordUrl = buildRecordUrl(errorRecord.Id);
            row.syncExecutionId = errorRecord.SyncExecution__c;
            row.executionName = errorRecord.SyncExecution__r == null ? null : errorRecord.SyncExecution__r.Name;
            row.integrationSystemId = errorRecord.IntegrationSystem__c;
            row.systemName = errorRecord.IntegrationSystem__r == null ? null : errorRecord.IntegrationSystem__r.Name;
            row.integrationFlowId = errorRecord.IntegrationFlow__c;
            row.flowName = errorRecord.IntegrationFlow__r == null ? null : errorRecord.IntegrationFlow__r.Name;
            row.status = errorRecord.Status__c;
            row.errorType = errorRecord.ErrorType__c;
            row.errorMessage = errorRecord.ErrorMessage__c;
            row.salesforceRecordId = errorRecord.SalesforceRecordId__c;
            row.externalRecordId = errorRecord.ExternalRecordId__c;
            row.retryCount = errorRecord.RetryCount__c;
            row.isRetryable = errorRecord.IsRetryable__c;
            row.nextRetryAt = errorRecord.NextRetryAt__c;
            row.retryExecutionId = errorRecord.RetryExecution__c;
            row.correlationId = errorRecord.CorrelationId__c;
            rows.add(row);
        }
        return rows;
    }

    @AuraEnabled(cacheable=true)
    public static List<RecordLinkRow> getRecordLinks() {
        requireReadable(IntegrationRecordLink__c.SObjectType);

        List<IntegrationRecordLink__c> links = [
            SELECT Id, Name, IntegrationSystem__c, IntegrationSystem__r.Name,
                IntegrationFlow__c, IntegrationFlow__r.Name, SalesforceObject__c,
                SalesforceRecordId__c, ExternalObject__c, ExternalRecordId__c,
                LastSyncStatus__c, LastSyncedAt__c, LastErrorMessage__c,
                LastCorrelationId__c
            FROM IntegrationRecordLink__c
            ORDER BY LastSyncedAt__c DESC NULLS LAST, LastModifiedDate DESC
            LIMIT :MAX_ROWS
        ];

        List<RecordLinkRow> rows = new List<RecordLinkRow>();
        for (IntegrationRecordLink__c link : links) {
            RecordLinkRow row = new RecordLinkRow();
            row.id = link.Id;
            row.name = link.Name;
            row.recordUrl = buildRecordUrl(link.Id);
            row.systemName = link.IntegrationSystem__r == null ? null : link.IntegrationSystem__r.Name;
            row.flowName = link.IntegrationFlow__r == null ? null : link.IntegrationFlow__r.Name;
            row.salesforceObject = link.SalesforceObject__c;
            row.salesforceRecordId = link.SalesforceRecordId__c;
            row.externalObject = link.ExternalObject__c;
            row.externalRecordId = link.ExternalRecordId__c;
            row.lastSyncStatus = link.LastSyncStatus__c;
            row.lastSyncedAt = link.LastSyncedAt__c;
            row.lastErrorMessage = link.LastErrorMessage__c;
            row.lastCorrelationId = link.LastCorrelationId__c;
            rows.add(row);
        }
        return rows;
    }

    @AuraEnabled(cacheable=true)
    public static List<RecordLogRow> getRecordLogs() {
        requireReadable(SyncRecordLog__c.SObjectType);

        List<SyncRecordLog__c> logs = [
            SELECT Id, Name, SyncExecution__c, SyncExecution__r.Name,
                IntegrationSystem__c, IntegrationSystem__r.Name, IntegrationFlow__c,
                IntegrationFlow__r.Name, IntegrationRecordLink__c,
                SalesforceRecordId__c, ExternalRecordId__c, Status__c, ErrorType__c,
                Message__c, ProcessedAt__c, CorrelationId__c
            FROM SyncRecordLog__c
            ORDER BY ProcessedAt__c DESC NULLS LAST, CreatedDate DESC
            LIMIT :MAX_ROWS
        ];

        List<RecordLogRow> rows = new List<RecordLogRow>();
        for (SyncRecordLog__c log : logs) {
            RecordLogRow row = new RecordLogRow();
            row.id = log.Id;
            row.name = log.Name;
            row.recordUrl = buildRecordUrl(log.Id);
            row.executionName = log.SyncExecution__r == null ? null : log.SyncExecution__r.Name;
            row.systemName = log.IntegrationSystem__r == null ? null : log.IntegrationSystem__r.Name;
            row.flowName = log.IntegrationFlow__r == null ? null : log.IntegrationFlow__r.Name;
            row.integrationRecordLinkId = log.IntegrationRecordLink__c;
            row.salesforceRecordId = log.SalesforceRecordId__c;
            row.externalRecordId = log.ExternalRecordId__c;
            row.status = log.Status__c;
            row.errorType = log.ErrorType__c;
            row.message = log.Message__c;
            row.processedAt = log.ProcessedAt__c;
            row.correlationId = log.CorrelationId__c;
            rows.add(row);
        }
        return rows;
    }

    @AuraEnabled
    public static Id startManualSync(Id flowId) {
        if (flowId == null) {
            throw new AuraHandledException('A flow id is required to start a manual synchronization.');
        }
        requireCreateable(SyncExecution__c.SObjectType);
        requireUpdateable(IntegrationFlow__c.SObjectType);

        IntegrationFlow__c flow = [
            SELECT Id, Name, IntegrationSystem__c, IsActive__c
            FROM IntegrationFlow__c
            WHERE Id = :flowId
            LIMIT 1
        ];

        if (!flow.IsActive__c) {
            throw new AuraHandledException('Only active flows can be started manually.');
        }

        return ErpSyncExecutionService.queueFlow(
            flow.Id,
            'Manual execution queued from the ErpSync admin console.'
        );
    }

    @AuraEnabled
    public static ErpSyncConfigValidationService.ValidationResult validateFlowConfiguration(Id flowId) {
        if (flowId == null) {
            throw new AuraHandledException('A flow id is required to validate configuration.');
        }
        requireReadable(IntegrationFlow__c.SObjectType);
        requireReadable(IntegrationMapping__c.SObjectType);
        return ErpSyncConfigValidationService.validateFlow(flowId);
    }

    @AuraEnabled
    public static Id scheduleRetry(Id errorId) {
        if (errorId == null) {
            throw new AuraHandledException('An error id is required to schedule a retry.');
        }
        requireUpdateable(SyncError__c.SObjectType);

        SyncError__c errorRecord = [
            SELECT Id, RetryCount__c, IntegrationFlow__r.RetryDelayMinutes__c
            FROM SyncError__c
            WHERE Id = :errorId
            LIMIT 1
        ];

        Decimal retryCount = errorRecord.RetryCount__c == null ? 0 : errorRecord.RetryCount__c;
        Integer retryDelay = errorRecord.IntegrationFlow__r == null || errorRecord.IntegrationFlow__r.RetryDelayMinutes__c == null
            ? 15
            : errorRecord.IntegrationFlow__r.RetryDelayMinutes__c.intValue();
        retryDelay = retryDelay < 1 ? 1 : retryDelay;
        errorRecord.Status__c = 'Retry Scheduled';
        errorRecord.RetryCount__c = retryCount + 1;
        errorRecord.LastRetryAt__c = System.now();
        errorRecord.NextRetryAt__c = System.now().addMinutes(retryDelay);
        update errorRecord;
        return errorRecord.Id;
    }

    @AuraEnabled
    public static Integer runDueScheduledFlows() {
        requireCreateable(SyncExecution__c.SObjectType);
        requireUpdateable(IntegrationFlow__c.SObjectType);
        return ErpSyncScheduleService.runDueScheduledFlows().size();
    }

    @AuraEnabled
    public static Integer runDueRetries() {
        requireCreateable(SyncExecution__c.SObjectType);
        requireUpdateable(SyncError__c.SObjectType);
        return ErpSyncRetryService.runDueRetries().size();
    }

    @AuraEnabled
    public static ConnectionCheckResult testConnection(Id systemId) {
        if (systemId == null) {
            throw new AuraHandledException('A system id is required to test a connection.');
        }
        requireUpdateable(IntegrationSystem__c.SObjectType);

        IntegrationSystem__c systemRecord = [
            SELECT Id, Name, ConnectorType__c, BaseUrl__c, NamedCredentialName__c
            FROM IntegrationSystem__c
            WHERE Id = :systemId
            LIMIT 1
        ];

        ErpSyncConnector connector = ErpSyncConnectorFactory.create(systemRecord);
        ErpSyncConnectorResult connectorResult = connector.checkConnection(systemRecord);

        systemRecord.LastConnectionCheckAt__c = System.now();
        systemRecord.LastConnectionStatus__c = connectorResult.success ? 'Success' : 'Failed';
        update systemRecord;

        ConnectionCheckResult result = new ConnectionCheckResult();
        result.systemId = systemRecord.Id;
        result.success = connectorResult.success;
        result.message = connectorResult.message;
        result.status = systemRecord.LastConnectionStatus__c;
        return result;
    }

    @AuraEnabled
    public static Id markErrorResolved(Id errorId, String resolutionNotes) {
        if (errorId == null) {
            throw new AuraHandledException('An error id is required to resolve an error.');
        }
        requireUpdateable(SyncError__c.SObjectType);

        SyncError__c errorRecord = new SyncError__c(
            Id = errorId,
            Status__c = 'Resolved',
            ResolutionNotes__c = String.isBlank(resolutionNotes)
                ? 'Resolved from the ErpSync admin console.'
                : resolutionNotes
        );
        update errorRecord;
        return errorRecord.Id;
    }

    private static void requireReadable(Schema.SObjectType objectType) {
        if (!objectType.getDescribe().isAccessible()) {
            throw new AuraHandledException('You do not have read access to ' + objectType.getDescribe().getLabel() + '.');
        }
    }

    private static void requireCreateable(Schema.SObjectType objectType) {
        if (!objectType.getDescribe().isCreateable()) {
            throw new AuraHandledException('You do not have create access to ' + objectType.getDescribe().getLabel() + '.');
        }
    }

    private static void requireUpdateable(Schema.SObjectType objectType) {
        if (!objectType.getDescribe().isUpdateable()) {
            throw new AuraHandledException('You do not have update access to ' + objectType.getDescribe().getLabel() + '.');
        }
    }

    private static String buildRecordUrl(Id recordId) {
        return '/' + String.valueOf(recordId);
    }

    private static String buildTemplateNotes(ErpSyncConnectorCatalog.CatalogItem template) {
        return 'Template ErpSync a finaliser avant activation.\n'
            + 'Auth: creer ou verifier le Named Credential ' + template.suggestedNamedCredentialName + '.\n'
            + 'Base URL exemple: ' + template.baseUrlExample + '.\n'
            + 'Endpoint exemple: ' + template.suggestedEndpointPath + '.\n'
            + 'Payload: ' + template.suggestedPayloadMode + '.\n'
            + 'Guide: ' + template.guide;
    }

    private static String truncateText(String value, Integer maxLength) {
        if (String.isBlank(value) || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength);
    }

    public class DashboardSummary {
        @AuraEnabled public Integer systemCount;
        @AuraEnabled public Integer activeSystemCount;
        @AuraEnabled public Integer flowCount;
        @AuraEnabled public Integer activeFlowCount;
        @AuraEnabled public Integer openErrorCount;
        @AuraEnabled public Integer runningExecutionCount;
        @AuraEnabled public Id lastExecutionId;
        @AuraEnabled public String lastExecutionName;
        @AuraEnabled public String lastExecutionStatus;
        @AuraEnabled public Datetime lastExecutionAt;
        @AuraEnabled public String lastExecutionUrl;
    }

    public class SystemRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String recordUrl;
        @AuraEnabled public String connectorType;
        @AuraEnabled public String environment;
        @AuraEnabled public String status;
        @AuraEnabled public String baseUrl;
        @AuraEnabled public String namedCredentialName;
        @AuraEnabled public Datetime lastSuccessfulSync;
        @AuraEnabled public String lastConnectionStatus;
        @AuraEnabled public Datetime lastConnectionCheckAt;
    }

    public class FlowRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String recordUrl;
        @AuraEnabled public Id integrationSystemId;
        @AuraEnabled public String systemName;
        @AuraEnabled public String salesforceObject;
        @AuraEnabled public String externalObject;
        @AuraEnabled public String direction;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String triggerMode;
        @AuraEnabled public Decimal batchSize;
        @AuraEnabled public String conflictStrategy;
        @AuraEnabled public String endpointPath;
        @AuraEnabled public String httpMethod;
        @AuraEnabled public String payloadMode;
        @AuraEnabled public String payloadRootKey;
        @AuraEnabled public Decimal scheduleFrequencyMinutes;
        @AuraEnabled public Datetime lastRunAt;
        @AuraEnabled public Datetime nextRunAt;
    }

    public class MappingRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String recordUrl;
        @AuraEnabled public Id integrationFlowId;
        @AuraEnabled public String flowName;
        @AuraEnabled public String salesforceField;
        @AuraEnabled public String externalField;
        @AuraEnabled public String direction;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public String transformType;
        @AuraEnabled public String nullBehavior;
        @AuraEnabled public Boolean isExternalKey;
        @AuraEnabled public Decimal sortOrder;
    }

    public class ExecutionRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String recordUrl;
        @AuraEnabled public Id integrationSystemId;
        @AuraEnabled public String systemName;
        @AuraEnabled public Id integrationFlowId;
        @AuraEnabled public String flowName;
        @AuraEnabled public String status;
        @AuraEnabled public Datetime startedAt;
        @AuraEnabled public Datetime finishedAt;
        @AuraEnabled public Decimal totalRecords;
        @AuraEnabled public Decimal successCount;
        @AuraEnabled public Decimal errorCount;
        @AuraEnabled public Decimal durationMs;
        @AuraEnabled public String correlationId;
    }

    public class ErrorRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String recordUrl;
        @AuraEnabled public Id syncExecutionId;
        @AuraEnabled public String executionName;
        @AuraEnabled public Id integrationSystemId;
        @AuraEnabled public String systemName;
        @AuraEnabled public Id integrationFlowId;
        @AuraEnabled public String flowName;
        @AuraEnabled public String status;
        @AuraEnabled public String errorType;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String salesforceRecordId;
        @AuraEnabled public String externalRecordId;
        @AuraEnabled public Decimal retryCount;
        @AuraEnabled public Boolean isRetryable;
        @AuraEnabled public Datetime nextRetryAt;
        @AuraEnabled public Id retryExecutionId;
        @AuraEnabled public String correlationId;
    }

    public class RecordLinkRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String recordUrl;
        @AuraEnabled public String systemName;
        @AuraEnabled public String flowName;
        @AuraEnabled public String salesforceObject;
        @AuraEnabled public String salesforceRecordId;
        @AuraEnabled public String externalObject;
        @AuraEnabled public String externalRecordId;
        @AuraEnabled public String lastSyncStatus;
        @AuraEnabled public Datetime lastSyncedAt;
        @AuraEnabled public String lastErrorMessage;
        @AuraEnabled public String lastCorrelationId;
    }

    public class RecordLogRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String recordUrl;
        @AuraEnabled public String executionName;
        @AuraEnabled public String systemName;
        @AuraEnabled public String flowName;
        @AuraEnabled public Id integrationRecordLinkId;
        @AuraEnabled public String salesforceRecordId;
        @AuraEnabled public String externalRecordId;
        @AuraEnabled public String status;
        @AuraEnabled public String errorType;
        @AuraEnabled public String message;
        @AuraEnabled public Datetime processedAt;
        @AuraEnabled public String correlationId;
    }

    public class ConnectionCheckResult {
        @AuraEnabled public Id systemId;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String status;
    }

    public class TemplateInstallResult {
        @AuraEnabled public Id systemId;
        @AuraEnabled public Id flowId;
        @AuraEnabled public Integer mappingCount;
        @AuraEnabled public String systemUrl;
        @AuraEnabled public String flowUrl;
        @AuraEnabled public String message;
    }
}
