# pzmcli
Project Zomboid Mod CLI (pzmcli) - terminal tool for create mods on Linux for Project Zomboid

Work in progress. Don't use yet.

## What is need to be done
- Self installer with self update.
- Create new mod with skeleton directories.
- Mock to Project Zomboid exported Java functions.
- Run tests to check mod.
- Prepare mod release.
- Make mod release to Steam without entering to Project Zomboid game.

## TODO
- Add VERSION file to mod

## Install
```bash
wget -O pzmcli.sh https://raw.githubusercontent.com/openzomboid/pzmcli/master/pzmcli.sh && chmod +x pzmcli.sh && ./pzmcli.sh self-install && rm pzmcli.sh
```

## Uninstall
```bash
pzmcli self-uninstall
```
