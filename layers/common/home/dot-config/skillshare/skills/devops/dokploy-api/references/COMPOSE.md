# Dokploy Compose

## Discovery

- Start with `project.all` to resolve `projectId`, `environmentId`,
  `composeId`, `appName`, server, ports, domains, mounts, and current
  `composeType`.
- Use `compose.one?composeId=...` before updating YAML, domains, ports, mounts,
  or lifecycle state.

## Lifecycle

- `compose.create`: create with `name`, `environmentId`, optional
  `description`, `appName`, `serverId`, `composeType`, and `composeFile`.
- `compose.update`: update metadata or Compose file fields exposed by Swagger.
- `compose.deploy`, `compose.redeploy`, `compose.stop`, `compose.delete`.

Confirm before production deploy/redeploy, stop, delete, or any update that
changes containers, images, networks, volumes, or exposed ports.

## Compose File Rules

- `composeType` is `docker-compose` or `stack`.
- `composeFile` is a YAML string in a JSON body, not a file upload.
- Do not set `container_name`; Dokploy-managed logs, metrics, networking, and
  generated service names can depend on its naming.
- Prefer Dokploy-managed domains and ports. If custom routing is necessary,
  connect services to the correct Dokploy network and verify labels against the
  target mode.
- For Docker Stack, put Traefik labels under `deploy.labels`, use prebuilt
  images, and ensure every node can pull private images.

## Verification

After deploy/update, read `compose.one`, check deployment history/status, and
inspect logs when available. If the task changes YAML, compare the stored
Compose file after the update instead of trusting the submitted payload.
