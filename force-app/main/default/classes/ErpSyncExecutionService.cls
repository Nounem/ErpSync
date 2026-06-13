public with sharing class ErpSyncExecutionService {
    public static Id queueFlow(Id flowId, String summary) {
        if (flowId == null) {
            throw new ErpSyncExecutionException('A flow id is required to queue a synchronization.');
        }

        IntegrationFlow__c flow = [
            SELECT Id, IntegrationSystem__c, IsActive__c
            FROM IntegrationFlow__c
            WHERE Id = :flowId
            LIMIT 1
        ];

        if (!flow.IsActive__c) {
            throw new ErpSyncExecutionException('Only active flows can be queued.');
        }

        SyncExecution__c execution = new SyncExecution__c(
            IntegrationSystem__c = flow.IntegrationSystem__c,
            IntegrationFlow__c = flow.Id,
            Status__c = 'Queued',
            StartedAt__c = System.now(),
            TotalRecords__c = 0,
            SuccessCount__c = 0,
            ErrorCount__c = 0,
            DurationMs__c = 0,
            TriggeredBy__c = UserInfo.getUserId(),
            CorrelationId__c = generateCorrelationId(),
            Summary__c = String.isBlank(summary) ? 'Execution queued by ErpSync.' : summary
        );
        insert execution;

        System.enqueueJob(new ErpSyncSyncQueueable(execution.Id));
        return execution.Id;
    }

    public static String generateCorrelationId() {
        String entropy = UserInfo.getOrganizationId() + UserInfo.getUserId() + String.valueOf(Datetime.now().getTime());
        Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(entropy));
        return EncodingUtil.convertToHex(digest).substring(0, 32);
    }

    public class ErpSyncExecutionException extends Exception {
    }
}
