CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_view_logs()
BEGIN 
  TRUNCATE TABLE staging_temp.f_view_logs_temp;

 INSERT INTO staging_temp.f_view_logs_temp(

-- Create or replace table staging_temp.f_view_logs_temp
-- partition by logTimeStamp
-- as
SELECT
insertId,
severity,
protopayload_auditlog.status.code AS status_code,
protopayload_auditlog.status.message AS status_message,
protopayload_auditlog.authenticationInfo.principalEmail AS user_mail,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.eventName as eventname,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobName.jobId as jobid,
protopayload_auditlog.requestMetadata.callerIp,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobConfiguration.query.query,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobConfiguration.query.statementType,
DATETIME(protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.createTime, "Asia/Bangkok") as createTime,
DATETIME(protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.startTime, "Asia/Bangkok") as startTime,
DATETIME(protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.endTime, "Asia/Bangkok") as endTime,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.queryOutputRowCount,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.totalProcessedBytes,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.totalBilledBytes,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.billingTier,
protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.totalSlotMs,
DATETIME(timestamp, "Asia/Bangkok") as logDateTimeStamp,
DATE(timestamp, "Asia/Bangkok") as logTimeStamp,
CONTAINS_SUBSTR(protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobConfiguration.query.query, "clmn") as datastudio 

FROM
  `spatial-vision-343005.bq_log_sink.cloudaudit_googleapis_com_data_access`
-- ORDER BY timestamp DESC
-- )

 );
Create or replace table `warehouse.f_view_logs`

copy `staging_temp.f_view_logs_temp`;

End;