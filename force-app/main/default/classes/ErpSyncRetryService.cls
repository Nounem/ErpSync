public with sharing class ErpSyncRetryService {
    private static final Integer DEFAULT_LIMIT = 25;
    private static final Integer DEFAULT_RETRY_DELAY_MINUTES = 15;
    private static final Integer DEFAULT_MAX_ATTEMPTS = 3;

    public static List<Id> runDueRetries() {
        return runDueRetries(DEFAULT_LIMIT);
    }

    public static List<Id> runDueRetries(Integer maxErrors) {
        Datetime nowValue = System.now();
        Integer limitSize = resolveLimit(maxErrors);

        List<SyncError__c> errors = [
            SELECT Id, IntegrationFlow__c, RetryCount__c, NextRetryAt__c,
                IntegrationFlow__r.Name,
                IntegrationFlow__r.RetryMaxAttempts__c,
                IntegrationFlow__r.RetryDelayMinutes__c,
                IntegrationFlow__r.IsActive__c
            FROM SyncError__c
            WHERE Status__c = 'Retry Scheduled'
                AND IsRetryable__c = true
                AND IntegrationFlow__c != null
                AND (NextRetryAt__c = null OR NextRetryAt__c <= :nowValue)
            ORDER BY NextRetryAt__c ASC NULLS FIRST, CreatedDate ASC
            LIMIT :limitSize
        ];

        List<Id> executionIds = new List<Id>();
        List<SyncError__c> errorsToUpdate = new List<SyncError__c>();
        for (SyncError__c errorRecord : errors) {
            Decimal retryCount = errorRecord.RetryCount__c == null ? 0 : errorRecord.RetryCount__c;
            Integer maxAttempts = resolveMaxAttempts(errorRecord.IntegrationFlow__r.RetryMaxAttempts__c);

            if (!errorRecord.IntegrationFlow__r.IsActive__c || retryCount >= maxAttempts) {
                errorsToUpdate.add(new SyncError__c(
                    Id = errorRecord.Id,
                    Status__c = 'Quarantined',
                    ResolutionNotes__c = 'Retry stopped by ErpSync: flow inactive or max attempts exceeded.'
                ));
                continue;
            }

            Id executionId = ErpSyncExecutionService.queueFlow(
                errorRecord.IntegrationFlow__c,
                'Retry execution queued from Sync Error ' + String.valueOf(errorRecord.Id) + '.'
            );
            executionIds.add(executionId);

            Integer retryDelay = resolveRetryDelay(errorRecord.IntegrationFlow__r.RetryDelayMinutes__c);
            errorsToUpdate.add(new SyncError__c(
                Id = errorRecord.Id,
                Status__c = 'Resolved',
                RetryExecution__c = executionId,
                LastRetryAt__c = nowValue,
                NextRetryAt__c = nowValue.addMinutes(retryDelay),
                ResolutionNotes__c = 'Retry execution queued: ' + String.valueOf(executionId)
            ));
        }

        if (!errorsToUpdate.isEmpty()) {
            update errorsToUpdate;
        }
        return executionIds;
    }

    private static Integer resolveLimit(Integer configuredLimit) {
        if (configuredLimit == null || configuredLimit < 1) {
            return DEFAULT_LIMIT;
        }
        return configuredLimit > DEFAULT_LIMIT ? DEFAULT_LIMIT : configuredLimit;
    }

    private static Integer resolveMaxAttempts(Decimal configuredMaxAttempts) {
        Integer maxAttempts = configuredMaxAttempts == null
            ? DEFAULT_MAX_ATTEMPTS
            : configuredMaxAttempts.intValue();
        return maxAttempts < 1 ? 1 : maxAttempts;
    }

    private static Integer resolveRetryDelay(Decimal configuredRetryDelay) {
        Integer retryDelay = configuredRetryDelay == null
            ? DEFAULT_RETRY_DELAY_MINUTES
            : configuredRetryDelay.intValue();
        return retryDelay < 1 ? 1 : retryDelay;
    }
}
