"""Exercise Unix installer modes with local Git repositories and temporary homes.

Requires Git, curl, and mise >= 2026.11.7. Applies dotfiles only.
Run with: python3 tests/install.py
"""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def run(command, environment, cwd):
    result = subprocess.run(
        command, env=environment, cwd=cwd, text=True, capture_output=True,
        timeout=60,
    )
    if result.returncode:
        raise RuntimeError(
            f"{command}\n{result.stdout[-2000:]}\n{result.stderr[-3000:]}"
        )
    return result.stdout + result.stderr


def commit(repository, environment, message):
    run(["git", "add", "."], environment, repository)
    run([
        "git", "-c", "user.name=Test", "-c", "user.email=test@example.com",
        "commit", "-qm", message,
    ], environment, repository)


def main():
    with tempfile.TemporaryDirectory(prefix="dotfiles-install-") as directory:
        base = Path(directory)
        remote = base / "remote"
        shutil.copytree(ROOT, remote, ignore=shutil.ignore_patterns(".git", "__pycache__"))
        environment = dict(
            os.environ, GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_NOSYSTEM="1"
        )
        run(["git", "init", "-b", "main"], environment, remote)
        commit(remote, environment, "Fixture")

        result = subprocess.run(
            ["sh", str(ROOT / "scripts/install.sh"), "--connect", "--once"],
            env=environment, cwd=base, text=True, capture_output=True, timeout=60,
        )
        assert result.returncode != 0 and "Choose either" in result.stderr

        caller = base / "development"
        caller.mkdir()
        (caller / "mise.toml").write_text(
            '[vars]\ndotfiles_checkout = "/invalid-development-source"\n'
            '[dotfiles]\n"~/.caller-probe" = { content = "wrong source" }\n'
        )
        (caller / ".miserc.toml").write_text('env = ["identity"]\n')

        for mode in ("connect", "once", "migration", "dangling", "foreign"):
            home = base / mode
            home.mkdir()
            config = home / ".config/mise"
            checkout = home / ".local/share/mise/bootstrap-repo"
            isolated = dict(
                environment, HOME=str(home),
                XDG_CONFIG_HOME=str(home / ".config"),
                XDG_DATA_HOME=str(home / ".local/share"),
                XDG_STATE_HOME=str(home / ".local/state"),
                XDG_CACHE_HOME=str(home / ".cache"),
                MISE_CONFIG_DIR=str(config),
                MISE_DATA_DIR=str(home / ".local/share/mise"),
                MISE_STATE_DIR=str(home / ".local/state/mise"),
                MISE_CACHE_DIR=str(home / ".cache/mise"),
                DOTFILES_REPOSITORY=str(remote), MISE_YES="1",
            )
            if mode in ("dangling", "foreign"):
                config.parent.mkdir(parents=True)
                target = home / "other-config"
                if mode == "foreign":
                    target.mkdir()
                config.symlink_to(target)
                result = subprocess.run(
                    ["sh", str(ROOT / "scripts/install.sh"), "--connect"],
                    env=isolated, cwd=caller, text=True, capture_output=True, timeout=60,
                )
                assert result.returncode != 0
                assert "resolve that connection" in result.stderr
                assert config.is_symlink() and not checkout.exists()
                print(f"{mode} link rejected without changes")
                continue
            if mode == "migration":
                config.mkdir(parents=True)
                (config / "config.toml").write_text('[tools]\npython = "3.13"\n')
                (config / "miserc.toml").write_text('env = ["desktop"]\n')
                (config / "miserc.local.toml").write_text("env = []\n")
                (config / "config.local.toml").write_text('[settings]\nminimum_release_age = "99d"\n')
                (config / "conf.d").mkdir()
                (config / "conf.d/custom.toml").write_text('[tools]\nruby = "3.4"\n')
                (config / "mise.lock").write_text("# existing lockfile\n")

            install = [
                "sh", str(ROOT / "scripts/install.sh"),
                "--only", "dotfiles",
                "--once" if mode == "once" else "--connect",
            ]
            output = run(install, isolated, caller)
            installation_output = output
            assert config.is_symlink() == (mode != "once"), output
            assert (home / ".zshrc").exists(), output
            assert not (home / ".caller-probe").exists(), output
            assert (config / "conf.d/dotfiles.toml").exists() == (mode == "once")
            output = run(["mise", "tasks", "ls"], isolated, home)
            assert "dotfiles:identity" in output, output
            assert "dotfiles:update" not in output, output
            if mode != "once":
                run(["mise", "bootstrap", "--update", "--dry-run"], isolated, home)
                if mode == "connect":
                    config.unlink()
                    config.symlink_to(os.path.relpath(checkout, config.parent))
                run(install, isolated, caller)
            if mode == "once":
                run(install, isolated, caller)
                run(["sh", str(ROOT / "scripts/install.sh"), "--connect", "--only", "dotfiles"], isolated, home)
                assert config.is_symlink()
            if mode == "migration":
                assert list(config.parent.glob("mise.backup.*"))
                backup = next(config.parent.glob("mise.backup.*"))
                assert 'python = "3.13"' in (backup / "config.toml").read_text()
                assert (backup / "conf.d/custom.toml").exists()
                assert (backup / "mise.lock").exists()
                assert str(backup / "conf.d/custom.toml") in installation_output
                assert str(backup / "config.local.toml") in installation_output
                assert not (checkout / "config.local.toml").exists()
                assert (checkout / "miserc.local.toml").read_text() == "env = []\n"
                # The published update fixture contains no packages, tools, or hooks.
                for file in remote.glob("config.*.toml"):
                    file.unlink()
                (remote / "mise.toml").write_text('min_version = "2026.11.7"\n')
                (remote / "config.toml").write_text(
                    '[dotfiles]\n"~/.update-probe" = { content = "published update" }\n'
                )
                commit(remote, environment, "Published update")
                run(["mise", "bootstrap", "--update", "--yes"], isolated, home)
                # An explicit update still accepts a non-overlapping local edit.
                with (checkout / "config.toml").open("a") as file:
                    file.write("\n# unpublished local edit\n")
                run(["mise", "bootstrap", "--update", "--yes"], isolated, home)
                assert "unpublished local edit" in (checkout / "config.toml").read_text()
                assert (home / ".update-probe").read_text() == "published update"
                with (remote / "config.toml").open("a") as file:
                    file.write("\n# conflicting published edit\n")
                commit(remote, environment, "Conflicting update")
                result = subprocess.run(
                    ["mise", "bootstrap", "--update", "--yes"], env=isolated,
                    cwd=home, text=True, capture_output=True, timeout=60,
                )
                assert result.returncode != 0
                assert "unpublished local edit" in (checkout / "config.toml").read_text()
                print("native update applied clean changes and preserved conflicting local edits")
            print(f"{mode} passed")


if __name__ == "__main__":
    main()
