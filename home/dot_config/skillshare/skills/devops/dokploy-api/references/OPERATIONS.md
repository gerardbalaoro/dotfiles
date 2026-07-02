# Dokploy Operations

## Deployment Records and Status

- `deployment.all`: inspect deployment records.
- `deployment.allByServer`: inspect deployments scoped to a server.
- `previewDeployment.all`: inspect preview deployments.
- Resource-specific status/log endpoints may exist under application, compose,
  database, server, or Docker families; use Swagger to select the exact route.

Use deployment records and logs to verify lifecycle writes that return `{}`.

## Rollbacks, Backups, Restores

- `rollback.*`: rollback application or service deployments.
- `backup.*`: backup configuration and backup/restore actions.
- `volumeBackups.*`: volume backup configuration and actions.

Before rollback or restore, record the target resource ID, current state,
selected backup/deployment version, expected downtime, and confirmation. After
completion, verify status and capture the resulting version or deployment ID.

## Schedules and Maintenance

- `schedule.*`: scheduled jobs and recurring maintenance.
- `settings.cleanAll` and related cleanup endpoints can remove queues, Docker
  artifacts, or other instance state depending on version.

Confirm before creating, changing, disabling, or deleting schedules that affect
production. Confirm before cleanup or bulk maintenance.

## CI/CD Triggers

Store `DOKPLOY_URL`, `DOKPLOY_API_KEY`, and target IDs as CI secrets. Use
`curl -fsS` so HTTP failures fail the job.

Application deploy:

```bash
curl -fsS -X POST "$DOKPLOY_URL/api/application.deploy" \
  -H "accept: application/json" \
  -H "content-type: application/json" \
  -H "x-api-key: $DOKPLOY_API_KEY" \
  -d "{\"applicationId\":\"$DOKPLOY_APPLICATION_ID\"}"
```

Compose deploy:

```bash
curl -fsS -X POST "$DOKPLOY_URL/api/compose.deploy" \
  -H "accept: application/json" \
  -H "content-type: application/json" \
  -H "x-api-key: $DOKPLOY_API_KEY" \
  -d "{\"composeId\":\"$DOKPLOY_COMPOSE_ID\"}"
```

When production should not build on the Dokploy host, build and push the image
in CI, then trigger Dokploy to deploy the already-pushed image.

## Redacted Inventory

Use redaction when sharing inventory output:

```bash
curl -fsS "$DOKPLOY_URL/api/project.all" \
  -H "accept: application/json" \
  -H "x-api-key: $DOKPLOY_API_KEY" |
  jq 'walk(if type == "object" then
    with_entries(if (.key|test("password|secret|token|key"; "i")) then
      .value = "<redacted>"
    else . end)
  else . end)'
```
