---
name: dokploy-api
description: Manage Dokploy instances through the HTTP API and Swagger reference. Use when the user mentions Dokploy, Dokploy API, Dokploy Swagger, x-api-key, project.all, application deploys, Compose services, databases, domains, servers, backups, schedules, registries, or CI/CD automation for Dokploy.
---

# Dokploy API

Manage a Dokploy instance through its privileged HTTP API. Run it like an
operator: discover the live instance, verify the target, make the smallest
necessary request, then prove the resulting state.

## Operator Loop

1. Establish the target instance and credentials.
   Completion: `DOKPLOY_URL` points at the intended instance, the token is
   available only from env/secret storage, and no secret is printed.
2. Verify the live API shape before non-trivial writes.
   Completion: the local instance Swagger at `$DOKPLOY_URL/swagger` or the
   current docs page for the endpoint family has been checked for method,
   required fields, enum values, and response shape.
3. Discover IDs from the instance instead of trusting names.
   Completion: project, environment, application, compose, database, server, or
   integration IDs come from a read endpoint such as `project.all`, `*.one`, or
   the relevant `*.all` endpoint; names are used only after uniqueness is clear.
4. Classify the operation.
   Completion: destructive, interrupting, credential-bearing, infrastructure,
   or production operations have explicit user confirmation; read-only and
   low-risk idempotent updates may proceed with stated assumptions.
5. Execute with a minimal, auditable request.
   Completion: the request uses `/api/<resource>.<action>`, sends
   `x-api-key`, uses JSON bodies for writes, and avoids logging secrets.
6. Verify after every mutation.
   Completion: a follow-up read, deployment list, health/status check, logs, or
   CI result confirms the new state or captures the failure details.

## Defaults

Use these shell variables in examples and scripts:

```bash
export DOKPLOY_URL="https://dokploy.example.com"
export DOKPLOY_API_KEY="your-generated-token"
```

Normalize `DOKPLOY_URL` without a trailing slash. The API base is
`$DOKPLOY_URL/api`; the default OpenAPI base in the docs is
`http://localhost:3000/api`. Tokens are generated from
`/settings/profile` in the API/CLI section and are sent as `x-api-key`.

Use this request shape:

```bash
curl -fsS "$DOKPLOY_URL/api/project.all" \
  -H "accept: application/json" \
  -H "x-api-key: $DOKPLOY_API_KEY"
```

For writes:

```bash
curl -fsS -X POST "$DOKPLOY_URL/api/application.deploy" \
  -H "accept: application/json" \
  -H "content-type: application/json" \
  -H "x-api-key: $DOKPLOY_API_KEY" \
  -d '{"applicationId":"APPLICATION_ID"}'
```

## Workflows

### Inventory

Start most tasks with `GET /api/project.all`; it returns projects and nested
applications, Compose services, and databases. Use `project.one` when the
project is known, `project.allForPermissions` for permission-limited views, and
resource-specific `*.one` endpoints before changing a single service.

### Applications

Create with `application.create`, inspect with `application.one`, configure
provider/build/env/domain/ports/mounts through `application.save*` endpoints,
then start, stop, deploy, redeploy, or reload through the matching action
endpoint. Treat `application.deploy`, `application.redeploy`,
`application.stop`, `application.delete`, queue cleanup, and env/build-secret
updates as confirmation-gated operations.

For CI/CD, store `DOKPLOY_URL`, `DOKPLOY_API_KEY`, and the target resource ID as
CI secrets. Build and push images in CI when production should not build on the
Dokploy host, then trigger Dokploy with `application.deploy` or
`compose.deploy`.

### Compose

Create with `compose.create`; pass `composeType` as `docker-compose` or `stack`
and `composeFile` as a YAML string, not a file upload. Use `compose.one` before
updates and `compose.deploy`, `compose.redeploy`, `compose.stop`, or
`compose.delete` for lifecycle actions. Avoid `container_name`; it can break
Dokploy-managed logs, metrics, and service naming. For Docker Stack, put Traefik
labels under `deploy.labels`, use prebuilt images, and pass registry auth when
needed.

### Databases

Use the resource family for the engine: `postgres.*`, `mysql.*`, `mariadb.*`,
`mongo.*`, or `redis.*`. Confirm generated usernames, passwords, external ports,
mounts, and backup settings before exposing or rotating anything. Never print
database passwords returned by inventory calls unless the user explicitly asks
for secret recovery.

### Domains, Ports, Mounts, Redirects

Prefer Dokploy domain and port endpoints over hand-edited Traefik labels unless
the service requires custom routing. Verify `appName`, target resource ID, and
service type before creating domains, ports, redirects, or mounts.

### Servers and Cluster

Server creation requires connection details such as `ipAddress`, `port`,
`username`, `sshKeyId`, and `serverType` (`deploy` or `build`). Treat server,
SSH key, cluster, swarm, registry, security, and Traefik settings changes as
infrastructure operations requiring confirmation and post-change connectivity
checks.

### Backups, Rollbacks, Schedules

Backups and volume backups may contain sensitive data; rollbacks and restores
can overwrite running state. Confirm target ID, timestamp/version, and expected
downtime before running backup, restore, rollback, or schedule mutations.

## Safety Gates

Ask for confirmation before:

- production deploys, redeploys, rollbacks, restores, or stops
- deletes, queue cleanup, maintenance cleanup, or bulk changes
- database credential, env var, build secret, registry, SSH key, server, swarm,
  security, or Traefik changes
- any operation where the target is matched by a non-unique name

Never commit, echo, or include in final answers: API keys, database passwords,
SSH keys, registry credentials, build secrets, env files, or full API responses
that contain secrets. Redact as `<redacted>` while preserving IDs and names
needed for verification.

## Errors

Dokploy errors commonly return `code`, `message`, and `issues`.

- `UNAUTHORIZED`: missing/invalid `x-api-key`, wrong instance, or expired token.
- `FORBIDDEN`: role, project permission, or API/CLI access not granted.
- `NOT_FOUND`: stale ID, wrong resource family, or wrong instance.
- `BAD_REQUEST`: schema mismatch; re-check Swagger for required fields and enum
  values.

If a write returns `{}` or minimal data, do not assume success. Read the resource
again, check deployment records, or inspect logs/status.

## Reference

Read only the branch reference needed for the task:

- Application create, provider setup, build settings, env, deploy, stop, or app
  networking: [references/APPLICATIONS.md](references/APPLICATIONS.md)
- Compose services, Compose YAML, Docker Compose vs Swarm stack, or Compose
  deploys: [references/COMPOSE.md](references/COMPOSE.md)
- Postgres, MySQL, MariaDB, Mongo, Redis, database credentials, database ports,
  or database backups: [references/DATABASES.md](references/DATABASES.md)
- Servers, SSH keys, registries, Docker, Swarm, cluster, security, settings, or
  Traefik instance changes: [references/INFRASTRUCTURE.md](references/INFRASTRUCTURE.md)
- Deployment history, previews, rollbacks, backups, restores, schedules, status
  checks, logs, or CI/CD triggers: [references/OPERATIONS.md](references/OPERATIONS.md)

Keep exact field decisions tied to the live Swagger because Dokploy versions can
change schemas.
