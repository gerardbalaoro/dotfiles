# Composing Commits

We prefer commits to be logical and focused on a specific unit of work.
A commit may include multiple files or several related changes, and it does not need to deliver a complete feature on its own.
Avoid mixing unrelated work; each commit should focus on one concern, domain, or intent.

We use the conventional commit message format:

```
<type>(<scope>): <subject>
```

Use the appropriate type for the change:

| Type        | Description                                                                 |
| ----------- | --------------------------------------------------------------------------- |
| `feat`      | A config or script has been added or changed.                               |
| `fix`       | A fix on a pre-existing config or script that is faulty.                    |   
| `refactor`  | A change that does change the end result of a script or config.             |
| `chore`     | A change on the project setup, not on the actual config or script managed.  |

Adding a scope is encouraged, but not always required.
The ideal scope of a commit is the "domain" or "tech" the changes are related to.
Here are some known scopes:

- `agents`: Changes related to agent configuration managed, not agent configuration of the project itself.
- `git`: Changes related to git configuration or scripts.
- `shell`: Changes related to shell configuration or scripts, may it be PowerShell, Bash, Zsh, or Fish.
   Also includes configuration that manage the shell prompt such as `oh-my-posh`, `oh-my-zsh`, or `starship`.
- `ssh`: Changes related to ssh configuration, keys, or scripts.
- `terminal`: Changes related to terminal configuration or scripts, may it be Windows Terminal, iTerm2, or Alacritty.
- `tools`: Changes related to package managers, package installation, or scripts that manage tools.
- `system`: Changes related to system configuration or scripts, may it be Windows, Linux, or macOS.

OS-specific changes should not have their own scope, attempt to use the "domain" related to the change instead.
Project-specific changes such as doc updates, setup files and scripts, `chezmoi`-related changes,
also should not have a scope as they are considered "global".

A good rule is that anything inside the `/home` directory and does not begin with `.chezmoi` is global and project-specific.
The only exception is `.chezmoiscripts/`, which depends on what the specific change is.