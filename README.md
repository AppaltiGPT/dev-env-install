# dev-env-install

The first step to install the Cato work environment on a Mac. Open Terminal and paste:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/AppaltiGPT/dev-env-install/main/install.sh)"
```

It installs Homebrew and the GitHub CLI, signs you in with your GitHub user (the browser opens) and
downloads the private dev-env repo. From there on it decides what to install, based on the access
you've been given: you don't have to choose anything.

If it says your user can't see the repo, ask whoever invited you to add you to the right team and
run the same command again: it only redoes what is missing.

This repo is public because it is the piece you need **before** you have access to anything. That is
why it only contains `install.sh`, which carries no secrets and no names of internal systems.
