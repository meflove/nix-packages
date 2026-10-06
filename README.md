> [!NOTE]
> **Moved to [tangled](https://tangled.org/did:plc:jv6arfakxixeyppnbxhf6blz)** — [GitHub](https://github.com/meflove/nix-packages) and [Codeberg](https://codeberg.org/angeldust/nix-packages) now serve as a mirrors.

# angeldust nix-packages

A personal [Nix flake](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-flake.html) of packages, Home Manager modules and NixOS modules, built on [flake-parts](https://flake.parts) and [pkgs-by-name](https://github.com/drupol/pkgs-by-name-for-flake-parts), tracking `nixos-unstable`.

- **Systems:** `x86_64-linux`
- **Outputs:** `legacyPackages` (the package set), `overlays.default` (exposes it as `pkgs.angeldust-pkgs`), `homeModules`, `nixosModules`
- **Home:** [Tangled](https://tangled.org/did:plc:jv6arfakxixeyppnbxhf6blz) **Mirrors:** [GitHub](https://github.com/meflove/nix-packages) · [Codeberg](https://codeberg.org/angeldust/nix-packages)

## Packages

Run anything directly, e.g.

```bash
nix run git+https://tangled.org/did:plc:jv6arfakxixeyppnbxhf6blz#purple
```

or list them all:

```bash
$ nix eval git+https://tangled.org/did:plc:jv6arfakxixeyppnbxhf6blz#packages.x86_64-linux --apply 'ps: builtins.attrNames ps'
```

| Attribute                                          | Description                                                                                                    |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `ani-cli-ru.api`                                   | `anicli_api` — parse anime from RU websites                                                                    |
| `ani-cli-ru.client`                                | `anicli_ru` — watch anime from RU sources via mpv                                                              |
| `ani-cli-ru.uvicorn`                               | Pinned `uvicorn` ASGI server for the above                                                                     |
| `blueferry`                                        | iPhone messages, notifications and contacts on Linux over Bluetooth (backend: CLI, TUI and D-Bus daemon)       |
| `blueferry-gtk`                                    | BlueFerry GTK client (bundles the backend)                                                                     |
| `blueferry-qt`                                     | BlueFerry Qt client (bundles the backend)                                                                      |
| `blueferry-quickshell`                             | BlueFerry Quickshell (Wayland shell) client                                                                    |
| `clipse`                                           | Clipboard manager TUI for Unix                                                                                 |
| `icloud-keychain.icp`                              | `icp` — unofficial iCloud Keychain client: CLI, `icp-host` native-messaging launcher and the browser extension |
| `icloud-keychain.extension`                        | The Apple Passwords browser extension as an unsigned `.xpi` for Firefox-family profiles                        |
| `opencodePlugins.oh-my-opencode-slim`              | Multi-agent orchestration plugin for OpenCode                                                                  |
| `opencodePlugins.opencode-mem`                     | Persistent memory for coding agents via local Turso/libSQL vector search¹                                      |
| `opencodePlugins.opencode-notify`                  | Native OS notifications for OpenCode¹                                                                          |
| `opencodePlugins.opencode-dynamic-context-pruning` | Prunes obsolete tool outputs from conversation context¹                                                        |
| `pipewire-soundpad`                                | Soundpad for Linux working via PipeWire                                                                        |
| `proton-linuwux`                                   | [Proton-GE "LinUwUx" rework](https://codeberg.org/xshaduwulfx/proton-linuwux) build for Steam                  |
| `purple`                                           | Open-source terminal SSH manager and SSH config editor                                                         |
| `soundcloud-desktop`                               | SoundCloud desktop app                                                                                         |
| `yazi-plugins.cba-preview`                         | Yazi plugin to preview Comic Book Archive                                                                      |
| `yazi-plugins.convert`                             | Yazi plugin to convert images                                                                                  |
| `yazi-plugins.djvu-preview`                        | Yazi plugin for DjVu preview                                                                                   |
| `yazi-plugins.office`                              | Yazi documents previewer using LibreOffice                                                                     |
| `yazi-plugins.piper`                               | Pipe any shell command as a cached previewer for Yazi                                                          |
| `yazi-plugins.torrent-preview`                     | Yazi plugin to preview BitTorrent files                                                                        |
| `yazi-plugins.wl-clipboard`                        | Simple system clipboard for Yazi on Wayland                                                                    |
| `yot`                                              | Watch YouTube videos with AI translation in mpv                                                                |
| `updater`                                          | The bulk package-updater script (also the default package — see [Updating](#updating))                         |

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
  inputs.angeldust-pkgs.url = "git+https://tangled.org/did:plc:jv6arfakxixeyppnbxhf6blz";

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

## NixOS modules

| Module                         | What it gives you                                                                                                                                                                              |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `nixosModules.icloud-keychain` | `services.icloud-keychain` — the `icp` CLI, the anisette-v3-server container (oci-containers/docker) that Apple sign-in needs, and native-messaging wiring for enabled Firefox-family browsers |
| `nixosModules.default`         | All of the above in one import                                                                                                                                                                 |

Example:

```nix
{
  inputs.angeldust-pkgs.url = "git+https://tangled.org/did:plc:jv6arfakxixeyppnbxhf6blz";

  # in your NixOS config:
  #
  #   imports = [ angeldust-pkgs.nixosModules.icloud-keychain ];
  #
  #   services.icloud-keychain.enable = true;
}
```

What `enable = true` does:

- runs `anisette-v3-server` via `virtualisation.oci-containers` (docker backend by default — a `mkDefault`, switch the global backend to podman freely), bound to `127.0.0.1:6969`, with the device data persisted in the named volume `anisette-v3_data` (upstream's recommendation; override with `anisette.dataDir` or tweak `anisette.image`/`port`/`pull`/`extraOptions`);
- installs the `icp` CLI and points it at the server via `ICP_ANISETTE_URL`;
- for every **enabled** browser, adds `icloud-keychain.icp` to its native messaging hosts (`lib/mozilla/native-messaging-hosts` manifests are linked by the browser wrapper): NixOS `programs.firefox`, and — when Home Manager is used as a NixOS module — `programs.firefox` and zen-browser (`programs.zen-browser`) per user. Browsers that are not enabled (or whose module isn't imported) are skipped.

The extension itself is installed per profile (it's unsigned, so Firefox-family browsers need signature checking off — e.g. in a [zen-browser-flake](https://github.com/0xc000022070/zen-browser-flake) profile):

```nix
programs.zen-browser.profiles.default = {
  extensions = [ pkgs.angeldust-pkgs.icloud-keychain.extension ];
  settings."xpinstall.signatures.required" = false;
};
```

Chromium-family browsers: load the unpacked extension from `<icp package>/share/icloud-keychain/extension`, then write the host manifest yourself — copy `lib/mozilla/native-messaging-hosts/org.icp.native.json` from the package into `~/.config/<browser>/NativeMessagingHosts/` replacing `allowed_extensions` with `allowed_origins = ["chrome-extension://<EXTENSION_ID>/"]`.

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
  nix.settings.trusted-public-keys = [ "meflove.cachix.org-1:daXeLaZBNNJOngNUDEoylRfvtai2uSFOqdg29fN+7N8=" ];
}
```

## Updating

`nix run .#updater` (the flake's default package) is a bulk updater that:

1. bumps every package version with [nix-update](https://github.com/Mic92/nix-update) (`--version=branch`);
2. regenerates `bun.nix` lockfiles with [bun2nix](https://github.com/nix-community/bun2nix) for Bun-based packages;
3. refreshes `npmDepsHash` with `prefetch-npm-deps` for npm-based packages.

It skips packages that are backed by flake inputs (those move with `nix flake update <input>`), local (`version = "local"`) or explicitly excluded ones, and prints a summary at the end. A daily [tangled pipelines](./.tangled/workflows/update.yml) runs `nix flake update`, `devenv update` and this updater.

## Development

The repo is set up with [devenv](https://devenv.sh):

```console
$ devenv shell        # or just devenv allow
$ nix fmt             # treefmt: alejandra, deadnix, statix + prettier for *.md
```

Pre-commit hooks (via [prek](https://github.com/j178/prek)): shellcheck, end-of-file-fixer, trim-trailing-whitespace, detect-private-keys, alejandra, deadnix, statix.

### Layout

```
flake.nix        # flake-parts config: pkgs-by-name, treefmt, overlay, homeModules/nixosModules wiring
updater.nix      # the bulk update script (packages.updater)
packages/        # one directory per package; nested dirs become dotted attributes
modules/         # Home Manager and NixOS modules, auto-imported via import-tree
```

## License

[GPL-3.0](./LICENSE)
