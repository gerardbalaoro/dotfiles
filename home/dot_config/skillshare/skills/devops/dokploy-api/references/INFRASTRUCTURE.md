# Dokploy Infrastructure

## Servers

- `server.create` currently requires `name`, `description`, `ipAddress`, `port`,
  `username`, `sshKeyId`, and `serverType` (`deploy` or `build`);
  `enableDockerCleanup` defaults to true where supported.
- `server.one?serverId=...` inspects a server.
- Other `server.*` endpoints handle updates, status checks, Docker cleanup, and
  deletion when exposed by the live Swagger.

Confirm before creating, deleting, or changing servers, because these operations
can affect deployment placement and connectivity.

## Access and Integrations

- SSH keys and routing: `sshKey.*`, `sshRouter.*` when present.
- Registries: `registry.*`; never print registry tokens or passwords.
- Git providers: `github.*`, `gitlab.*`, `gitea.*`, `bitbucket.*`,
  `gitProvider.*`; resolve provider IDs before attaching them to apps.
- Certificates: `certificates.*`.
- Notifications: `notification.*`.

## Docker, Swarm, Cluster

- `destination.*`, `docker.*`, `swarm.*`, and `cluster.*` govern placement,
  Docker behavior, Swarm, and cluster state.
- Treat Swarm/cluster mutations as infrastructure changes requiring
  confirmation and rollback notes.
- Check node connectivity and deployment status after changes.

## Instance Settings and Admin

- `settings.*` includes instance-level settings such as cleanup and Traefik port
  changes.
- `security.*`, `admin.*`, `organization.*`, `user.*`, and `stripe.*` are
  privileged/admin areas.

Require explicit confirmation before settings, security, admin, user,
organization, or Traefik changes. Use the smallest sufficient token scope and
verify the instance still responds afterward.
