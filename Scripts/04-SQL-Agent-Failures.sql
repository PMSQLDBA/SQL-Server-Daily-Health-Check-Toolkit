/*
Check: SQL Agent Failures
Read-only: Yes
Purpose: Show failed job outcomes in a configurable lookback period.
*/
SET NOCOUNT ON;
DECLARE @LookbackHours int = 24;

SELECT
    j.name AS JobName,
    msdb.dbo.agent_datetime(h.run_date, h.run_time) AS RunDateTime,
    h.run_duration AS RunDurationHHMMSS,
    h.message AS FailureMessage,
    'WARNING' AS Severity,
    'Review SQL Agent job history and the failing step. Confirm whether the failure affected production operations.' AS RecommendedAction
FROM msdb.dbo.sysjobhistory AS h
INNER JOIN msdb.dbo.sysjobs AS j
    ON h.job_id = j.job_id
WHERE h.step_id = 0
  AND h.run_status = 0
  AND msdb.dbo.agent_datetime(h.run_date, h.run_time) >= DATEADD(HOUR, -@LookbackHours, GETDATE())
ORDER BY RunDateTime DESC;

IF @@ROWCOUNT = 0
BEGIN
    SELECT
        CAST(NULL AS sysname) AS JobName,
        CAST(NULL AS datetime) AS RunDateTime,
        CAST(NULL AS int) AS RunDurationHHMMSS,
        CAST('No failed job outcomes found in the configured lookback period.' AS nvarchar(4000)) AS FailureMessage,
        CAST('PASS' AS varchar(10)) AS Severity,
        CAST('No action required.' AS nvarchar(4000)) AS RecommendedAction;
END;
