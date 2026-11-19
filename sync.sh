#!/usr/bin/env bash
# Copia la configuración viva de este equipo al repo (sistema → repo).
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/config"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

[[ -e "$CONFIG_HOME/niri/config.kdl" ]] || {
  echo "No existe $CONFIG_HOME/niri/config.kdl. ¿Está instalada la config?"
  exit 1
}

mkdir -p "$SRC/niri/cfg" "$SRC/noctalia"

log "Copiando config.kdl"
cp "$CONFIG_HOME/niri/config.kdl" "$SRC/niri/config.kdl"

log "Copiando cfg/*.kdl"
for f in "$CONFIG_HOME"/niri/cfg/*.kdl; do
  [[ -e "$f" ]] || continue
  b="$(basename "$f")"
  case "$b" in
    display.local.kdl|hot-rules.kdl|*.bkp|*.bkp*|*.bak) continue ;;
  esac
  cp "$f" "$SRC/niri/cfg/$b"
done

if [[ -e "$CONFIG_HOME/noctalia/config.toml" ]]; then
  log "Copiando Noctalia config.toml"
  cp "$CONFIG_HOME/noctalia/config.toml" "$SRC/noctalia/config.toml"
fi

# Aviso: nada de rutas personales antes de publicar
if grep -rInE '/home/[^/]+' "$SRC" >/dev/null 2>&1; then
  echo
  echo "AVISO: hay rutas personales en config/. Revísalas antes de publicar:"
  grep -rInE '/home/[^/]+' "$SRC" || true
fi

echo
log "Sincronizado."
echo "Revisa el diff y publica:"
echo "  git add -A && git commit -m 'Actualiza configuración' && git push"
