@IsTest
private class ErpSyncAdminControllerTest {
    @IsTest
    static void dashboardRowsAndActionsWork() {
        IntegrationSystem__c systemRecord = new IntegrationSystem__c(
            Name = 'Odoo Sandbox',
            ConnectorType__c = 'Odoo',
            Environment__c = 'Sandbox',
            Status__c = 'Active',
            BaseUrl__c = 'https://odoo.example.com',
            NamedCredentialName__c = 'Odoo_Sandbox'
        );
        insert systemRecord;

        IntegrationFlow__c flow = new IntegrationFlow__c(
            Name = 'Accounts to Odoo Partners',
            IntegrationSystem__c = systemRecord.Id,
            SalesforceObject__c = 'Account',
            ExternalObject__c = 'res.partner',
            Direction__c = 'Salesforce to External',
            IsActive__c = true,
            TriggerMode__c = 'Manual',
            HttpMethod__c = 'POST',
            PayloadMode__c = 'Envelope',
            BatchSize__c = 50,
            ConflictStrategy__c = 'Salesforce Wins',
            ExternalIdField__c = 'OdooPartnerId__c'
        );
        insert flow;

        IntegrationMapping__c mapping = new IntegrationMapping__c(
            Name = 'Account Name to Partner Name',
            IntegrationFlow__c = flow.Id,
            SalesforceField__c = 'Name',
            ExternalField__c = 'name',
            Direction__c = 'Inherit From Flow',
            IsActive__c = true,
            IsRequired__c = true,
            TransformType__c = 'Trim',
            NullBehavior__c = 'Error',
            SortOrder__c = 10
        );
        insert mapping;

        SyncExecution__c execution = new SyncExecution__c(
            IntegrationSystem__c = systemRecord.Id,
            IntegrationFlow__c = flow.Id,
            Status__c = 'Failed',
            StartedAt__c = System.now().addMinutes(-3),
            FinishedAt__c = System.now().addMinutes(-2),
            TotalRecords__c = 1,
            SuccessCount__c = 0,
            ErrorCount__c = 1,
            DurationMs__c = 1000,
            CorrelationId__c = 'test-correlation'
        );
        insert execution;

        SyncError__c errorRecord = new SyncError__c(
            SyncExecution__c = execution.Id,
            IntegrationSystem__c = systemRecord.Id,
            IntegrationFlow__c = flow.Id,
            Status__c = 'Open',
            ErrorType__c = 'Mapping',
            ErrorMessage__c = 'Missing required external field.',
            SalesforceRecordId__c = '001000000000001AAA',
            ExternalRecordId__c = 'odoo-1',
            RetryCount__c = 0,
            IsRetryable__c = true,
            CorrelationId__c = 'test-correlation'
        );
        insert errorRecord;

        Test.startTest();
        ErpSyncAdminController.DashboardSummary summary = ErpSyncAdminController.getDashboardSummary();
        List<ErpSyncAdminController.SystemRow> systems = ErpSyncAdminController.getSystems();
        List<ErpSyncConnectorCatalog.CatalogItem> connectorCatalog = ErpSyncAdminController.getConnectorCatalog();
        List<ErpSyncAdminController.FlowRow> flows = ErpSyncAdminController.getFlows();
        List<ErpSyncAdminController.MappingRow> mappings = ErpSyncAdminController.getMappings();
        List<ErpSyncAdminController.ExecutionRow> executions = ErpSyncAdminController.getRecentExecutions();
        List<ErpSyncAdminController.ErrorRow> errors = ErpSyncAdminController.getOpenErrors();
        Id manualExecutionId = ErpSyncAdminController.startManualSync(flow.Id);
        Id retriedErrorId = ErpSyncAdminController.scheduleRetry(errorRecord.Id);
        Id resolvedErrorId = ErpSyncAdminController.markErrorResolved(errorRecord.Id, 'Corrected test data.');
        ErpSyncAdminController.ConnectionCheckResult connectionResult = ErpSyncAdminController.testConnection(systemRecord.Id);
        Test.stopTest();

        System.assertEquals(1, summary.systemCount, 'The dashboard should count integration systems.');
        System.assertEquals(1, summary.activeSystemCount, 'The dashboard should count active systems.');
        System.assertEquals(1, summary.flowCount, 'The dashboard should count flows.');
        System.assertEquals(1, summary.activeFlowCount, 'The dashboard should count active flows.');
        System.assertEquals(1, summary.openErrorCount, 'The dashboard should count open errors.');
        System.assertEquals(1, systems.size(), 'The systems list should expose configured systems.');
        System.assert(connectorCatalog.size() > 10, 'The connector catalog should expose common ERP and SaaS systems.');
        System.assert(catalogContains(connectorCatalog, 'Brevo'), 'Brevo should be present in the connector catalog.');
        System.assertEquals(1, flows.size(), 'The flows list should expose configured flows.');
        System.assertEquals('Envelope', flows[0].payloadMode, 'The flow row should expose the payload mode.');
        System.assertEquals(1, mappings.size(), 'The mappings list should expose configured mappings.');
        System.assertEquals(1, executions.size(), 'The executions list should expose recent executions.');
        System.assertEquals(1, errors.size(), 'The errors list should expose open errors.');
        System.assertNotEquals(null, manualExecutionId, 'Manual sync should create a queued execution.');
        System.assertEquals(errorRecord.Id, retriedErrorId, 'Retry should update the target error.');
        System.assertEquals(errorRecord.Id, resolvedErrorId, 'Resolve should update the target error.');
        System.assertEquals(false, connectionResult.success, 'Odoo connector is not implemented yet.');
        System.assertEquals('Failed', connectionResult.status, 'Unsupported connectors should fail the connection test.');

        SyncError__c updatedError = [
            SELECT Status__c, ResolutionNotes__c
            FROM SyncError__c
            WHERE Id = :errorRecord.Id
        ];
        System.assertEquals('Resolved', updatedError.Status__c, 'The error should be marked resolved.');
        System.assertEquals('Corrected test data.', updatedError.ResolutionNotes__c, 'The resolution note should be stored.');

        IntegrationSystem__c updatedSystem = [
            SELECT LastConnectionStatus__c, LastConnectionCheckAt__c
            FROM IntegrationSystem__c
            WHERE Id = :systemRecord.Id
        ];
        System.assertEquals('Failed', updatedSystem.LastConnectionStatus__c, 'The connection status should be stored.');
        System.assertNotEquals(null, updatedSystem.LastConnectionCheckAt__c, 'The connection check timestamp should be stored.');
    }

    @IsTest
    static void connectorTemplateInstallCreatesEditableStarterConfig() {
        Test.startTest();
        ErpSyncAdminController.TemplateInstallResult result = ErpSyncAdminController.installConnectorTemplate('Brevo');
        Test.stopTest();

        System.assertNotEquals(null, result.systemId, 'The template install should create a system.');
        System.assertNotEquals(null, result.flowId, 'The template install should create a flow.');
        System.assertEquals(4, result.mappingCount, 'The Brevo template should create starter mappings.');

        IntegrationSystem__c systemRecord = [
            SELECT Name, ConnectorType__c, Environment__c, Status__c, BaseUrl__c, NamedCredentialName__c, Notes__c
            FROM IntegrationSystem__c
            WHERE Id = :result.systemId
        ];
        System.assertEquals('Brevo', systemRecord.ConnectorType__c, 'The template should use the selected connector.');
        System.assertEquals('Sandbox', systemRecord.Environment__c, 'Templates should start in sandbox.');
        System.assertEquals('Inactive', systemRecord.Status__c, 'Templates should be inactive until reviewed.');
        System.assertEquals('https://api.brevo.com/v3', systemRecord.BaseUrl__c, 'The Brevo base URL should be prefilled.');
        System.assertEquals('Brevo', systemRecord.NamedCredentialName__c, 'The Named Credential suggestion should be prefilled.');
        System.assert(systemRecord.Notes__c.contains('Named Credential'), 'The admin notes should guide authentication.');

        IntegrationFlow__c flow = [
            SELECT SalesforceObject__c, ExternalObject__c, IsActive__c, EndpointPath__c, HttpMethod__c, PayloadMode__c
            FROM IntegrationFlow__c
            WHERE Id = :result.flowId
        ];
        System.assertEquals('Contact', flow.SalesforceObject__c, 'Brevo starts from Salesforce contacts.');
        System.assertEquals('contacts', flow.ExternalObject__c, 'Brevo targets contacts.');
        System.assertEquals(false, flow.IsActive__c, 'The flow should be inactive until reviewed.');
        System.assertEquals('/contacts', flow.EndpointPath__c, 'The endpoint should be prefilled.');
        System.assertEquals('POST', flow.HttpMethod__c, 'The HTTP method should be prefilled.');
        System.assertEquals('Raw Mapping', flow.PayloadMode__c, 'Brevo should use raw mapping for mixed root/nested payload.');

        List<IntegrationMapping__c> mappings = [
            SELECT SalesforceField__c, ExternalField__c, IsExternalKey__c
            FROM IntegrationMapping__c
            WHERE IntegrationFlow__c = :result.flowId
            ORDER BY SortOrder__c
        ];
        System.assertEquals('Email', mappings[0].SalesforceField__c, 'Email should be the first Brevo mapping.');
        System.assertEquals('email', mappings[0].ExternalField__c, 'Email should remain at payload root for Brevo.');
        System.assertEquals(true, mappings[0].IsExternalKey__c, 'Email should be the external key.');
        System.assertEquals('attributes.FIRSTNAME', mappings[1].ExternalField__c, 'Brevo first name should use nested attributes.');
    }

    private static Boolean catalogContains(List<ErpSyncConnectorCatalog.CatalogItem> catalog, String connectorType) {
        for (ErpSyncConnectorCatalog.CatalogItem item : catalog) {
            if (item.connectorType == connectorType) {
                return true;
            }
        }
        return false;
    }
}
