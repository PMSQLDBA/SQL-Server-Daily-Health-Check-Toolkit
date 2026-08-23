/*
Check: Transaction Log Health
Read-only: Yes
Purpose: Show log utilization and log reuse wait reason.
*/
SET NOCOUNT ON;
DECLARE @LogUsedWarningPercent decimal(5,2) = 80.00;

SELECT
    d.name AS DatabaseName,
    d.recovery_model_desc AS RecoveryModel,
    d.log_reuse_wait_desc AS LogReuseWait,
    CAST(ls.total_log_size_in_bytes / 1048576.0 AS decimal(18,2)) AS TotalLogMB,
    CAST(ls.used_log_space_in_bytes / 1048576.0 AS decimal(18,2)) AS UsedLogMB,
    CAST(ls.used_log_space_in_percent AS decimal(6,2)) AS UsedLogPercent,
    CASE
        WHEN ls.used_log_space_in_percent >= @LogUsedWarningPercent THEN 'WARNING'
        ELSE 'PASS'
    END AS Severity,
    CASE
        WHEN ls.used_log_space_in_percent >= @LogUsedWarningPercent
            THEN 'Log utilization is high. Review log reuse wait, active transactions, backup status, and recent growth before taking action.'
        ELSE 'Log utilization is below the configured warning threshold.'
    END AS RecommendedAction
FROM sys.databases AS d
CROSS APPLY sys.dm_db_log_stats(d.database_id) AS ls
WHERE d.state_desc = 'ONLINE'
ORDER BY ls.used_log_space_in_percent DESC;
