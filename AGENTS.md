# Agent Instructions

## Working Agreements

- Treat architectural questions as discussion until the user asks for implementation.
- Keep provisioning and dotfile deployment in mise; do not introduce another manager.
- Validate with syntax checks or isolated temporary home directories. Do not provision the current host solely to verify changes.

## Mise Resources

Start with the [official documentation index](https://mise.jdx.dev/llms.txt) to locate the relevant reference:

- [Bootstrap](https://mise.jdx.dev/bootstrap.html): packages, lifecycle, and hooks.
- [Dotfile Groups](https://mise.jdx.dev/dotfiles/groups.html): directory deployment and entry exceptions.
- [Configuration](https://mise.jdx.dev/configuration.html) and [Config Environments](https://mise.jdx.dev/configuration/environments.html): includes, precedence, and platform selection.
- [Tera Templates](https://mise.jdx.dev/templates.html): supported functions, context, and rendering restrictions.
- [Task Configuration](https://mise.jdx.dev/tasks/task-configuration.html): task properties and dependencies.

Check the installed version with `mise --version` and supported flags with the relevant subcommand's `--help`.
Check feature availability against `min_version` before changing configuration.
For version-specific behavior, consult documentation at the matching release tag in [jdx/mise](https://github.com/jdx/mise).

## Task-Specific Guidance

Read the relevant skill when the task requires it:

- [Git Conventions](.agents/skills/git-conventions/SKILL.md): Git operations, commits, branches, and pull requests.
- [Writing Documentation](.agents/skills/writing-documentation/SKILL.md): Documentation and code comments.
