@IsTest
private class ErpSyncSchedulerAndRetryTest {
    @IsTest
    static void dueScheduledFlowQueuesAndRunsExecution() {
        TestData data = createGenericRestFlow('Scheduled');
        data.flow.NextRunAt__c = System.now().addMinutes(-5);
        data.flow.ScheduleFrequencyMinutes__c = 30;
        update data.flow;

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        List<Id> executionIds = ErpSyncScheduleService.runDueScheduledFlows(5);
        Test.stopTest();

        System.assertEquals(1, executionIds.size(), 'One due scheduled flow should be queued.');

        SyncExecution__c execution = [
            SELECT Status__c, TotalRecords__c, SuccessCount__c, ErrorCount__c
            FROM SyncExecution__c
            WHERE Id = :executionIds[0]
        ];
        System.assertEquals('Success', execution.Status__c, 'The scheduled execution should run successfully.');
        System.assertEquals(1, execution.TotalRecords__c, 'One source record should be processed.');
        System.assertEquals(1, execution.SuccessCount__c, 'The source record should sync successfully.');
        System.assertEquals(0, execution.ErrorCount__c, 'No error should be logged.');

        IntegrationFlow__c updatedFlow = [
            SELECT NextRunAt__c
            FROM IntegrationFlow__c
            WHERE Id = :data.flow.Id
        ];
        System.assert(updatedFlow.NextRunAt__c > System.now(), 'The next run should be pushed into the future.');
    }

    @IsTest
    static void dueRetryQueuesExecutionAndResolvesOriginalError() {
        TestData data = createGenericRestFlow('Manual');

        SyncExecution__c failedExecution = new SyncExecution__c(
            IntegrationSystem__c = data.systemRecord.Id,
            IntegrationFlow__c = data.flow.Id,
            Status__c = 'Failed',
            StartedAt__c = System.now().addMinutes(-30),
            FinishedAt__c = System.now().addMinutes(-29),
            TotalRecords__c = 1,
            SuccessCount__c = 0,
            ErrorCount__c = 1,
            DurationMs__c = 1000,
            CorrelationId__c = 'retry-source'
        );
        insert failedExecution;

        SyncError__c errorRecord = new SyncError__c(
            SyncExecution__c = failedExecution.Id,
            IntegrationSystem__c = data.systemRecord.Id,
            IntegrationFlow__c = data.flow.Id,
            Status__c = 'Retry Scheduled',
            ErrorType__c = 'Network',
            ErrorMessage__c = 'Temporary external outage.',
            RetryCount__c = 1,
            IsRetryable__c = true,
            NextRetryAt__c = System.now().addMinutes(-1),
            CorrelationId__c = 'retry-source'
        );
        insert errorRecord;

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        List<Id> executionIds = ErpSyncRetryService.runDueRetries(5);
        Test.stopTest();

        System.assertEquals(1, executionIds.size(), 'One due retry should be queued.');

        SyncError__c updatedError = [
            SELECT Status__c, RetryExecution__c, ResolutionNotes__c
            FROM SyncError__c
            WHERE Id = :errorRecord.Id
        ];
        System.assertEquals('Resolved', updatedError.Status__c, 'The original error should be resolved after retry queueing.');
        System.assertEquals(executionIds[0], updatedError.RetryExecution__c, 'The retry execution should be linked.');
        System.assert(updatedError.ResolutionNotes__c.contains(String.valueOf(executionIds[0])), 'The retry execution should be noted.');

        SyncExecution__c retryExecution = [
            SELECT Status__c, SuccessCount__c, ErrorCount__c
            FROM SyncExecution__c
            WHERE Id = :executionIds[0]
        ];
        System.assertEquals('Success', retryExecution.Status__c, 'The retry execution should run successfully.');
        System.assertEquals(1, retryExecution.SuccessCount__c, 'The retry should process the source record.');
        System.assertEquals(0, retryExecution.ErrorCount__c, 'The retry should not create a new error.');
    }

    private static TestData createGenericRestFlow(String triggerMode) {
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
            TriggerMode__c = triggerMode,
            EndpointPath__c = '/accounts',
            HttpMethod__c = 'POST',
            PayloadMode__c = 'Envelope',
            BatchSize__c = 10,
            RetryMaxAttempts__c = 3,
            RetryDelayMinutes__c = 15,
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
            TransformType__c = 'Trim',
            NullBehavior__c = 'Error',
            SortOrder__c = 10
        );
        insert mapping;

        Account account = new Account(Name = '  Scheduler Account  ');
        insert account;

        TestData data = new TestData();
        data.systemRecord = systemRecord;
        data.flow = flow;
        data.account = account;
        return data;
    }

    private class TestData {
        public IntegrationSystem__c systemRecord;
        public IntegrationFlow__c flow;
        public Account account;
    }

    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            System.assertEquals('POST', request.getMethod(), 'The configured HTTP method should be used.');
            System.assert(request.getEndpoint().contains('callout:ErpSync_Generic/accounts'), 'Named Credential endpoint should be used.');
            System.assert(request.getBody().contains('"name":"Scheduler Account"'), 'The payload should include the transformed account name.');

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setStatus('OK');
            response.setBody('{"id":"external-scheduled-account"}');
            return response;
        }
    }
}
