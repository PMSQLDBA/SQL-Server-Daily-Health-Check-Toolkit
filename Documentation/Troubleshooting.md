# Troubleshooting

## "VIEW SERVER STATE permission was denied"

The login does not have the metadata permission required for the DMV. Ask your SQL Server/security administrator for the minimum approved permission needed for your SQL Server version.

## Backup output looks wrong

Check whether:

- The database is intentionally excluded from backups.
- The database is in SIMPLE recovery model.
- Backup history has been purged from `msdb`.
- Backups are taken by a tool that records history differently than expected.
- The configured warning threshold matches policy.

## SQL Agent check returns nothing

Possible reasons include:

- SQL Server Agent is not installed/running for that platform or edition.
- No failed job steps are inside the selected lookback period.
- The login cannot read job history metadata in `msdb`.

## Always On script says HADR is disabled

This is expected on standalone instances or servers not configured for Always On Availability Groups.

## Blocking script returns no rows

That means no currently blocked requests met the configured blocking threshold at the moment the query ran. Blocking is transient; use approved monitoring/Extended Events tooling for historical analysis.

## Database-space percentages seem surprising

The script reports free space *inside database files*. It is not the same as free space on the Windows/Linux volume. Use OS/storage monitoring for volume-level capacity.

## A script fails on an older/newer version

DMV schemas and permissions can change between releases. Record the exact SQL Server version, edition, error number, and failing statement, then adjust/test the script in non-production before use.
