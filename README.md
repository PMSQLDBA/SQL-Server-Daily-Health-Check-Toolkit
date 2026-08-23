# SQL Server Daily Health Check Toolkit

A production-focused, read-only toolkit for SQL Server DBAs to perform a consistent daily health review.

## What's included

- 10 T-SQL scripts for instance, database, backup, job, storage, log, blocking, long-running query, Always On, and summary checks.
- A Daily Health Check SOP in PDF format.
- Prerequisites, installation, permissions, usage, and troubleshooting guides.
- A sample health-check report.
- A license template and changelog.

## Safety first

The included SQL scripts are designed to be **read-only**. They do not execute `KILL`, `ALTER`, `DBCC SHRINK*`, restart services/jobs, delete data, rebuild indexes, or change SQL Server configuration.

Always review scripts in a non-production environment before using them in production. Some checks require elevated metadata permissions such as `VIEW SERVER STATE` or access to `msdb`.

## Suggested daily workflow

1. Run `Scripts/10-Health-Check-Summary.sql` for a quick overview.
2. If a check returns `WARNING` or `CRITICAL`, run the matching detailed script.
3. Validate the finding against your organization's RPO, RTO, maintenance windows, and operational standards.
4. Escalate or remediate using your approved production procedures.
5. Record the finding in your ticketing/operations system when required.

## Supported scope

The scripts are written for Microsoft SQL Server and target commonly used DMV/metadata features available in modern supported releases. Always test against the exact SQL Server versions and editions you operate.

## Configuration

Thresholds are intentionally configurable. Do not treat the defaults as universal production policy.

Common defaults used in the toolkit:

- Full backup warning: 24 hours
- Log backup warning: 30 minutes
- Long-running request warning: 15 minutes
- Blocking warning: 60 seconds

Edit the variables near the top of each applicable script to match your environment.

## Folder structure

```text
SQL-Server-Daily-Health-Check-Toolkit/
├── README.md
├── LICENSE-TEMPLATE.txt
├── CHANGELOG.md
├── SOP/
│   └── SQL-Server-Daily-Health-Check-SOP.pdf
├── Scripts/
│   ├── 01-Instance-Health.sql
│   ├── 02-Database-Status.sql
│   ├── 03-Backup-Health.sql
│   ├── 04-SQL-Agent-Failures.sql
│   ├── 05-Database-Space.sql
│   ├── 06-Transaction-Log-Health.sql
│   ├── 07-Blocking-Sessions.sql
│   ├── 08-Long-Running-Queries.sql
│   ├── 09-AlwaysOn-Health.sql
│   └── 10-Health-Check-Summary.sql
├── Documentation/
│   ├── Prerequisites.md
│   ├── Installation.md
│   ├── How-To-Use.md
│   ├── Permissions.md
│   └── Troubleshooting.md
└── Sample-Output/
    └── Health-Check-Sample.pdf
```

## Disclaimer

This toolkit is operational guidance, not a substitute for your organization's change, security, backup, recovery, or incident-management procedures. Validate every recommendation before taking action in production.
