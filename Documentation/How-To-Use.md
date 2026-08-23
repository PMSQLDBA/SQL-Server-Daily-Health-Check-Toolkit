# How to Use

## Daily procedure

1. Connect to the target SQL Server instance.
2. Confirm you are on the correct server and environment.
3. Run `10-Health-Check-Summary.sql`.
4. Review each result as `PASS`, `INFO`, `WARNING`, or `CRITICAL`.
5. For non-PASS findings, run the matching detailed script.
6. Compare findings with your organization's operational standards.
7. Escalate or remediate only through approved procedures.

## Severity meaning

- `PASS`: The check did not find a condition outside the configured threshold.
- `INFO`: Informational output that may need context but is not automatically a problem.
- `WARNING`: A condition deserves DBA review but may be expected or non-urgent.
- `CRITICAL`: A condition can indicate material service, recoverability, or availability risk and should be investigated promptly.

## Important interpretation notes

A warning is not automatically an incident. Examples:

- A reporting database may intentionally be read-only.
- A DR replica may intentionally use asynchronous commit.
- A SIMPLE recovery database does not require transaction log backups.
- A backup may be older than the default threshold because the organization's policy is different.

Always interpret output in context.
