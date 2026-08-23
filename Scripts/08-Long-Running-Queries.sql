/*
Check: Long-Running Requests
Read-only: Yes
Purpose: Show currently executing user requests above a configurable elapsed-time threshold.
*/
SET NOCOUNT ON;
DECLARE @LongRunningMinutes int = 15;

SELECT
    r.session_id,
    DB_NAME(r.database_id) AS DatabaseName,
    s.login_name,
    s.host_name,
    r.status,
    r.command,
    r.start_time,
    DATEDIFF(MINUTE, r.start_time, SYSDATETIME()) AS ElapsedMinutes,
    r.cpu_time AS CpuMs,
    r.total_elapsed_time AS TotalElapsedMs,
    r.reads,
    r.writes,
    r.logical_reads,
    r.wait_type,
    SUBSTRING(t.text,
              (r.statement_start_offset/2)+1,
              ((CASE r.statement_end_offset WHEN -1 THEN DATALENGTH(t.text) ELSE r.statement_end_offset END - r.statement_start_offset)/2)+1) AS CurrentStatement,
    'WARNING' AS Severity,
    'Confirm whether the request duration is expected. Review execution plan, waits, blocking, workload, and business impact before intervention.' AS RecommendedAction
FROM sys.dm_exec_requests AS r
INNER JOIN sys.dm_exec_sessions AS s ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
WHERE s.is_user_process = 1
  AND r.session_id <> @@SPID
  AND DATEDIFF(MINUTE, r.start_time, SYSDATETIME()) >= @LongRunningMinutes
ORDER BY r.total_elapsed_time DESC;
