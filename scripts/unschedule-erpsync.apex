String jobName = 'ErpSync Scheduler - Hourly';
for (CronTrigger triggerRecord : [
    SELECT Id
    FROM CronTrigger
    WHERE CronJobDetail.Name = :jobName
]) {
    System.abortJob(triggerRecord.Id);
}
