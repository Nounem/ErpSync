public with sharing class ErpSyncSyncQueueable implements Queueable, Database.AllowsCallouts {
    private Id executionId;

    public ErpSyncSyncQueueable(Id executionId) {
        this.executionId = executionId;
    }

    public void execute(QueueableContext context) {
        ErpSyncSyncOrchestrator.run(executionId);
    }
}
