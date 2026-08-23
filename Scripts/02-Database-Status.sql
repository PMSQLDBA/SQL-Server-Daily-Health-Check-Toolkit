/*
Check: Database Status
Read-only: Yes
Purpose: Identify databases not in the expected ONLINE state and show key configuration metadata.
*/
SET NOCOUNT ON;

SELECT
    d.name AS DatabaseName,
    d.state_desc AS DatabaseState,
    d.user_access_desc AS UserAccess,
    d.recovery_model_desc AS RecoveryModel,
    d.is_read_only AS IsReadOnly,
    d.is_auto_close_on AS IsAutoCloseOn,
    d.is_auto_shrink_on AS IsAutoShrinkOn,
    CASE
        WHEN d.state_desc = 'ONLINE' THEN 'PASS'
        ELSE 'CRITICAL'
    END AS Severity,
    CASE
        WHEN d.state_desc = 'ONLINE' THEN 'No state issue detected.'
        ELSE 'Confirm whether this state is expected. Investigate before attempting recovery or state changes.'
    END AS RecommendedAction
FROM sys.databases AS d
ORDER BY CASE WHEN d.state_desc = 'ONLINE' THEN 1 ELSE 0 END, d.name;
