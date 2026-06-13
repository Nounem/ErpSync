@IsTest
private class ErpSyncSyncOrchestratorTest {
    @IsTest
    static void genericRestSyncBuildsPayloadAndMarksSuccess() {
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

        insert new List<IntegrationMapping__c>{
            new IntegrationMapping__c(
                Name = 'Name to name',
                IntegrationFlow__c = flow.Id,
                SalesforceField__c = 'Name',
                ExternalField__c = 'name',
                Direction__c = 'Inherit From Flow',
                IsActive__c = true,
                IsRequired__c = true,
                TransformType__c = 'Trim',
                NullBehavior__c = 'Error',
                SortOrder__c = 10
            ),
            new IntegrationMapping__c(
                Name = 'Phone to phone',
                IntegrationFlow__c = flow.Id,
                SalesforceField__c = 'Phone',
                ExternalField__c = 'phone',
                Direction__c = 'Inherit From Flow',
                IsActive__c = true,
                IsRequired__c = false,
                TransformType__c = 'Trim',
                NullBehavior__c = 'Ignore',
                SortOrder__c = 20
            )
        };

        Account account = new Account(Name = '  Acme  ', Phone = '  555-0100  ');
        insert account;

        SyncExecution__c execution = new SyncExecution__c(
            IntegrationSystem__c = systemRecord.Id,
            IntegrationFlow__c = flow.Id,
            Status__c = 'Queued',
            StartedAt__c = System.now(),
            TotalRecords__c = 0,
            SuccessCount__c = 0,
            ErrorCount__c = 0,
            DurationMs__c = 0,
            CorrelationId__c = 'test-generic-rest'
        );
        insert execution;

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        ErpSyncSyncOrchestrator.run(execution.Id);
        Test.stopTest();

        SyncExecution__c updatedExecution = [
            SELECT Status__c, TotalRecords__c, SuccessCount__c, ErrorCount__c, Summary__c
            FROM SyncExecution__c
            WHERE Id = :execution.Id
        ];
        System.assertEquals('Success', updatedExecution.Status__c, 'The execution should succeed.');
        System.assertEquals(1, updatedExecution.TotalRecords__c, 'One account should be processed.');
        System.assertEquals(1, updatedExecution.SuccessCount__c, 'The REST callout should be counted as success.');
        System.assertEquals(0, updatedExecution.ErrorCount__c, 'No errors should be logged.');
        System.assert(updatedExecution.Summary__c.contains('success=1'), 'The summary should include the success count.');

        System.assertEquals(0, [SELECT COUNT() FROM SyncError__c WHERE SyncExecution__c = :execution.Id]);

        SyncRecordLog__c recordLog = [
            SELECT Status__c, SalesforceRecordId__c, ExternalRecordId__c, Payload__c
            FROM SyncRecordLog__c
            WHERE SyncExecution__c = :execution.Id
            LIMIT 1
        ];
        System.assertEquals('Success', recordLog.Status__c, 'A success record log should be created.');
        System.assertEquals(String.valueOf(account.Id), recordLog.SalesforceRecordId__c, 'The log should reference the Salesforce record.');
        System.assertEquals('external-account-1', recordLog.ExternalRecordId__c, 'The log should store the external id.');
        System.assert(recordLog.Payload__c.contains('"name":"Acme"'), 'The log should store the transformed payload.');

        IntegrationRecordLink__c recordLink = [
            SELECT LastSyncStatus__c, SalesforceRecordId__c, ExternalRecordId__c, LastErrorMessage__c
            FROM IntegrationRecordLink__c
            WHERE IntegrationFlow__c = :flow.Id
            LIMIT 1
        ];
        System.assertEquals('Success', recordLink.LastSyncStatus__c, 'The record link should be marked successful.');
        System.assertEquals(String.valueOf(account.Id), recordLink.SalesforceRecordId__c, 'The link should reference the Salesforce record.');
        System.assertEquals('external-account-1', recordLink.ExternalRecordId__c, 'The external id should be retained on the link.');
        System.assertEquals(null, recordLink.LastErrorMessage__c, 'Successful sync should clear the last error.');

        IntegrationSystem__c updatedSystem = [
            SELECT LastSuccessfulSync__c
            FROM IntegrationSystem__c
            WHERE Id = :systemRecord.Id
        ];
        System.assertNotEquals(null, updatedSystem.LastSuccessfulSync__c, 'Successful sync should update system health.');
    }

    @IsTest
    static void mappingErrorCreatesSyncError() {
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
            Name = 'Phone required',
            IntegrationFlow__c = flow.Id,
            SalesforceField__c = 'Phone',
            ExternalField__c = 'phone',
            Direction__c = 'Inherit From Flow',
            IsActive__c = true,
            IsRequired__c = true,
            TransformType__c = 'Trim',
            NullBehavior__c = 'Error',
            SortOrder__c = 10
        );
        insert mapping;

        Account account = new Account(Name = 'No Phone Account');
        insert account;

        SyncExecution__c execution = new SyncExecution__c(
            IntegrationSystem__c = systemRecord.Id,
            IntegrationFlow__c = flow.Id,
            Status__c = 'Queued',
            StartedAt__c = System.now(),
            TotalRecords__c = 0,
            SuccessCount__c = 0,
            ErrorCount__c = 0,
            DurationMs__c = 0,
            CorrelationId__c = 'test-mapping-error'
        );
        insert execution;

        Test.startTest();
        ErpSyncSyncOrchestrator.run(execution.Id);
        Test.stopTest();

        SyncExecution__c updatedExecution = [
            SELECT Status__c, TotalRecords__c, SuccessCount__c, ErrorCount__c
            FROM SyncExecution__c
            WHERE Id = :execution.Id
        ];
        System.assertEquals('Failed', updatedExecution.Status__c, 'The execution should fail on mapping error.');
        System.assertEquals(1, updatedExecution.TotalRecords__c, 'One account should be evaluated.');
        System.assertEquals(0, updatedExecution.SuccessCount__c, 'No records should succeed.');
        System.assertEquals(1, updatedExecution.ErrorCount__c, 'One mapping error should be logged.');

        SyncError__c errorRecord = [
            SELECT ErrorType__c, Status__c, SalesforceRecordId__c, IsRetryable__c
            FROM SyncError__c
            WHERE SyncExecution__c = :execution.Id
            LIMIT 1
        ];
        System.assertEquals('Mapping', errorRecord.ErrorType__c, 'The error should be classified as mapping.');
        System.assertEquals('Open', errorRecord.Status__c, 'The error should remain open.');
        System.assertEquals(String.valueOf(account.Id), errorRecord.SalesforceRecordId__c, 'The failing Salesforce record should be stored.');
        System.assertEquals(false, errorRecord.IsRetryable__c, 'Mapping errors are not retryable without correction.');

        SyncRecordLog__c recordLog = [
            SELECT Status__c, ErrorType__c, SalesforceRecordId__c, Message__c
            FROM SyncRecordLog__c
            WHERE SyncExecution__c = :execution.Id
            LIMIT 1
        ];
        System.assertEquals('Error', recordLog.Status__c, 'An error record log should be created.');
        System.assertEquals('Mapping', recordLog.ErrorType__c, 'The record log should expose the error type.');
        System.assertEquals(String.valueOf(account.Id), recordLog.SalesforceRecordId__c, 'The log should reference the failing record.');

        IntegrationRecordLink__c recordLink = [
            SELECT LastSyncStatus__c, SalesforceRecordId__c, LastErrorMessage__c
            FROM IntegrationRecordLink__c
            WHERE IntegrationFlow__c = :flow.Id
            LIMIT 1
        ];
        System.assertEquals('Error', recordLink.LastSyncStatus__c, 'The record link should be marked in error.');
        System.assertEquals(String.valueOf(account.Id), recordLink.SalesforceRecordId__c, 'The link should reference the failing record.');
        System.assert(recordLink.LastErrorMessage__c.contains('Required field is empty'), 'The link should retain the last error.');
    }

    @IsTest
    static void brevoRootKeyPayloadUsesGenericRestAdapter() {
        IntegrationSystem__c systemRecord = new IntegrationSystem__c(
            Name = 'Brevo Sandbox',
            ConnectorType__c = 'Brevo',
            Environment__c = 'Sandbox',
            Status__c = 'Active',
            NamedCredentialName__c = 'Brevo'
        );
        insert systemRecord;

        IntegrationFlow__c flow = new IntegrationFlow__c(
            Name = 'Accounts to Brevo Contacts',
            IntegrationSystem__c = systemRecord.Id,
            SalesforceObject__c = 'Account',
            ExternalObject__c = 'contacts',
            Direction__c = 'Salesforce to External',
            IsActive__c = true,
            TriggerMode__c = 'Manual',
            EndpointPath__c = '/contacts',
            HttpMethod__c = 'POST',
            PayloadMode__c = 'Root Key',
            PayloadRootKey__c = 'attributes',
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
            TransformType__c = 'Trim',
            NullBehavior__c = 'Error',
            SortOrder__c = 10
        );

        Account account = new Account(Name = ' Brevo Test ');
        insert account;

        SyncExecution__c execution = new SyncExecution__c(
            IntegrationSystem__c = systemRecord.Id,
            IntegrationFlow__c = flow.Id,
            Status__c = 'Queued',
            StartedAt__c = System.now(),
            TotalRecords__c = 0,
            SuccessCount__c = 0,
            ErrorCount__c = 0,
            DurationMs__c = 0,
            CorrelationId__c = 'test-brevo-root'
        );
        insert execution;

        Test.setMock(HttpCalloutMock.class, new RootKeyMock());

        Test.startTest();
        ErpSyncSyncOrchestrator.run(execution.Id);
        Test.stopTest();

        SyncExecution__c updatedExecution = [
            SELECT Status__c, SuccessCount__c, ErrorCount__c
            FROM SyncExecution__c
            WHERE Id = :execution.Id
        ];
        System.assertEquals('Success', updatedExecution.Status__c, 'Brevo should be handled by the Generic REST adapter.');
        System.assertEquals(1, updatedExecution.SuccessCount__c, 'The Brevo-style callout should succeed.');
        System.assertEquals(0, updatedExecution.ErrorCount__c, 'No Brevo errors should be logged.');
    }

    @IsTest
    static void rawMappingSupportsNestedExternalFields() {
        IntegrationSystem__c systemRecord = new IntegrationSystem__c(
            Name = 'Brevo Sandbox',
            ConnectorType__c = 'Brevo',
            Environment__c = 'Sandbox',
            Status__c = 'Active',
            NamedCredentialName__c = 'Brevo'
        );
        insert systemRecord;

        IntegrationFlow__c flow = new IntegrationFlow__c(
            Name = 'Contacts to Brevo Contacts',
            IntegrationSystem__c = systemRecord.Id,
            SalesforceObject__c = 'Contact',
            ExternalObject__c = 'contacts',
            Direction__c = 'Salesforce to External',
            IsActive__c = true,
            TriggerMode__c = 'Manual',
            EndpointPath__c = '/contacts',
            HttpMethod__c = 'POST',
            PayloadMode__c = 'Raw Mapping',
            BatchSize__c = 10,
            ConflictStrategy__c = 'Salesforce Wins'
        );
        insert flow;

        insert new List<IntegrationMapping__c>{
            new IntegrationMapping__c(
                Name = 'Email to email',
                IntegrationFlow__c = flow.Id,
                SalesforceField__c = 'Email',
                ExternalField__c = 'email',
                Direction__c = 'Inherit From Flow',
                IsActive__c = true,
                IsRequired__c = true,
                IsExternalKey__c = true,
                TransformType__c = 'Trim',
                NullBehavior__c = 'Error',
                SortOrder__c = 10
            ),
            new IntegrationMapping__c(
                Name = 'FirstName to attributes',
                IntegrationFlow__c = flow.Id,
                SalesforceField__c = 'FirstName',
                ExternalField__c = 'attributes.FIRSTNAME',
                Direction__c = 'Inherit From Flow',
                IsActive__c = true,
                IsRequired__c = false,
                TransformType__c = 'Trim',
                NullBehavior__c = 'Ignore',
                SortOrder__c = 20
            ),
            new IntegrationMapping__c(
                Name = 'LastName to attributes',
                IntegrationFlow__c = flow.Id,
                SalesforceField__c = 'LastName',
                ExternalField__c = 'attributes.LASTNAME',
                Direction__c = 'Inherit From Flow',
                IsActive__c = true,
                IsRequired__c = false,
                TransformType__c = 'Trim',
                NullBehavior__c = 'Ignore',
                SortOrder__c = 30
            )
        };

        Contact contact = new Contact(
            FirstName = ' Ada ',
            LastName = ' Lovelace ',
            Email = ' ada@example.com '
        );
        insert contact;

        SyncExecution__c execution = new SyncExecution__c(
            IntegrationSystem__c = systemRecord.Id,
            IntegrationFlow__c = flow.Id,
            Status__c = 'Queued',
            StartedAt__c = System.now(),
            TotalRecords__c = 0,
            SuccessCount__c = 0,
            ErrorCount__c = 0,
            DurationMs__c = 0,
            CorrelationId__c = 'test-brevo-nested'
        );
        insert execution;

        Test.setMock(HttpCalloutMock.class, new RawNestedMock());

        Test.startTest();
        ErpSyncSyncOrchestrator.run(execution.Id);
        Test.stopTest();

        SyncExecution__c updatedExecution = [
            SELECT Status__c, SuccessCount__c, ErrorCount__c
            FROM SyncExecution__c
            WHERE Id = :execution.Id
        ];
        System.assertEquals('Success', updatedExecution.Status__c, 'The nested raw payload should sync successfully.');
        System.assertEquals(1, updatedExecution.SuccessCount__c, 'One contact should sync.');
        System.assertEquals(0, updatedExecution.ErrorCount__c, 'No nested mapping errors should be logged.');
    }

    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            System.assertEquals('POST', request.getMethod(), 'The configured HTTP method should be used.');
            System.assert(request.getEndpoint().contains('callout:ErpSync_Generic/accounts'), 'Named Credential endpoint should be used.');
            System.assert(request.getBody().contains('"name":"Acme"'), 'The payload should be transformed.');
            System.assert(request.getBody().contains('"phone":"555-0100"'), 'The optional field should be transformed.');

            HttpResponse response = new HttpResponse();
            response.setStatusCode(201);
            response.setStatus('Created');
            response.setBody('{"id":"external-account-1"}');
            return response;
        }
    }

    private class RootKeyMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            System.assertEquals('POST', request.getMethod(), 'The configured HTTP method should be used.');
            System.assert(request.getEndpoint().contains('callout:Brevo/contacts'), 'The Brevo Named Credential endpoint should be used.');
            System.assert(request.getBody().contains('"attributes"'), 'The configured root key should wrap the payload.');
            System.assert(request.getBody().contains('"COMPANY":"Brevo Test"'), 'The mapped field should be sent under the root key.');

            HttpResponse response = new HttpResponse();
            response.setStatusCode(201);
            response.setStatus('Created');
            response.setBody('{"id":"brevo-contact-1"}');
            return response;
        }
    }

    private class RawNestedMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            System.assertEquals('POST', request.getMethod(), 'The configured HTTP method should be used.');
            System.assert(request.getEndpoint().contains('callout:Brevo/contacts'), 'The Brevo endpoint should be used.');
            System.assert(request.getBody().contains('"email":"ada@example.com"'), 'Email should stay at payload root.');
            System.assert(request.getBody().contains('"attributes"'), 'Nested attributes should be present.');
            System.assert(request.getBody().contains('"FIRSTNAME":"Ada"'), 'First name should be nested and trimmed.');
            System.assert(request.getBody().contains('"LASTNAME":"Lovelace"'), 'Last name should be nested and trimmed.');

            HttpResponse response = new HttpResponse();
            response.setStatusCode(201);
            response.setStatus('Created');
            response.setBody('{"id":"brevo-contact-2"}');
            return response;
        }
    }
}
