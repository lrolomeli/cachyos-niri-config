# CachyOS Niri + Noctalia — dotfiles

Configuración personal de **niri + Noctalia v5** para CachyOS (Arch-based), lista
para replicar en una instalación nueva con un solo comando.

## Requisitos

- CachyOS con el escritorio **Niri** instalado (`cachyos-niri-noctalia`).
- `git` para clonar. Opcionalmente `brightnessctl`, `capitaine-cursors`,
  `alacritty`, `firefox` y `nautilus` (ver `packages.txt`).

## Instalación en un equipo nuevo

```bash
git clone https://github.com/<usuario>/cachyos-niri-dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Con escala 1.5 (pantallas HiDPI o si prefieres todo más grande):

```bash
./install.sh --scale 1.5
```

Opciones:

| Opción | Qué hace |
|---|---|
| `--scale N` | Escala de la pantalla (por defecto `1.0`). |
| `--system` | Desactiva `NetworkManager-wait-online` y activa `Color`, `ILoveCandy`, `VerbosePkgLists`, `DisableDownloadTimeout` y `ParallelDownloads=10` en `/etc/pacman.conf` (con backup y diff). |
| `--install-packages` | Instala los paquetes de `packages.txt`. |
| `--dry-run` | Muestra lo que haría sin tocar nada. |

El script:

1. Hace backup de `~/.config/niri` y `~/.config/noctalia` en
   `~/.config-backup-YYYYMMDD-HHMMSS`.
2. Copia la configuración.
3. Detecta la salida de pantalla conectada y genera
   `~/.config/niri/cfg/display.local.kdl` con la escala elegida.
4. Valida con `niri validate` y `noctalia config validate`.
5. Recarga Noctalia (`noctalia msg config-reload`). niri recarga solo.

## Mantener el repo al día

Editas en vivo y luego:

```bash
cd ~/dotfiles
./sync.sh                       # sistema → repo
git diff                        # revisa
git add -A && git commit -m "Actualiza configuración" && git push
```

`sync.sh` excluye lo que no debe versionarse: `display.local.kdl`,
`hot-rules.kdl`, backups y `noctalia.kdl`.

## Estructura

```
config/
├── niri/
│   ├── config.kdl          # entrada; incluye cfg/*
│   └── cfg/
│       ├── animation.kdl
│       ├── autostart.kdl
│       ├── display.kdl          # plantilla genérica
│       ├── input.kdl
│       ├── keybinds.kdl         # atajos
│       ├── layout.kdl
│       ├── misc.kdl             # sin blur, screenshot-path
│       └── rules.kdl            # reglas de ventanas (sin blur global)
└── noctalia/
    └── config.toml         # barra minimalista + polkit
install.sh                  # repo → sistema
sync.sh                     # sistema → repo
packages.txt
```

## Atajos destacados

| Atajo | Acción |
|---|---|
| `Mod+W` / `Mod+Q` | Cerrar ventana |
| `Mod+Space` / `Mod+Ctrl+Return` | Lanzador |
| `Mod+↑/↓` | Ventana arriba/abajo; al final de la columna, cambia de escritorio |
| `Mod+Ctrl+↑/↓` | Mover ventana; al final de la columna, a otro escritorio |
| `Mod+RePág/AvPág` | Cambiar de escritorio |
| `Mod+Shift+Space` | Mostrar/ocultar barra |
| `Mod+Shift+Return` | Selector de fondo |
| `Mod+Shift+S` | Ajustes de Noctalia |
| `Mod+Shift+O` | Bloquear (alias de `Mod+Alt+L`) |

`Mod` = tecla Super/Windows (Cmd en teclados Apple).

## Notas

- **Escala**: por defecto `1.0`. El equipo donde se generó usa `1.5`, pero el
  repo queda portable; `install.sh` detecta el nombre de la salida
  (`eDP-1`, `DP-1`, …) y no lo fija a mano.
- **Noctalia**: la barra y el agente polkit están en
  `~/.config/noctalia/config.toml`, que es capa de usuario y no la sobrescribe
  el GUI. Ajustes hechos desde la interfaz se guardan en
  `~/.local/state/noctalia/settings.toml` y **no** se versionan aquí.
- **Sin datos personales**: no se versionan rutas de `/home`, wallpapers,
  estado de la app ni credenciales.
- **Rollback**: cada ejecución deja un backup; para volver atrás:
  ```bash
  cp -a ~/.config-backup-YYYYMMDD-HHMMSS/niri ~/.config/niri
  ```
- **Blur**: desactivado a propósito para mantener fluidez en iGPU modestas.

## Problemas comunes

- `niri validate` falla: revisa el mensaje; casi siempre es una coma o una
  llave en el `.kdl` editado.
- No aparece la barra: `noctalia msg bar-toggle` o reinicia Noctalia.
- La escala se ve mal: vuelve a ejecutar `./install.sh --scale 1.25` (o el
  valor que quieras); no requiere reiniciar la sesión.
