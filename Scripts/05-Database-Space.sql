/*
Check: Database File Space
Read-only: Yes
Purpose: Show file size and free space inside each database data file.
Important: This is NOT operating-system volume free space.
*/

SET NOCOUNT ON;

DECLARE @FreeSpaceWarningPercent decimal(5,2) = 15.00;

IF OBJECT_ID('tempdb..#FileSpace') IS NOT NULL
    DROP TABLE #FileSpace;

CREATE TABLE #FileSpace
(
    DatabaseName      sysname,
    LogicalFileName   sysname,
    FileType          nvarchar(60),
    SizeMB            decimal(18,2),
    UsedMB            decimal(18,2),
    FreeMB            decimal(18,2),
    FreePercent       decimal(18,2),
    GrowthDescription nvarchar(100)
);

DECLARE
    @db  sysname,
    @sql nvarchar(max);

DECLARE dbs CURSOR LOCAL FAST_FORWARD FOR
SELECT name
FROM sys.databases
WHERE state_desc = 'ONLINE'
  AND source_database_id IS NULL;

OPEN dbs;

FETCH NEXT FROM dbs INTO @db;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
    USE ' + QUOTENAME(@db) + N';

    INSERT INTO #FileSpace
    (
        DatabaseName,
        LogicalFileName,
        FileType,
        SizeMB,
        UsedMB,
        FreeMB,
        FreePercent,
        GrowthDescription
    )
    SELECT
        DB_NAME(),
        name,
        type_desc,

        CAST(
            size / 128.0
            AS decimal(18,2)
        ) AS SizeMB,

        CAST(
            FILEPROPERTY(name, ''SpaceUsed'') / 128.0
            AS decimal(18,2)
        ) AS UsedMB,

        CAST(
            (size - FILEPROPERTY(name, ''SpaceUsed'')) / 128.0
            AS decimal(18,2)
        ) AS FreeMB,

        CAST(
            CASE
                WHEN size = 0 THEN 0
                ELSE
                    (
                        (size - FILEPROPERTY(name, ''SpaceUsed''))
                        * 100.0 / size
                    )
            END
            AS decimal(18,2)
        ) AS FreePercent,

        CASE
            WHEN is_percent_growth = 1
                THEN CAST(growth AS varchar(20)) + ''%''
            ELSE
                CAST(
                    CAST(growth / 128.0 AS decimal(18,2))
                    AS varchar(30)
                ) + '' MB''
        END AS GrowthDescription

    FROM sys.database_files
    WHERE type_desc = ''ROWS'';
    ';

    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        PRINT CONCAT(
            'Could not inspect database ',
            QUOTENAME(@db),
            ': ',
            ERROR_MESSAGE()
        );
    END CATCH;

    FETCH NEXT FROM dbs INTO @db;
END

CLOSE dbs;
DEALLOCATE dbs;


SELECT
    DatabaseName,
    LogicalFileName,
    FileType,
    SizeMB,
    UsedMB,
    FreeMB,
    FreePercent,
    GrowthDescription,

    CASE
        WHEN FreePercent < @FreeSpaceWarningPercent
            THEN 'WARNING'
        ELSE 'PASS'
    END AS Severity,

    CASE
        WHEN FreePercent < @FreeSpaceWarningPercent
            THEN 'Low free space inside the database file. Review growth pattern, autogrowth settings, and underlying volume capacity.'
        ELSE
            'File has free space above the configured threshold.'
    END AS RecommendedAction

FROM #FileSpace
ORDER BY
    FreePercent,
    DatabaseName,
    LogicalFileName;
