/*
Check: Always On Availability Group Health
Read-only: Yes
Purpose: Show local replica/database synchronization health when HADR is enabled.
*/
SET NOCOUNT ON;

IF CAST(SERVERPROPERTY('IsHadrEnabled') AS int) <> 1
BEGIN
    SELECT
        CAST(NULL AS sysname) AS AvailabilityGroup,
        CAST(NULL AS sysname) AS ReplicaServer,
        CAST(NULL AS sysname) AS DatabaseName,
        CAST(NULL AS nvarchar(60)) AS RoleDescription,
        CAST(NULL AS nvarchar(60)) AS SynchronizationState,
        CAST(NULL AS nvarchar(60)) AS SynchronizationHealth,
        CAST('INFO' AS varchar(10)) AS Severity,
        CAST('HADR is not enabled on this SQL Server instance.' AS nvarchar(4000)) AS RecommendedAction;
    RETURN;
END;

SELECT
    ag.name AS AvailabilityGroup,
    ar.replica_server_name AS ReplicaServer,
    DB_NAME(drs.database_id) AS DatabaseName,
    ars.role_desc AS RoleDescription,
    drs.synchronization_state_desc AS SynchronizationState,
    drs.synchronization_health_desc AS SynchronizationHealth,
    CASE
        WHEN drs.synchronization_health_desc = 'HEALTHY' THEN 'PASS'
        WHEN drs.synchronization_health_desc = 'PARTIALLY_HEALTHY' THEN 'WARNING'
        ELSE 'CRITICAL'
    END AS Severity,
    CASE
        WHEN drs.synchronization_health_desc = 'HEALTHY' THEN 'No synchronization health issue detected.'
        ELSE 'Review replica connectivity, send/redo queues, synchronization mode, role, and recent failover activity.'
    END AS RecommendedAction
FROM sys.dm_hadr_database_replica_states AS drs
INNER JOIN sys.availability_replicas AS ar ON drs.replica_id = ar.replica_id
INNER JOIN sys.availability_groups AS ag ON drs.group_id = ag.group_id
LEFT JOIN sys.dm_hadr_availability_replica_states AS ars
    ON drs.replica_id = ars.replica_id AND drs.group_id = ars.group_id
WHERE drs.is_local = 1
ORDER BY ag.name, DatabaseName;
