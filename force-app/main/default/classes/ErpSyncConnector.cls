public interface ErpSyncConnector {
    ErpSyncConnectorResult send(ErpSyncConnectorRequest request);
    ErpSyncConnectorResult checkConnection(IntegrationSystem__c systemRecord);
}
