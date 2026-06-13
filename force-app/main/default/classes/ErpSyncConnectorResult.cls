public class ErpSyncConnectorResult {
    public Boolean success { get; private set; }
    public String errorType { get; private set; }
    public String message { get; private set; }
    public String responseBody { get; private set; }
    public Integer statusCode { get; private set; }
    public String externalRecordId { get; private set; }
    public Boolean retryable { get; private set; }

    public static ErpSyncConnectorResult success(Integer statusCode, String message, String responseBody, String externalRecordId) {
        ErpSyncConnectorResult result = new ErpSyncConnectorResult();
        result.success = true;
        result.statusCode = statusCode;
        result.message = message;
        result.responseBody = responseBody;
        result.externalRecordId = externalRecordId;
        result.retryable = false;
        return result;
    }

    public static ErpSyncConnectorResult failure(
        String errorType,
        String message,
        Boolean retryable,
        Integer statusCode,
        String responseBody
    ) {
        ErpSyncConnectorResult result = new ErpSyncConnectorResult();
        result.success = false;
        result.errorType = String.isBlank(errorType) ? 'Technical' : errorType;
        result.message = message;
        result.retryable = retryable == null ? true : retryable;
        result.statusCode = statusCode;
        result.responseBody = responseBody;
        return result;
    }
}
