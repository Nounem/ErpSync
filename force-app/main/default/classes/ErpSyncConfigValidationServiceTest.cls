@IsTest
private class ErpSyncConfigValidationServiceTest {
    @IsTest
    static void validGenericRestFlowPassesWithExternalKeyWarningAbsent() {
        IntegrationSystem__c systemRecord = new IntegrationSystem__c(
            Name = 'Generic REST Sandbox',
            ConnectorType__c = 'Generic REST',
            Environment__c = 'Sandbox',
            Status__c = 'Active',
            NamedCredentialName__c = 'ErpSync_Generic'
        );
        insert systemRecord;

        IntegrationFlow__c flow = new IntegrationFlow__c(
            Name = 'Accounts to REST',
            IntegrationSystem__c = systemRecord.Id,
            SalesforceObject__c = 'Account',
            ExternalObject__c = 'accounts',
            Direction__c = 'Salesforce to External',
            IsActive__c = true,
            TriggerMode__c = 'Manual',
            EndpointPath__c = '/accounts',
            HttpMethod__c = 'POST',
            PayloadMode__c = 'Envelope',
            BatchSize__c = 10,
            ConflictStrategy__c = 'Salesforce Wins'
        );
        insert flow;

        IntegrationMapping__c mapping = new IntegrationMapping__c(
            Name = 'Name to name',
            IntegrationFlow__c = flow.Id,
            SalesforceField__c = 'Name',
            ExternalField__c = 'name',
            Direction__c = 'Inherit From Flow',
            IsActive__c = true,
            IsRequired__c = true,
            IsExternalKey__c = true,
            TransformType__c = 'Trim',
            NullBehavior__c = 'Error',
            SortOrder__c = 10
        );
        insert mapping;

        Test.startTest();
        ErpSyncConfigValidationService.ValidationResult result = ErpSyncConfigValidationService.validateFlow(flow.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'A complete Generic REST flow should validate.');
        System.assertEquals(0, result.errors.size(), 'No errors should be returned.');
        System.assertEquals(0, result.warnings.size(), 'The external key warning should be absent.');
    }

    @IsTest
    static void invalidMappingFieldFailsValidation() {
        IntegrationSystem__c systemRecord = new IntegrationSystem__c(
            Name = 'Generic REST Sandbox',
            ConnectorType__c = 'Generic REST',
            Environment__c = 'Sandbox',
            Status__c = 'Active',
            NamedCredentialName__c = 'ErpSync_Generic'
        );
        insert systemRecord;

        IntegrationFlow__c flow = new IntegrationFlow__c(
            Name = 'Accounts to REST',
            IntegrationSystem__c = systemRecord.Id,
            SalesforceObject__c = 'Account',
            ExternalObject__c = 'accounts',
            Direction__c = 'Salesforce to External',
            IsActive__c = true,
            TriggerMode__c = 'Manual',
            EndpointPath__c = '/accounts',
            HttpMethod__c = 'POST',
            PayloadMode__c = 'Envelope',
            BatchSize__c = 10,
            ConflictStrategy__c = 'Salesforce Wins'
        );
        insert flow;

        IntegrationMapping__c mapping = new IntegrationMapping__c(
            Name = 'Bad field',
            IntegrationFlow__c = flow.Id,
            SalesforceField__c = 'DefinitelyMissing__c',
            ExternalField__c = 'name',
            Direction__c = 'Inherit From Flow',
            IsActive__c = true,
            IsRequired__c = true,
            TransformType__c = 'Trim',
            NullBehavior__c = 'Error',
            SortOrder__c = 10
        );
        insert mapping;

        Test.startTest();
        ErpSyncConfigValidationService.ValidationResult result = ErpSyncAdminController.validateFlowConfiguration(flow.Id);
        Test.stopTest();

        System.assertEquals(false, result.success, 'An unknown Salesforce field should fail validation.');
        System.assertEquals(1, result.errors.size(), 'One field error should be returned.');
        System.assert(result.errors[0].contains('DefinitelyMissing__c'), 'The missing field should be named.');
    }

    @IsTest
    static void rootKeyPayloadRequiresRootKey() {
        IntegrationSystem__c systemRecord = new IntegrationSystem__c(
            Name = 'Brevo Sandbox',
            ConnectorType__c = 'Brevo',
            Environment__c = 'Sandbox',
            Status__c = 'Active',
            NamedCredentialName__c = 'Brevo'
        );
        insert systemRecord;

        IntegrationFlow__c flow = new IntegrationFlow__c(
            Name = 'Accounts to Brevo',
            IntegrationSystem__c = systemRecord.Id,
            SalesforceObject__c = 'Account',
            ExternalObject__c = 'contacts',
            Direction__c = 'Salesforce to External',
            IsActive__c = true,
            TriggerMode__c = 'Manual',
            EndpointPath__c = '/contacts',
            HttpMethod__c = 'POST',
            PayloadMode__c = 'Root Key',
            BatchSize__c = 10,
            ConflictStrategy__c = 'Salesforce Wins'
        );
        insert flow;

        insert new IntegrationMapping__c(
            Name = 'Name to company',
            IntegrationFlow__c = flow.Id,
            SalesforceField__c = 'Name',
            ExternalField__c = 'COMPANY',
            Direction__c = 'Inherit From Flow',
            IsActive__c = true,
            IsRequired__c = true,
            IsExternalKey__c = true,
            TransformType__c = 'Trim',
            NullBehavior__c = 'Error',
            SortOrder__c = 10
        );

        Test.startTest();
        ErpSyncConfigValidationService.ValidationResult result = ErpSyncConfigValidationService.validateFlow(flow.Id);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Root Key payload without root key should fail validation.');
        System.assertEquals(1, result.errors.size(), 'One root key error should be returned.');
        System.assert(result.errors[0].contains('Payload Root Key'), 'The root key field should be named.');
    }
}
