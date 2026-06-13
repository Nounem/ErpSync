public with sharing class ErpSyncScheduleService {
    private static final Integer DEFAULT_LIMIT = 25;
    private static final Integer DEFAULT_FREQUENCY_MINUTES = 60;
    private static final Integer MIN_FREQUENCY_MINUTES = 5;

    public static List<Id> runDueScheduledFlows() {
        return runDueScheduledFlows(DEFAULT_LIMIT);
    }

    public static List<Id> runDueScheduledFlows(Integer maxFlows) {
        Datetime nowValue = System.now();
        Integer limitSize = resolveLimit(maxFlows);

        List<IntegrationFlow__c> flows = [
            SELECT Id, Name, NextRunAt__c, ScheduleFrequencyMinutes__c
            FROM IntegrationFlow__c
            WHERE IsActive__c = true
                AND TriggerMode__c = 'Scheduled'
                AND IntegrationSystem__r.Status__c = 'Active'
                AND (NextRunAt__c = null OR NextRunAt__c <= :nowValue)
            ORDER BY NextRunAt__c ASC NULLS FIRST, LastModifiedDate ASC
            LIMIT :limitSize
        ];

        List<Id> executionIds = new List<Id>();
        for (IntegrationFlow__c flow : flows) {
            Id executionId = ErpSyncExecutionService.queueFlow(
                flow.Id,
                'Scheduled execution queued by the ErpSync scheduler.'
            );
            executionIds.add(executionId);
            flow.NextRunAt__c = nowValue.addMinutes(resolveFrequency(flow.ScheduleFrequencyMinutes__c));
        }

        if (!flows.isEmpty()) {
            update flows;
        }
        return executionIds;
    }

    private static Integer resolveLimit(Integer configuredLimit) {
        if (configuredLimit == null || configuredLimit < 1) {
            return DEFAULT_LIMIT;
        }
        return configuredLimit > DEFAULT_LIMIT ? DEFAULT_LIMIT : configuredLimit;
    }

    private static Integer resolveFrequency(Decimal configuredFrequency) {
        Integer frequency = configuredFrequency == null
            ? DEFAULT_FREQUENCY_MINUTES
            : configuredFrequency.intValue();
        return frequency < MIN_FREQUENCY_MINUTES ? MIN_FREQUENCY_MINUTES : frequency;
    }
}
