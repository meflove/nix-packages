# angeldust nix-packages

A personal [Nix flake](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-flake.html) of packages and Home Manager modules, built on [flake-parts](https://flake.parts) and [pkgs-by-name](https://github.com/drupol/pkgs-by-name-for-flake-parts), tracking `nixos-unstable`.

- **Systems:** `x86_64-linux`
- **Outputs:** `legacyPackages` (the package set), `overlays.default` (exposes it as `pkgs.angeldust-pkgs`), `homeModules`
- **Mirrors:** [GitHub](https://github.com/meflove/nix-packages) · [Codeberg](https://codeberg.org/angeldust/nix-packages) · [Tangled](https://tangled.org/did:plc:jv6arfakxixeyppnbxhf6blz)

## Packages

Run anything directly, e.g. `nix run github:meflove/nix-packages#purple`, or list them all:

```console
$ nix eval github:meflove/nix-packages#legacyPackages.x86_64-linux --apply 'ps: builtins.attrNames ps'
```

| Attribute                                          | Description                                                                                              |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `ani-cli-ru.api`                                   | `anicli_api` — parse anime from RU websites                                                              |
| `ani-cli-ru.client`                                | `anicli_ru` — watch anime from RU sources via mpv                                                        |
| `ani-cli-ru.uvicorn`                               | Pinned `uvicorn` ASGI server for the above                                                               |
| `blueferry`                                        | iPhone messages, notifications and contacts on Linux over Bluetooth (backend: CLI, TUI and D-Bus daemon) |
| `blueferry-gtk`                                    | BlueFerry GTK client (bundles the backend)                                                               |
| `blueferry-qt`                                     | BlueFerry Qt client (bundles the backend)                                                                |
| `blueferry-quickshell`                             | BlueFerry Quickshell (Wayland shell) client                                                              |
| `clipse`                                           | Clipboard manager TUI for Unix                                                                           |
| `opencodePlugins.oh-my-opencode-slim`              | Multi-agent orchestration plugin for OpenCode                                                            |
| `opencodePlugins.opencode-mem`                     | Persistent memory for coding agents via local Turso/libSQL vector search¹                                |
| `opencodePlugins.opencode-notify`                  | Native OS notifications for OpenCode¹                                                                    |
| `opencodePlugins.opencode-dynamic-context-pruning` | Prunes obsolete tool outputs from conversation context¹                                                  |
| `pipewire-soundpad`                                | Soundpad for Linux working via PipeWire                                                                  |
| `proton-cachyos-linuwux`                           | [Proton-Cachyos "LinUwUx" rework](https://github.com/xshaduwulfx/proton-linuwux) build for Steam         |
| `purple`                                           | Open-source terminal SSH manager and SSH config editor                                                   |
| `soundcloud-desktop`                               | SoundCloud desktop app                                                                                   |
| `yazi-plugins.cba-preview`                         | Yazi plugin to preview Comic Book Archive                                                                |
| `yazi-plugins.convert`                             | Yazi plugin to convert images                                                                            |
| `yazi-plugins.djvu-preview`                        | Yazi plugin for DjVu preview                                                                             |
| `yazi-plugins.office`                              | Yazi documents previewer using LibreOffice                                                               |
| `yazi-plugins.piper`                               | Pipe any shell command as a cached previewer for Yazi                                                    |
| `yazi-plugins.torrent-preview`                     | Yazi plugin to preview BitTorrent files                                                                  |
| `yazi-plugins.wl-clipboard`                        | Simple system clipboard for Yazi on Wayland                                                              |
| `yot`                                              | Watch YouTube videos with AI translation in mpv                                                          |
| `updater`                                          | The bulk package-updater script (also the default package — see [Updating](#updating))                   |

¹ These plugins still ship the OpenCode **V1** plugin API and do not load on OpenCode V2 (only load-failure warnings, nothing breaks). The Home Manager module options document this in detail.

## Home Manager modules

| Module                          | What it gives you                                                                                                                           |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `homeModules.blueferry`         | `programs.blueferry` — installs the package and a hardened, D-Bus-activated `blueferry` systemd user service                                |
| `homeModules.pipewire-soundpad` | `programs.pipewire-soundpad` — installs the package and a `pwsp-daemon` systemd user service                                                |
| `homeModules.opencode-plugins`  | `programs.opencode.nixPlugins.*` — declaratively installs OpenCode plugins into `~/.config/opencode/plugins` and writes their JSON settings |
| `homeModules.default`           | All of the above in one import                                                                                                              |

Example:

```nix
{
  inputs.angeldust-pkgs.url = "github:meflove/nix-packages";

  # in your Home Manager / NixOS config:
  #
  #   imports = [ angeldust-pkgs.homeModules.default ];
  #
  #   programs.blueferry = {
  #     enable = true;
  #     package = pkgs.angeldust-pkgs.blueferry-gtk; # or .blueferry / .blueferry-qt / .blueferry-quickshell
  #   };
  #
  #   programs.pipewire-soundpad.enable = true;
  #
  #   programs.opencode.nixPlugins.opencode-mem = {
  #     enable = true;
  #     settings.webServerEnabled = true;
  #   };
}
```

### Overlay

`overlays.default` adds the whole package set as `pkgs.angeldust-pkgs`:

```nix
{
  nixpkgs.overlays = [ angeldust-pkgs.overlays.default ];
  # then: environment.systemPackages = [ pkgs.angeldust-pkgs.yot ];
}
```

## Binary cache

All packages are built and pushed daily to [meflove.cachix.org](https://meflove.cachix.org) by CI. To use it, add the cache URL (and its public key from the page above) to your substituters:

```nix
{
  nix.settings.substituters = [ "https://meflove.cachix.org" ];
  nix.settings.trusted-public-keys = [ "meflove.cachix.org-1:<public-key>" ];
}
```

## Updating

`nix run .#updater` (the flake's default package) is a bulk updater that:

1. bumps every package version with [nix-update](https://github.com/Mic92/nix-update) (`--version=branch`);
2. regenerates `bun.nix` lockfiles with [bun2nix](https://github.com/nix-community/bun2nix) for Bun-based packages;
3. refreshes `npmDepsHash` with `prefetch-npm-deps` for npm-based packages.

It skips packages that are backed by flake inputs (those move with `nix flake update <input>`), local (`version = "local"`) or explicitly excluded ones, and prints a summary at the end. A daily [GitHub Actions workflow](.github/workflows/update-repo.yaml) runs `nix flake update`, `devenv update` and this updater, committing as _“Flake.lock and devenv.lock update”_.

## Development

The repo is set up with [devenv](https://devenv.sh) ([direnv](https://direnv.sh) hooks included):

```console
$ devenv shell        # or just allow .envrc
$ nix fmt             # treefmt: alejandra, deadnix, statix + prettier for *.md
```

Pre-commit hooks (via [prek](https://github.com/j178/prek)): shellcheck, end-of-file-fixer, trim-trailing-whitespace, detect-private-keys, alejandra, deadnix, statix.

### Layout

```
flake.nix        # flake-parts config: pkgs-by-name, treefmt, overlay, homeModules wiring
updater.nix      # the bulk update script (packages.updater)
packages/        # one directory per package; nested dirs become dotted attributes
modules/         # Home Manager modules, auto-imported via import-tree
```

## License

[GPL-3.0](./LICENSE)
