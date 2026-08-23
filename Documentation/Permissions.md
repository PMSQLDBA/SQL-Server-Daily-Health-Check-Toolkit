# Permissions

Permissions vary by SQL Server version and security model. Grant only what your organization approves.

## Typical requirements

### Instance and DMV checks

Many server-level DMV queries require:

```sql
GRANT VIEW SERVER STATE TO [YourMonitoringLogin];
```

On newer SQL Server releases, some DMVs may use more granular permissions such as `VIEW SERVER PERFORMANCE STATE`. Confirm requirements for your exact version.

### Backup history

Backup checks read metadata in `msdb`, including backup history tables.

### SQL Agent history

SQL Agent checks read `msdb` job and job-history metadata. Membership in an appropriate SQL Agent database role may be required depending on your security model.

### Always On

Availability Group DMVs require HADR to be enabled and appropriate metadata/server-state permissions.

## Least privilege recommendation

Create a dedicated monitoring login only if your security team approves it. Avoid granting `sysadmin` solely to make monitoring queries work.
