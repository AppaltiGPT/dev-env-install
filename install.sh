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
[ "$(uname -s)" = Darwin ] || die "questo installer e' per macOS"
# Con `curl … | bash` lo stdin e' lo script stesso: Homebrew e il login GitHub non potrebbero chiedere
# niente, e l'installazione si fermerebbe a meta' con un errore che non dice perche'.
[ -t 0 ] || die "lancialo cosi', non con una pipe:
    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/$REPO-install/main/install.sh)\""
fi

say "Homebrew"
if ! command -v brew > /dev/null 2>&1; then
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && { eval "$("$b" shellenv)"; break; }; done
fi
if ! command -v brew > /dev/null 2>&1; then
  echo "  lo installo: il Mac ti chiede la password una volta"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && { eval "$("$b" shellenv)"; break; }; done
  command -v brew > /dev/null 2>&1 || die "Homebrew non risulta installato: rilancia questo comando"
fi
# Senza questa riga, nel prossimo Terminale `brew` e tutto quello che installa non ci sarebbero.
riga="eval \"\$($(command -v brew) shellenv)\""
grep -qsF "$riga" "$HOME/.zprofile" || printf '\n%s\n' "$riga" >> "$HOME/.zprofile"
ok "$(brew --version | head -1)"

say "GitHub"
command -v gh > /dev/null 2>&1 || brew install gh > /dev/null
if ! gh auth status -h github.com > /dev/null 2>&1; then
  echo "  si apre il browser: entra con il tuo utente GitHub"
  gh auth login -h github.com -p https -w -s read:packages
fi
gh auth setup-git > /dev/null 2>&1 || true
utente="$(gh api user -q .login 2> /dev/null || echo "?")"
ok "sei $utente"

say "Il repo del dev-env"
if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only -q || die "non riesco ad aggiornare $DEST: guarda 'git -C $DEST status'"
  ok "aggiornato in $DEST"
elif gh repo clone "$REPO" "$DEST" -- -q 2> /dev/null; then
  ok "clonato in $DEST"
else
  die "il tuo utente GitHub ($utente) non vede il repo $REPO. Chiedi a chi ti ha invitato in Cato di
    aggiungerti al team giusto, poi rilancia questo comando."
fi
# I comandi di sempre stanno in ~/.cato-setup: un link alla cartella bootstrap/ li tiene validi.
if [ ! -e "$LINK" ] && [ ! -L "$LINK" ]; then
  ln -s "$DEST/bootstrap" "$LINK"
fi

exec bash "$DEST/bootstrap/installa.sh" "$@"
