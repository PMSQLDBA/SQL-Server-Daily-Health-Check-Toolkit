/*
Check: Backup Health
Read-only: Yes
Purpose: Show last full, differential, and log backups and flag stale/missing backups using configurable thresholds.
Notes: Adjust thresholds to match approved RPO/backup policy.
*/
SET NOCOUNT ON;
DECLARE @FullBackupWarningHours int = 24;
DECLARE @LogBackupWarningMinutes int = 30;

WITH LastBackups AS
(
    SELECT
        bs.database_name,
        MAX(CASE WHEN bs.type = 'D' THEN bs.backup_finish_date END) AS LastFullBackup,
        MAX(CASE WHEN bs.type = 'I' THEN bs.backup_finish_date END) AS LastDiffBackup,
        MAX(CASE WHEN bs.type = 'L' THEN bs.backup_finish_date END) AS LastLogBackup
    FROM msdb.dbo.backupset AS bs
    WHERE bs.is_copy_only = 0
    GROUP BY bs.database_name
)
SELECT
    d.name AS DatabaseName,
    d.recovery_model_desc AS RecoveryModel,
    lb.LastFullBackup,
    lb.LastDiffBackup,
    lb.LastLogBackup,
    CASE
        WHEN d.name = 'tempdb' THEN 'INFO'
        WHEN lb.LastFullBackup IS NULL THEN 'CRITICAL'
        WHEN DATEDIFF(HOUR, lb.LastFullBackup, SYSDATETIME()) > @FullBackupWarningHours THEN 'WARNING'
        WHEN d.recovery_model_desc = 'FULL'
             AND (lb.LastLogBackup IS NULL OR DATEDIFF(MINUTE, lb.LastLogBackup, SYSDATETIME()) > @LogBackupWarningMinutes)
             THEN 'WARNING'
        ELSE 'PASS'
    END AS Severity,
    CASE
        WHEN d.name = 'tempdb' THEN 'tempdb is recreated at startup and is not backed up.'
        WHEN lb.LastFullBackup IS NULL THEN 'No full backup found in msdb history. Confirm backup coverage immediately.'
        WHEN DATEDIFF(HOUR, lb.LastFullBackup, SYSDATETIME()) > @FullBackupWarningHours THEN 'Full backup is older than the configured threshold. Validate backup job and policy.'
        WHEN d.recovery_model_desc = 'FULL'
             AND (lb.LastLogBackup IS NULL OR DATEDIFF(MINUTE, lb.LastLogBackup, SYSDATETIME()) > @LogBackupWarningMinutes)
             THEN 'Log backup is missing or older than the configured threshold. Validate the log-backup chain and policy.'
        ELSE 'Backup history is within configured thresholds.'
    END AS RecommendedAction
FROM sys.databases AS d
LEFT JOIN LastBackups AS lb ON lb.database_name = d.name
WHERE d.state_desc = 'ONLINE'
ORDER BY d.name;
