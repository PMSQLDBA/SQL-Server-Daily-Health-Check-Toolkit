/*
Check: Transaction Log Health
Read-only: Yes
Purpose: Show transaction log utilization and log reuse wait reason.
*/

SET NOCOUNT ON;

DECLARE @LogUsedWarningPercent decimal(5,2) = 80.00;

SELECT
    d.name AS DatabaseName,
    d.recovery_model_desc AS RecoveryModel,

    ls.log_truncation_holdup_reason AS LogReuseWait,

    CAST(ls.total_log_size_mb AS decimal(18,2)) AS TotalLogMB,

    CAST(ls.active_log_size_mb AS decimal(18,2)) AS UsedLogMB,

    CAST(
        CASE
            WHEN ls.total_log_size_mb = 0 THEN 0
            ELSE (ls.active_log_size_mb * 100.0 / ls.total_log_size_mb)
        END
        AS decimal(6,2)
    ) AS UsedLogPercent,

    CASE
        WHEN
            CASE
                WHEN ls.total_log_size_mb = 0 THEN 0
                ELSE (ls.active_log_size_mb * 100.0 / ls.total_log_size_mb)
            END >= @LogUsedWarningPercent
        THEN 'WARNING'
        ELSE 'PASS'
    END AS Severity,

    CASE
        WHEN
            CASE
                WHEN ls.total_log_size_mb = 0 THEN 0
                ELSE (ls.active_log_size_mb * 100.0 / ls.total_log_size_mb)
            END >= @LogUsedWarningPercent
        THEN
            'Log utilization is high. Review log reuse wait, active transactions, log backup status, and recent log growth before taking action.'
        ELSE
            'Log utilization is below the configured warning threshold.'
    END AS RecommendedAction

FROM sys.databases AS d

CROSS APPLY sys.dm_db_log_stats(d.database_id) AS ls

WHERE d.state_desc = 'ONLINE'
  AND d.source_database_id IS NULL

ORDER BY UsedLogPercent DESC;
