public with sharing class ErpSyncUnsupportedConnector implements ErpSyncConnector {
    private String message;

    public ErpSyncUnsupportedConnector(String message) {
        this.message = String.isBlank(message) ? 'This connector is not implemented yet.' : message;
    }

    public ErpSyncConnectorResult send(ErpSyncConnectorRequest request) {
        return ErpSyncConnectorResult.failure('Technical', message, false, null, null);
    }

    public ErpSyncConnectorResult checkConnection(IntegrationSystem__c systemRecord) {
        return ErpSyncConnectorResult.failure('Technical', message, false, null, null);
    }
}
