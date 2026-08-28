{
  self',
  inputs,
  pkgs,
  lib,
}: let
  excludePackages = [
    (baseNameOf ./.)
    "yot"
  ];

  isDerivation = pkg: builtins.isAttrs pkg && ((pkg ? type && pkg.type == "derivation") || (pkg ? drvPath));

  getDerivations = packages: let
    collectNames = prefix: attrs:
      lib.concatMap (
        name: let
          pkg = attrs.${name};
          fullName =
            if prefix == ""
            then name
            else "${prefix}.${name}";
          isDrv = builtins.tryEval (isDerivation pkg);
        in
          if !isDrv.success
          then []
          else if isDrv.value
          then [fullName]
          else if builtins.isAttrs pkg && !(pkg ? outPath)
          then collectNames fullName pkg
          else []
      ) (lib.attrNames attrs);
  in
    lib.sort lib.lessThan (collectNames "" packages);

  getPackageByPath = path: root: lib.foldl (acc: key: acc.${key}) root (lib.splitString "." path);

  isLocalPackage = _name: pkg: let
    version =
      pkg.version or (pkg.drvVersion or (
        if pkg ? src && pkg.src ? version
        then pkg.src.version
        else null
      ));
  in
    version == "local";

  isExcluded = name:
    (builtins.elem name excludePackages)
    || (builtins.any (ex: lib.hasPrefix (ex + ".") name) excludePackages);

  ourPackages = self'.legacyPackages or {};
  allDerivations = getDerivations ourPackages;

  # Packages whose evaluation fails are skipped instead of breaking the updater.
  packagesToUpdate =
    builtins.filter (
      name: let
        checked = builtins.tryEval (
          let
            pkg = getPackageByPath name ourPackages;
            notExcluded = !(isExcluded name);
            # Flake-input-backed packages cannot be bumped by nix-update;
            # bun-managed ones are refreshed by the bun.nix section, the rest
            # are updated with `nix flake update <input>`.
            notInputBacked = !(builtins.elem name flakeInputBackedNames);
            notLocal =
              if pkg ? version || pkg ? drvVersion
              then !(isLocalPackage name pkg)
              else true;
          in
            notExcluded && notInputBacked && notLocal
        );
      in
        checked.success && checked.value
    )
    allDerivations;

  localPackagesCount = builtins.length (
    builtins.filter (
      name: let
        checked = builtins.tryEval (
          let
            pkg = getPackageByPath name ourPackages;
            isLocal =
              if pkg ? version || pkg ? drvVersion
              then isLocalPackage name pkg
              else false;
          in
            !(isExcluded name) && isLocal
        );
      in
        checked.success && checked.value
    )
    allDerivations
  );

  includedNames = builtins.filter (name: !(isExcluded name)) allDerivations;
  excludedPackagesCount = builtins.length allDerivations - builtins.length includedNames;

  noVersionPackagesCount = builtins.length (
    builtins.filter (
      name: let
        pkg = getPackageByPath name ourPackages;
      in
        !(pkg ? version) && !(pkg ? drvVersion)
    )
    packagesToUpdate
  );

  bunNixFiles = dir: let
    entries = builtins.readDir "${toString ./.}/${dir}";
    matches = lib.filter (f: lib.match "(|.*-)bun\.nix" f != null) (lib.attrNames entries);
  in
    map (f: {
      out = f;
      lockRel =
        if lib.match ".*-bun\.nix" f != null
        then "${lib.head (lib.match "(.*)-bun\.nix" f)}/bun.lock"
        else "bun.lock";
    })
    matches;

  bunDepsPackages =
    builtins.filter (p: p.lock != null)
    (
      lib.concatMap (
        file: let
          dir = dirOf (lib.removePrefix "${toString ./.}/" (toString file));
          name = baseNameOf dir;
        in
          if !(inputs ? ${name})
          then []
          else
            map (entry: {
              inherit dir name;
              inherit (entry) out;
              lock =
                if builtins.pathExists "${inputs.${name}.outPath}/${entry.lockRel}"
                then "${inputs.${name}.outPath}/${entry.lockRel}"
                else null;
            })
            (bunNixFiles dir)
      )
      (lib.filter (lib.hasSuffix "package.nix") (lib.filesystem.listFilesRecursive ./packages))
    );

  flakeInputBackedNames =
    builtins.filter (
      name: let
        inputName = lib.last (lib.splitString "." name);
        srcCheck = builtins.tryEval (getPackageByPath name ourPackages).src.outPath;
      in
        inputs ? ${inputName}
        && srcCheck.success
        && srcCheck.value == inputs.${inputName}.outPath
    )
    includedNames;
  flakeInputBackedCount = builtins.length flakeInputBackedNames;

  quietBunUpdate = pkgs.writeShellScriptBin "quiet-bun-update" ''
    ${lib.getExe pkgs.bun2nix} "$@" > /dev/null 2>&1
    exit_code=$?
    exit $exit_code
  '';

  npmDepsPackages =
    builtins.filter (p: p.lock != null)
    (
      map
      (file: let
        dir = dirOf (lib.removePrefix "${toString ./.}/" (toString file));
        name = baseNameOf dir;
        inputLock =
          if inputs ? ${name} && builtins.pathExists "${inputs.${name}.outPath}/package-lock.json"
          then "${inputs.${name}.outPath}/package-lock.json"
          else null;
        localLock =
          if builtins.pathExists "${toString ./.}/${dir}/package-lock.json"
          then "${toString ./.}/${dir}/package-lock.json"
          else null;
      in {
        inherit dir name;
        lock =
          if inputLock != null
          then inputLock
          else localLock;
      })
      (lib.filter (lib.hasSuffix "package.nix") (lib.filesystem.listFilesRecursive ./packages))
    );

  quietNixUpdate = pkgs.writeShellScriptBin "quiet-nix-update" ''
    ${lib.getExe pkgs.nix-update} "$@" > /dev/null 2>&1
    exit_code=$?
    exit $exit_code
  '';
in
  pkgs.writeShellScriptBin "update-packages"
  # bash
  ''
    echo "Starting package updates..."
    echo ""

    COMMANDS=()
    PACKAGE_NAMES=()

    for name in ${toString packagesToUpdate}; do
      nix_update_cmd="${lib.getExe quietNixUpdate}"
      if [[ "$name" != "proton-cachyos-linuwux" ]]; then
        cmd="cd $PWD && $nix_update_cmd --flake legacyPackages.${pkgs.stdenv.system}.$name --version=branch"
      else
        cmd="cd $PWD && $nix_update_cmd --flake legacyPackages.${pkgs.stdenv.system}.$name --version-regex 'proton-cachyos-(.*)'"
      fi

      COMMANDS+=("$cmd")
      PACKAGE_NAMES+=("$name")
    done

    BUN_DIRS=()
    BUN_OUTS=()
    BUN_LOCKS=()
    BUN_NAMES=()
    ${lib.concatStringsSep "\n" (
      map (
        p: ''
          BUN_DIRS+=("${p.dir}")
          BUN_OUTS+=("${p.out}")
          BUN_LOCKS+=("${p.lock}")
          BUN_NAMES+=("${p.name}${lib.optionalString (p.out != "bun.nix") " (${p.out})"}")
        ''
      )
      bunDepsPackages
    )}

    NPM_DIRS=()
    NPM_LOCKS=()
    ${lib.concatStringsSep "\n" (
      map (
        p: ''
          NPM_DIRS+=("${p.dir}")
          NPM_LOCKS+=("${p.lock}")
        ''
      )
      npmDepsPackages
    )}

    total=''${#COMMANDS[@]}
    current=0
    success=0
    failed=0
    all_total=${toString (builtins.length allDerivations)}
    excluded_count=${toString excludedPackagesCount}
    flake_input_backed_count=${toString flakeInputBackedCount}
    local_count=${toString localPackagesCount}
    no_version_count=${toString noVersionPackagesCount}

    echo "=== Package Statistics ==="
    echo "Total packages: $all_total"
    echo "Excluded by list: $excluded_count"
    echo "Flake-input backed (skipped): $flake_input_backed_count"
    echo "Local packages (skipped): $local_count"
    echo "Packages without 'version' attr: $no_version_count"
    echo "Packages to update: $total"
    echo ""

    if [[ $total -eq 0 ]]; then
      echo "No packages to update!"
      exit 0
    fi

    for i in "''${!COMMANDS[@]}"; do
      cmd="''${COMMANDS[$i]}"
      name="''${PACKAGE_NAMES[$i]}"
      current=$((current + 1))

      echo -n "[$current/$total] Updating $name..."

      if eval "$cmd"; then
        echo " Success"
        success=$((success + 1))
      else
        echo " Failed"
        failed=$((failed + 1))
      fi
    done

    bun_total=''${#BUN_DIRS[@]}
    bun_success=0
    bun_failed=0

    if [[ $bun_total -gt 0 ]]; then
      echo ""
      echo "=== Updating bun.nix dependencies ==="
      echo ""

      for i in "''${!BUN_DIRS[@]}"; do
        dir="''${BUN_DIRS[$i]}"
        out="''${BUN_OUTS[$i]}"
        lock="''${BUN_LOCKS[$i]}"
        name="''${BUN_NAMES[$i]}"
        bun_current=$((i + 1))

        echo -n "[$bun_current/$bun_total] Updating $name..."

        if [[ ! -f "$lock" ]]; then
          echo " Failed (lockfile not found in source of '$name')"
          bun_failed=$((bun_failed + 1))
          continue
        fi

        if (cd "$dir" && ${lib.getExe quietBunUpdate} -l "$lock" -o "$out"); then
          if ${lib.getExe pkgs.nix} fmt -- "$dir/$out" >/dev/null 2>&1; then
            echo " Success"
          else
            echo " Success (unformatted)"
          fi
          bun_success=$((bun_success + 1))
        else
          echo " Failed (bun2nix)"
          bun_failed=$((bun_failed + 1))
        fi
      done
    fi

    npm_total=''${#NPM_DIRS[@]}
    npm_updated=0
    npm_unchanged=0
    npm_failed=0

    if [[ $npm_total -gt 0 ]]; then
      echo ""
      echo "=== Updating npmDepsHash ==="
      echo ""

      for i in "''${!NPM_DIRS[@]}"; do
        dir="''${NPM_DIRS[$i]}"
        lock="''${NPM_LOCKS[$i]}"
        name="$(basename "$dir")"
        npm_current=$((i + 1))

        echo -n "[$npm_current/$npm_total] Updating $name npmDepsHash..."

        if [[ ! -f "$lock" ]]; then
          echo " Failed (package-lock.json not found in source of '$name')"
          npm_failed=$((npm_failed + 1))
          continue
        fi

        if ! new_hash=$(${lib.getExe pkgs.prefetch-npm-deps} "$lock" 2>/dev/null) || [[ -z "$new_hash" ]]; then
          echo " Failed (prefetch-npm-deps)"
          npm_failed=$((npm_failed + 1))
          continue
        fi

        old_hash=$(sed -n 's/.*npmDepsHash = "\([^"]*\)".*/\1/p' "$dir/package.nix")

        if [[ "$new_hash" == "$old_hash" ]]; then
          echo " Up-to-date"
          npm_unchanged=$((npm_unchanged + 1))
        elif sed -i "s|npmDepsHash = \"[^\"]*\"|npmDepsHash = \"$new_hash\"|" "$dir/package.nix"; then
          echo " Success"
          npm_updated=$((npm_updated + 1))
        else
          echo " Failed (rewrite)"
          npm_failed=$((npm_failed + 1))
        fi
      done
    fi

    echo ""
    echo "=== Update Summary ==="
    echo "Successful: $success"
    echo "Failed: $failed"
    echo "Skipped (local): $local_count"
    echo "Flake-input backed (skipped here): $flake_input_backed_count"
    echo "Excluded: $excluded_count"
    echo "Bun deps updated: $bun_success"
    echo "Bun deps failed: $bun_failed"
    echo "npmDepsHash updated: $npm_updated"
    echo "npmDepsHash up-to-date: $npm_unchanged"
    echo "npmDepsHash failed: $npm_failed"
    echo "Total: $all_total"
  ''
