/*
Product: SQL Server Daily Health Check Toolkit
Check: Instance Health
Read-only: Yes
Purpose: Show basic SQL Server identity, version, uptime, and startup information.
*/
SET NOCOUNT ON;

SELECT
    @@SERVERNAME AS ServerName,
    CAST(SERVERPROPERTY('MachineName') AS nvarchar(128)) AS MachineName,
    CAST(SERVERPROPERTY('InstanceName') AS nvarchar(128)) AS InstanceName,
    CAST(SERVERPROPERTY('Edition') AS nvarchar(128)) AS Edition,
    CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128)) AS ProductVersion,
    CAST(SERVERPROPERTY('ProductLevel') AS nvarchar(128)) AS ProductLevel,
    sqlserver_start_time AS SQLServerStartTime,
    DATEDIFF(MINUTE, sqlserver_start_time, SYSDATETIME()) AS UptimeMinutes,
    CASE
        WHEN DATEDIFF(MINUTE, sqlserver_start_time, SYSDATETIME()) < 60 THEN 'WARNING'
        ELSE 'INFO'
    END AS Severity,
    CASE
        WHEN DATEDIFF(MINUTE, sqlserver_start_time, SYSDATETIME()) < 60
            THEN 'SQL Server started within the last hour. Confirm whether restart was expected.'
        ELSE 'Instance is running. Review uptime in the context of patching/restart policy.'
    END AS RecommendedAction
FROM sys.dm_os_sys_info;
