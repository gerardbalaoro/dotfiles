# Dokploy Databases

## Discovery

- Start with `project.all`; database entries are nested by engine family.
- Resolve the exact engine and ID before mutation: `postgresId`, `mysqlId`,
  `mariadbId`, `mongoId`, or `redisId`.
- Use the engine-specific `*.one` endpoint when available before update, stop,
  delete, backup, restore, or port changes.

## Endpoint Families

- `postgres.*`
- `mysql.*`
- `mariadb.*`
- `mongo.*`
- `redis.*`

Typical actions include create, inspect, update/save environment, start, stop,
deploy/redeploy, delete, ports, mounts, backups, restores, and settings. Use the
live Swagger for the actual action names and required body fields.

## Credential Policy

- `project.all` can return generated database users, passwords, root passwords,
  and external ports.
- Redact passwords and secrets by default; reveal them only when the explicit
  user task is credential recovery or connection setup.
- Confirm before rotating credentials, exposing external ports, changing mounts,
  restoring a backup, deleting data, or stopping a production database.

## Verification

After mutation, read the database resource again and verify application status,
ports, backup records, or restore result. For credential changes, verify the
consumer app was updated or clearly report that it still needs updating.
