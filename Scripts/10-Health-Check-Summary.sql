/*
Check: Daily Health Check Summary
Read-only: Yes
Purpose: Provide a fast instance-level summary. Run detailed scripts for investigation.
Important: Thresholds are examples; align them with approved policy.
*/
SET NOCOUNT ON;
DECLARE @FullBackupWarningHours int = 24;
DECLARE @LogBackupWarningMinutes int = 30;
DECLARE @BlockingWarningSeconds int = 60;
DECLARE @LongRunningMinutes int = 15;

DECLARE @Results TABLE
(
    SortOrder int,
    CheckName nvarchar(100),
    Status varchar(10),
    Details nvarchar(1000),
    RecommendedAction nvarchar(1000)
);

-- 1. Instance
INSERT @Results
SELECT 1, 'Instance Health',
       CASE WHEN DATEDIFF(MINUTE, sqlserver_start_time, SYSDATETIME()) < 60 THEN 'WARNING' ELSE 'PASS' END,
       CONCAT('SQL Server start time: ', CONVERT(varchar(19), sqlserver_start_time, 120)),
       CASE WHEN DATEDIFF(MINUTE, sqlserver_start_time, SYSDATETIME()) < 60
            THEN 'Confirm whether the recent restart was expected.' ELSE 'No recent restart warning detected.' END
FROM sys.dm_os_sys_info;

-- 2. Database state
DECLARE @BadDbCount int = (SELECT COUNT(*) FROM sys.databases WHERE state_desc <> 'ONLINE');
INSERT @Results VALUES
(2, 'Database Status', CASE WHEN @BadDbCount = 0 THEN 'PASS' ELSE 'CRITICAL' END,
 CONCAT(@BadDbCount, ' database(s) are not ONLINE.'),
 CASE WHEN @BadDbCount = 0 THEN 'No action required.' ELSE 'Run 02-Database-Status.sql and validate each non-ONLINE database.' END);

-- 3. Backup health
;WITH b AS
(
    SELECT database_name,
           MAX(CASE WHEN type='D' AND is_copy_only=0 THEN backup_finish_date END) AS LastFull,
           MAX(CASE WHEN type='L' AND is_copy_only=0 THEN backup_finish_date END) AS LastLog
    FROM msdb.dbo.backupset
    GROUP BY database_name
), x AS
(
    SELECT d.name, d.recovery_model_desc, b.LastFull, b.LastLog,
           CASE
             WHEN d.name='tempdb' THEN 0
             WHEN b.LastFull IS NULL OR DATEDIFF(HOUR,b.LastFull,SYSDATETIME())>@FullBackupWarningHours THEN 1
             WHEN d.recovery_model_desc='FULL' AND (b.LastLog IS NULL OR DATEDIFF(MINUTE,b.LastLog,SYSDATETIME())>@LogBackupWarningMinutes) THEN 1
             ELSE 0 END AS IsWarning
    FROM sys.databases d LEFT JOIN b ON d.name=b.database_name
    WHERE d.state_desc='ONLINE'
)
INSERT @Results
SELECT 3, 'Backup Health', CASE WHEN SUM(IsWarning)=0 THEN 'PASS' ELSE 'WARNING' END,
       CONCAT(SUM(IsWarning),' database(s) outside configured backup thresholds.'),
       CASE WHEN SUM(IsWarning)=0 THEN 'No action required.' ELSE 'Run 03-Backup-Health.sql and compare with approved backup policy.' END
FROM x;

-- 4. SQL Agent failures
DECLARE @FailedJobs int = (
    SELECT COUNT(*)
    FROM msdb.dbo.sysjobhistory h
    WHERE h.step_id=0 AND h.run_status=0
      AND msdb.dbo.agent_datetime(h.run_date,h.run_time) >= DATEADD(HOUR,-24,GETDATE())
);
INSERT @Results VALUES
(4,'SQL Agent Jobs',CASE WHEN @FailedJobs=0 THEN 'PASS' ELSE 'WARNING' END,
 CONCAT(@FailedJobs,' failed job outcome(s) in the last 24 hours.'),
 CASE WHEN @FailedJobs=0 THEN 'No action required.' ELSE 'Run 04-SQL-Agent-Failures.sql and review failed job history.' END);

-- 5. Transaction log health
DECLARE @HighLogCount int = 0;

BEGIN TRY
    SELECT @HighLogCount = COUNT(*)
    FROM sys.databases AS d
    CROSS APPLY sys.dm_db_log_stats(d.database_id) AS ls
    WHERE d.state_desc = 'ONLINE'
      AND d.source_database_id IS NULL
      AND CASE
              WHEN ls.total_log_size_mb = 0 THEN 0
              ELSE (ls.active_log_size_mb * 100.0 / ls.total_log_size_mb)
          END >= 80;
END TRY
BEGIN CATCH
    SET @HighLogCount = -1;
END CATCH;

INSERT @Results VALUES
(
    5,
    'Transaction Log Health',

    CASE
        WHEN @HighLogCount = -1 THEN 'INFO'
        WHEN @HighLogCount = 0 THEN 'PASS'
        ELSE 'WARNING'
    END,

    CASE
        WHEN @HighLogCount = -1
            THEN 'Could not evaluate log utilization with current version/permissions.'
        ELSE
            CONCAT(@HighLogCount, ' database(s) at or above 80% active log utilization.')
    END,

    CASE
        WHEN @HighLogCount > 0
            THEN 'Run 06-Transaction-Log-Health.sql and review log reuse waits.'
        ELSE
            'Review detailed script if additional log diagnostics are needed.'
    END
);
-- 6. Blocking
DECLARE @BlockingCount int = (
    SELECT COUNT(*) FROM sys.dm_exec_requests
    WHERE blocking_session_id <> 0 AND session_id <> @@SPID AND wait_time/1000 >= @BlockingWarningSeconds
);
INSERT @Results VALUES
(6,'Blocking',CASE WHEN @BlockingCount=0 THEN 'PASS' ELSE 'WARNING' END,
 CONCAT(@BlockingCount,' blocked request(s) above ',@BlockingWarningSeconds,' seconds.'),
 CASE WHEN @BlockingCount=0 THEN 'No sustained blocking detected at query time.' ELSE 'Run 07-Blocking-Sessions.sql and investigate blocking chain before intervention.' END);

-- 7. Long running requests
DECLARE @LongCount int = (
    SELECT COUNT(*) FROM sys.dm_exec_requests r
    JOIN sys.dm_exec_sessions s ON r.session_id=s.session_id
    WHERE s.is_user_process=1 AND r.session_id<>@@SPID
      AND DATEDIFF(MINUTE,r.start_time,SYSDATETIME())>=@LongRunningMinutes
);
INSERT @Results VALUES
(7,'Long-Running Requests',CASE WHEN @LongCount=0 THEN 'PASS' ELSE 'WARNING' END,
 CONCAT(@LongCount,' user request(s) running for at least ',@LongRunningMinutes,' minutes.'),
 CASE WHEN @LongCount=0 THEN 'No long-running requests above threshold.' ELSE 'Run 08-Long-Running-Queries.sql and validate business/workload context.' END);

-- 8. Always On
IF CAST(SERVERPROPERTY('IsHadrEnabled') AS int) = 1
BEGIN
    DECLARE @UnhealthyAG int = (
        SELECT COUNT(*) FROM sys.dm_hadr_database_replica_states
        WHERE is_local=1 AND synchronization_health_desc <> 'HEALTHY'
    );
    INSERT @Results VALUES
    (8,'Always On',CASE WHEN @UnhealthyAG=0 THEN 'PASS' ELSE 'WARNING' END,
     CONCAT(@UnhealthyAG,' local AG database replica(s) not reporting HEALTHY.'),
     CASE WHEN @UnhealthyAG=0 THEN 'No local AG health warning detected.' ELSE 'Run 09-AlwaysOn-Health.sql and review topology, mode, queues, and connectivity.' END);
END
ELSE
BEGIN
    INSERT @Results VALUES (8,'Always On','INFO','HADR is not enabled on this instance.','No action required for standalone instances.');
END;

SELECT
    @@SERVERNAME AS ServerName,
    SYSDATETIME() AS GeneratedAt,
    CheckName,
    Status,
    Details,
    RecommendedAction
FROM @Results
ORDER BY SortOrder;
