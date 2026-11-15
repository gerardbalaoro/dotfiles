"""Validate checkout path rendering with mise's actual template engine."""

import os
from pathlib import Path
import subprocess
import tempfile
import tomllib

ROOT = Path(__file__).resolve().parents[1]


def main():
    config = tomllib.loads((ROOT / 'config.toml').read_text())
    template = config['vars']['dotfiles_checkout']
    assert template == config['settings']['dotfiles']['root']
    # Supply canonical Windows paths directly so this regression runs on Unix too.
    template = template.replace('config_source | canonicalize | dirname', 'vars.source_path')
    cases = [
        (r'\\?\C:\Users\Gerard\AppData\Local\mise\bootstrap-repo',
         'C:/Users/Gerard/AppData/Local/mise/bootstrap-repo'),
        (r'\\?\C:\Users\Gerard Name\repo', 'C:/Users/Gerard Name/repo'),
        (r'\\?\UNC\server\share\repo', '//server/share/repo'),
        (r'C:\Users\Gerard\repo', 'C:/Users/Gerard/repo'),
        (r'\\server\share\repo', '//server/share/repo'),
        ('/home/gerard/repo', '/home/gerard/repo'),
    ]
    with tempfile.TemporaryDirectory(prefix='dotfiles-paths-') as directory:
        base = Path(directory)
        environment = dict(
            os.environ, MISE_CONFIG_DIR=str(base / 'config'),
            MISE_DATA_DIR=str(base / 'data'), MISE_STATE_DIR=str(base / 'state'),
            MISE_CACHE_DIR=str(base / 'cache'), MISE_TRUSTED_CONFIG_PATHS=directory,
        )
        for source, expected in cases:
            (base / 'mise.toml').write_text(
                f"[vars]\nsource_path = '''{source}'''\nnormalized = '''{template}'''\n"
            )
            result = subprocess.run(
                ['mise', 'vars', 'normalized'], cwd=base, env=environment,
                text=True, capture_output=True, check=True, timeout=30,
            )
            assert result.stdout.strip() == expected, result.stdout
    print('Drive, UNC, spaced, and Unix checkout paths passed')


if __name__ == '__main__':
    main()
