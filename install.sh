#!/usr/bin/env bash
# Instala esta configuración de niri + Noctalia en una CachyOS (Arch-based).
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/config"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
NIRI_DST="$CONFIG_HOME/niri"
NOCT_DST="$CONFIG_HOME/noctalia"

SCALE="1.0"
DRY_RUN=0
SYSTEM=0
INSTALL_PKGS=0

usage() {
  cat <<'EOF'
Uso: ./install.sh [opciones]

  --scale N            Escala de la pantalla (por defecto 1.0). Ej: --scale 1.5
  --system             Ajustes de sistema (pide sudo):
                         - desactiva NetworkManager-wait-online
                         - Color, ILoveCandy, VerbosePkgLists,
                           DisableDownloadTimeout y ParallelDownloads=10
                           en /etc/pacman.conf (con backup)
  --install-packages   Instala los paquetes de packages.txt (pide sudo)
  --dry-run            Muestra lo que haría sin tocar nada
  -h, --help           Esta ayuda

Ejemplos:
  ./install.sh
  ./install.sh --scale 1.5
  ./install.sh --scale 1.5 --system
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scale)
      [[ $# -ge 2 ]] || { echo "Falta el valor de --scale"; exit 1; }
      SCALE="$2"; shift 2 ;;
    --system) SYSTEM=1; shift ;;
    --install-packages) INSTALL_PKGS=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opción desconocida: $1"; echo; usage; exit 1 ;;
  esac
done

[[ "$SCALE" =~ ^[0-9]+([.][0-9]+)?$ ]] || { echo "Escala inválida: $SCALE"; exit 1; }

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
run() { if (( DRY_RUN )); then printf '[dry-run] %s\n' "$*"; else "$@"; fi; }

command -v niri >/dev/null || {
  echo "niri no está instalado. En CachyOS: instala el escritorio Niri (cachyos-niri-noctalia)."
  exit 1
}

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$CONFIG_HOME-backup-$STAMP"

# ── Backup ────────────────────────────────────────────────────────────────
if (( DRY_RUN )); then
  echo "[dry-run] backup en $BACKUP"
else
  mkdir -p "$BACKUP"
  for d in niri noctalia; do
    [[ -e "$CONFIG_HOME/$d" ]] && cp -a "$CONFIG_HOME/$d" "$BACKUP/"
  done
  log "Backup: $BACKUP"
fi

# ── niri ──────────────────────────────────────────────────────────────────
log "Instalando configuración de niri"
run mkdir -p "$NIRI_DST"
run cp -a "$SRC/niri/." "$NIRI_DST/"

# ── Noctalia ──────────────────────────────────────────────────────────────
log "Instalando configuración de Noctalia"
run mkdir -p "$NOCT_DST"
run install -m 644 "$SRC/noctalia/config.toml" "$NOCT_DST/config.toml"

# ── Salida de pantalla específica del equipo ──────────────────────────────
detect_output() {
  local out="" f
  if niri msg outputs >/dev/null 2>&1; then
    out="$(niri msg outputs 2>/dev/null | grep -oP '\(\K[^)]+' | head -n1 || true)"
  fi
  if [[ -z "$out" ]]; then
    for f in /sys/class/drm/card*-*/status; do
      [[ -r "$f" && "$(cat "$f")" == "connected" ]] || continue
      f="$(basename "$(dirname "$f")")"
      out="${f#*-}"
      break
    done
  fi
  echo "${out:-eDP-1}"
}

OUTPUT="$(detect_output)"
log "Salida detectada: $OUTPUT (escala $SCALE)"
if (( DRY_RUN )); then
  echo "[dry-run] escribir $NIRI_DST/cfg/display.local.kdl"
else
  cat > "$NIRI_DST/cfg/display.local.kdl" <<EOF
// Generado por install.sh el $(date -Iseconds)
// Específico de este equipo; no se versiona.
output "$OUTPUT" {
    scale $SCALE
    position x=0 y=0
}
EOF
fi

# ── Validación y recarga ──────────────────────────────────────────────────
if (( ! DRY_RUN )); then
  log "Validando niri"
  niri validate
  if command -v noctalia >/dev/null; then
    log "Validando Noctalia"
    noctalia config validate || true
    log "Recargando Noctalia"
    noctalia msg config-reload >/dev/null 2>&1 || true
  fi
fi

# ── Paquetes (opcional) ───────────────────────────────────────────────────
if (( INSTALL_PKGS )); then
  log "Instalando paquetes de packages.txt"
  mapfile -t PKGS < <(grep -vE '^[[:space:]]*(#|$)' "$REPO_DIR/packages.txt")
  if (( DRY_RUN )); then
    printf '[dry-run] sudo pacman -S --needed --noconfirm %s\n' "${PKGS[*]}"
  else
    sudo pacman -S --needed --noconfirm "${PKGS[@]}"
  fi
fi

# ── Ajustes de sistema (opcional) ─────────────────────────────────────────
if (( SYSTEM )); then
  log "Aplicando ajustes de sistema"
  CONF=/etc/pacman.conf
  if (( DRY_RUN )); then
    echo "[dry-run] backup y ajuste de $CONF"
    echo "[dry-run] systemctl disable NetworkManager-wait-online.service"
  else
    sudo cp -a "$CONF" "$CONF.bak.$STAMP"
    sudo sed -i -E 's/^[#[:space:]]*(Color)$/\1/' "$CONF"
    sudo sed -i -E 's/^[#[:space:]]*(VerbosePkgLists)$/\1/' "$CONF"
    sudo sed -i -E 's/^[#[:space:]]*(DisableDownloadTimeout)$/\1/' "$CONF"
    sudo sed -i -E 's/^[#[:space:]]*ParallelDownloads[[:space:]]*=.*/ParallelDownloads = 10/' "$CONF"
    if grep -qE '^[#[:space:]]*ILoveCandy' "$CONF"; then
      sudo sed -i -E 's/^[#[:space:]]*ILoveCandy$/ILoveCandy/' "$CONF"
    else
      sudo sed -i '/^ParallelDownloads = 10/a ILoveCandy' "$CONF"
    fi

    if systemctl is-enabled --quiet NetworkManager-wait-online.service 2>/dev/null; then
      sudo systemctl disable NetworkManager-wait-online.service
      sudo systemctl reset-failed NetworkManager-wait-online.service >/dev/null 2>&1 || true
    fi

    log "Diff de pacman.conf:"
    diff -u "$CONF.bak.$STAMP" "$CONF" || true
  fi
fi

log "Listo."
echo "Cierra y vuelve a entrar en la sesión de niri para aplicar todo."
echo "Backup: $BACKUP"
