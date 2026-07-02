# Dokploy Applications

## Discovery

- Start with `project.all` to find the project, environment, application name,
  `applicationId`, `appName`, server, domains, ports, and related services.
- Use `application.one?applicationId=...` before changing an existing app.
- Use provider read/list endpoints to resolve Git provider IDs before saving a
  provider configuration.

## Lifecycle

- `application.create`: create from `name`, `environmentId`, and optional
  `appName`, `description`, `serverId`.
- `application.start`, `application.stop`, `application.deploy`,
  `application.redeploy`, `application.reload`, `application.delete`.
- `application.cleanQueues`: clear queued application work.

Confirm before deploy/redeploy in production, stop, delete, reload when it may
interrupt traffic, or queue cleanup.

## Configuration

- Source providers: `application.saveGithubProvider`,
  `application.saveGitlabProvider`, `application.saveBitbucketProvider`,
  `application.saveGiteaProvider`.
- Build settings: `application.saveBuildType`; live docs list build types such
  as `dockerfile`, `heroku_buildpacks`, `paketo_buildpacks`, `nixpacks`,
  `static`, and `railpack`.
- Environment: `application.saveEnvironment` with `env`, `buildArgs`,
  `buildSecrets`, and `createEnvFile`.
- Docker/image, ports, domains, mounts, redirects, preview deployment, and
  advanced settings use matching `application.save*` or resource-family
  endpoints; check Swagger for the exact endpoint before writing.

## Routing and Storage

- Prefer Dokploy `domain.*`, `port.*`, `mounts.*`, and `redirects.*` endpoints
  over manual Traefik labels unless custom routing is required.
- Verify `appName` as well as `applicationId`; many routing payloads need both.
- Avoid printing env, build args, build secrets, registry credentials, or full
  inventory responses.

## Verification

After mutation, read `application.one`, check deployment records, and inspect
status/logs when available. If a write returns `{}`, treat it as accepted, not
proved.
