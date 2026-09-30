#!/usr/bin/env bash
# test-install.sh — prove del primo stadio. brew, gh e git sono finti; il secondo stadio anche.
set -uo pipefail
cd "$(dirname "$0")"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/test-install.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
ok=0; ko=0
t() {
  if [ "$2" = "$3" ]; then ok=$((ok + 1)); printf '  ok   %s\n' "$1"
  else ko=$((ko + 1)); printf '  NO   %s\n       ottenuto: %s\n       atteso:   %s\n' "$1" "$2" "$3"; fi
}
mkdir -p "$TMP/bin" "$TMP/home"
cat > "$TMP/bin/brew" <<'SH'
#!/bin/sh
case "$1" in --version) echo "Homebrew 5.0.0" ;; shellenv) : ;; *) echo "brew $*" >> "$FINTI/brew.log" ;; esac
SH
cat > "$TMP/bin/gh" <<'SH'
#!/bin/sh
case "$1 $2" in
  "auth status") [ -f "$FINTI/loggato" ] ;;
  "auth login") echo login >> "$FINTI/gh.log"; : > "$FINTI/loggato" ;;
  "auth setup-git") : ;;
  "api user") echo "persona-finta" ;;
  "repo clone")
    [ -f "$FINTI/senza-accesso" ] && exit 1
    mkdir -p "$4/.git" "$4/bootstrap"
    printf '#!/bin/sh\necho "SECONDO STADIO $*"\n' > "$4/bootstrap/installa.sh" ;;
esac
SH
chmod +x "$TMP/bin/brew" "$TMP/bin/gh"
export FINTI="$TMP" PATH="$TMP/bin:$PATH" HOME="$TMP/home"
lancia() { CATO_INSTALL_PROVA=1 bash ./install.sh "$@" < /dev/null 2>&1; }

printf '\n== senza terminale e senza l interruttore: si ferma e dice come lanciarlo\n'
out="$(bash ./install.sh < /dev/null 2>&1)"; rc=$?
t "esce 1"                         "$rc" "1"
t "e da' la forma giusta"          "$(printf '%s' "$out" | grep -c '/bin/bash -c')" "$( [ "$(uname -s)" = Darwin ] && echo 1 || echo 0)"

printf '\n== il giro normale\n'
out="$(lancia --devops)"; rc=$?
t "arriva al secondo stadio, con gli argomenti" "$(printf '%s' "$out" | grep -c 'SECONDO STADIO --devops')" "1"
t "fa il login GitHub"             "$(wc -l < "$TMP/gh.log" | tr -d ' ')" "1"
t "brew nel profilo della shell"   "$(grep -c 'shellenv' "$TMP/home/.zprofile")" "1"
t "~/.cato-setup punta a bootstrap/" "$(readlink "$TMP/home/.cato-setup")" "$TMP/home/.cato-dev-env/bootstrap"
lancia > /dev/null
t "rilanciato: niente secondo login" "$(wc -l < "$TMP/gh.log" | tr -d ' ')" "1"
t "e niente riga doppia nel profilo" "$(grep -c 'shellenv' "$TMP/home/.zprofile")" "1"

printf '\n== chi non vede il repo\n'
rm -rf "$TMP/home/.cato-dev-env" "$TMP/home/.cato-setup"; : > "$TMP/senza-accesso"
out="$(lancia)"; rc=$?
t "si ferma"                       "$rc" "1"
t "e dice chi e' e cosa chiedere"  "$(printf '%s' "$out" | grep -c 'persona-finta) non vede il repo')" "1"
rm -f "$TMP/senza-accesso"

printf '\n== un ~/.cato-setup vecchio non si tocca\n'
mkdir -p "$TMP/home/.cato-setup"; echo vecchio > "$TMP/home/.cato-setup/segno"
lancia > /dev/null
t "resta una cartella"             "$([ -L "$TMP/home/.cato-setup" ] && echo link || echo cartella)" "cartella"
t "col suo contenuto"              "$(cat "$TMP/home/.cato-setup/segno")" "vecchio"

printf '\n== ok=%d no=%d\n' "$ok" "$ko"
[ "$ko" = 0 ]
