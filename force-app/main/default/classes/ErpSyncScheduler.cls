public with sharing class ErpSyncScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        ErpSyncScheduleService.runDueScheduledFlows();
        ErpSyncRetryService.runDueRetries();
    }
}
