/*
Check: Blocking Sessions
Read-only: Yes
Purpose: Identify currently blocked requests exceeding a configurable duration.
*/
SET NOCOUNT ON;
DECLARE @BlockingWarningSeconds int = 60;

SELECT
    r.session_id AS BlockedSessionId,
    r.blocking_session_id AS BlockingSessionId,
    DB_NAME(r.database_id) AS DatabaseName,
    r.status AS RequestStatus,
    r.wait_type AS WaitType,
    r.wait_time / 1000.0 AS WaitSeconds,
    r.wait_resource AS WaitResource,
    s.login_name AS BlockedLogin,
    s.host_name AS BlockedHost,
    SUBSTRING(t.text,
              (r.statement_start_offset/2)+1,
              ((CASE r.statement_end_offset WHEN -1 THEN DATALENGTH(t.text) ELSE r.statement_end_offset END - r.statement_start_offset)/2)+1) AS BlockedStatement,
    CASE WHEN r.wait_time / 1000 >= @BlockingWarningSeconds THEN 'WARNING' ELSE 'INFO' END AS Severity,
    'Review the blocking transaction and business impact. Do not kill a session without understanding rollback and application impact.' AS RecommendedAction
FROM sys.dm_exec_requests AS r
INNER JOIN sys.dm_exec_sessions AS s ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
WHERE r.blocking_session_id <> 0
  AND r.session_id <> @@SPID
ORDER BY r.wait_time DESC;
