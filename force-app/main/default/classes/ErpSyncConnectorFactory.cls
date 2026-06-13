public with sharing class ErpSyncConnectorFactory {
    public static ErpSyncConnector create(IntegrationSystem__c systemRecord) {
        if (systemRecord == null) {
            return new ErpSyncUnsupportedConnector('No integration system was provided.');
        }

        if (ErpSyncConnectorCatalog.isGenericRestCompatible(systemRecord.ConnectorType__c)) {
            return new ErpSyncGenericRestConnector();
        }

        return new ErpSyncUnsupportedConnector(
            'Connector type ' + systemRecord.ConnectorType__c + ' is not implemented yet.'
        );
    }
}
