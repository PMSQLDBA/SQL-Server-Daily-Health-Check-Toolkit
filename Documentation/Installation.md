# Installation

No SQL Server objects are installed by default.

1. Extract the toolkit to a secure DBA workstation or approved repository.
2. Review every `.sql` file before use.
3. Open the script in SSMS or your approved SQL client.
4. Review and adjust threshold variables near the top of applicable scripts.
5. Connect to the intended SQL Server instance.
6. Confirm the instance name and environment before execution.
7. Run `10-Health-Check-Summary.sql` first for a quick overview.
8. Run detailed scripts for any warnings or critical findings.

## Optional central repository

Teams may store the scripts in source control. Recommended practices include:

- Require code review for changes.
- Tag releases.
- Keep environment-specific values out of the source files.
- Do not store passwords, tokens, connection strings, or private server inventories in the repository.
