# Prerequisites

## Technical prerequisites

- Microsoft SQL Server instance accessible through SQL Server Management Studio (SSMS), Azure Data Studio, sqlcmd, or another trusted T-SQL client.
- A login with sufficient metadata permissions for the checks you intend to run.
- Access to `msdb` for backup and SQL Agent history checks.
- `VIEW SERVER STATE` is commonly required for server-level dynamic management views.
- Always On checks require an instance where the HADR feature is enabled and sufficient permissions to read availability group DMVs.

## Operational prerequisites

Before using the toolkit in production, know your organization's:

- Backup policy and expected RPO/RTO.
- Approved maintenance and escalation process.
- Expected database states (for example, intentionally OFFLINE or RESTORING databases).
- SQL Agent maintenance schedules.
- Availability Group topology and planned asynchronous replicas.
- Capacity thresholds and auto-growth standards.

## Recommended testing

Test the package in non-production first. Validate output on at least:

- A healthy standalone SQL Server.
- A server with a failed SQL Agent job.
- A database with an old or missing backup.
- Databases using SIMPLE and FULL recovery models.
- A server with active blocking.
- An Availability Group server, if used in your environment.
