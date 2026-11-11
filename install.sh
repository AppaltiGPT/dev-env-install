#!/usr/bin/env bash
# install.sh — installa l'ambiente di lavoro Cato su un Mac.
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/AppaltiGPT/dev-env-install/main/install.sh)"
#
# E' pubblico apposta, quindi fa solo quello che serve per arrivare al repo privato: Homebrew, la CLI
# di GitHub, il login GitHub e il clone. Poi passa la mano allo script che sta la' dentro, e da li' in
# poi cosa si installa lo decidono i permessi della persona, non questo file.
set -euo pipefail
REPO="AppaltiGPT/dev-env"
DEST="${CATO_DEV_ENV_DIR:-$HOME/.cato-dev-env}"
LINK="$HOME/.cato-setup"

say() { printf '\n▸ %s\n' "$*"; }
ok()  { printf '  ✔ %s\n' "$*"; }
die() { printf '\n  ✗ %s\n' "$*" >&2; exit 1; }

# `CATO_INSTALL_PROVA=1` salta i due controlli sull'ambiente (macOS, terminale): serve alle prove in
# CI, che girano su Linux e senza terminale. Non cambia nient'altro.
if [ "${CATO_INSTALL_PROVA:-0}" != 1 ]; then
[ "$(uname -s)" = Darwin ] || die "this installer is for macOS"
# Con `curl … | bash` lo stdin e' lo script stesso: Homebrew e il login GitHub non potrebbero chiedere
# niente, e l'installazione si fermerebbe a meta' con un errore che non dice perche'.
[ -t 0 ] || die "run it like this, not through a pipe:
    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/$REPO-install/main/install.sh)\""
fi

say "Homebrew"
if ! command -v brew > /dev/null 2>&1; then
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && { eval "$("$b" shellenv)"; break; }; done
fi
if ! command -v brew > /dev/null 2>&1; then
  echo "  installing it: the Mac asks for your password once"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && { eval "$("$b" shellenv)"; break; }; done
  command -v brew > /dev/null 2>&1 || die "Homebrew does not look installed: run this command again"
fi
# Senza questa riga, nel prossimo Terminale `brew` e tutto quello che installa non ci sarebbero.
riga="eval \"\$($(command -v brew) shellenv)\""
grep -qsF "$riga" "$HOME/.zprofile" || printf '\n%s\n' "$riga" >> "$HOME/.zprofile"
ok "$(brew --version | head -1)"

say "GitHub"
command -v gh > /dev/null 2>&1 || brew install gh > /dev/null
if ! gh auth status -h github.com > /dev/null 2>&1; then
  echo "  the browser opens: sign in with your GitHub user"
  gh auth login -h github.com -p https -w -s read:packages
fi
gh auth setup-git > /dev/null 2>&1 || true
utente="$(gh api user -q .login 2> /dev/null || echo "?")"
ok "you are $utente"

say "The dev-env repo"
if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only -q || die "cannot update $DEST: look at 'git -C $DEST status'"
  ok "updated in $DEST"
elif gh repo clone "$REPO" "$DEST" -- -q 2> /dev/null; then
  ok "cloned in $DEST"
else
  die "your GitHub user ($utente) cannot see the $REPO repo. Ask whoever invited you to Cato to
    add you to the right team, then run this command again."
fi
# I comandi di sempre stanno in ~/.cato-setup: un link alla cartella bootstrap/ li tiene validi.
if [ ! -e "$LINK" ] && [ ! -L "$LINK" ]; then
  ln -s "$DEST/bootstrap" "$LINK"
fi

exec bash "$DEST/bootstrap/installa.sh" "$@"
