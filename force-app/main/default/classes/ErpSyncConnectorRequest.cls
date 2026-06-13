public class ErpSyncConnectorRequest {
    public IntegrationSystem__c systemRecord { get; private set; }
    public IntegrationFlow__c flow { get; private set; }
    public SObject sourceRecord { get; private set; }
    public Map<String, Object> payload { get; private set; }
    public Id executionId { get; private set; }
    public String correlationId { get; private set; }

    public ErpSyncConnectorRequest(
        IntegrationSystem__c systemRecord,
        IntegrationFlow__c flow,
        SObject sourceRecord,
        Map<String, Object> payload,
        Id executionId,
        String correlationId
    ) {
        this.systemRecord = systemRecord;
        this.flow = flow;
        this.sourceRecord = sourceRecord;
        this.payload = payload;
        this.executionId = executionId;
        this.correlationId = correlationId;
    }
}
