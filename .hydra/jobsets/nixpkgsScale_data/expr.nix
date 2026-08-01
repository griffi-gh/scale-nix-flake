# adapted from the nixpkgs-cuda jobset:
# https://raw.githubusercontent.com/nixos-cuda/hydra-jobsets/refs/heads/master/jobsets/cuda-packages.nix
#
# (disclosure: some later changes i made to this have been assisted by ai, and very lazily so
# imo it's fine for a one off script whose entire purpose is to generate the static data.json)
#
let
  supportedSystems = [ "x86_64-linux" ];
  currentSystem = builtins.currentSystem or "x86_64-linux";
  nixpkgs = <nixpkgs>;

  ##########################################################
  # STEP 1: Initialize release-lib
  ##########################################################

  lib = import "${nixpkgs}/lib";
  mkReleaseLib = import "${nixpkgs}/pkgs/top-level/release-lib.nix";

  nixpkgsConfig = {
    # TODO: why not simply "allowUnfree = true"?
    # allowUnfreePredicate =
    #   letq
    #     cudaLib = (import "${nixpkgs}/pkgs/development/cuda-modules/_cuda").lib;
    #   in
    #   cudaLib.allowUnfreeCudaPredicate;
    allowUnfree = true;
    cudaSupport = true;
    inHydra = true;

    # Don't evaluate duplicate and/or deprecated attributes
    allowAliases = false;
  };

  # Attributes passed to nixpkgs.
  nixpkgsArgs = {
    config = nixpkgsConfig;
    __allowFileset = false;
  };

  release-lib = mkReleaseLib (
    {
      inherit supportedSystems nixpkgsArgs;
      system = currentSystem;
    }
    // lib.intersectAttrs (lib.functionArgs mkReleaseLib) {
      inherit nixpkgs;
    }
  );

  ##########################################################
  # STEP 2: Compute the set of attrpaths in nixpkgs that are affected by switching cudaSupport from
  # `false` to `true`
  ##########################################################

  ci = import "${nixpkgs}/ci" {
    system = currentSystem;
    inherit nixpkgs;
  };

  # TODO: optimize the value of chunkSize for the hydra machine
  evalCudaSupportFalse = ci.eval {
    extraNixpkgsConfig = nixpkgsConfig // {
      cudaSupport = false;
    };
  };
  evalCudaSupportTrue = ci.eval { extraNixpkgsConfig = nixpkgsConfig; };

  # These produce a symlink tree like this:
  # - x86_64-linux
  #   - paths.json
  #   - <other uninteresting stuff>
  # - aarch64-linux
  #   - paths.json
  #   - ...
  #
  # Where paths.json looks like this:
  #
  # {
  #   "AMB-plugins.x86_64-linux": {
  #     "out": "/nix/store/1kfkni7mvz0ak3pkgq38axy6qwfp2kdz-AMB-plugins-0.8.1"
  #   },
  #   "ArchiSteamFarm.x86_64-linux": {
  #     "out": "/nix/store/8lj39bhsxs6hl5whdv6qz280xz71v9i2-ArchiSteamFarm-6.3.1.4"
  #   },
  #   "CuboCore.coreaction.x86_64-linux": {
  #     "out": "/nix/store/zw4wdd4s0qaw24hysqvj1zr150pfr2y9-coreaction-5.0.0"
  #   },
  #   "CuboCore.corearchiver.x86_64-linux": {
  #     "out": "/nix/store/nlr70m9iympiaqzwy07wbpcyh2hkzdc0-corearchiver-5.0.0"
  #   },
  #   ...
  # }

  baselineCudaSupportFalse = evalCudaSupportFalse.baseline { evalSystems = supportedSystems; };
  baselineCudaSupportTrue = evalCudaSupportTrue.baseline { evalSystems = supportedSystems; };

  # Taken from ci/eval/diff.nix
  getAttrs =
    dir: evalSystem:
    let
      raw = builtins.readFile "${dir}/${evalSystem}/paths.json";
      # The file contains Nix paths; we need to ignore them for evaluation purposes,
      # else there will be a "is not allowed to refer to a store path" error.
      data = builtins.unsafeDiscardStringContext raw;
    in
    builtins.fromJSON data;

  # Collect all paths that changed between these into a form of a list:
  # [
  #   {system = "x86_64-linux"; path = ["csxcad"];}
  #   {system = "x86_64-linux"; path = ["ctranslate2"];}
  #   {system = "x86_64-linux"; path = ["cudaPackages" "libcublasmp"];}
  #   {system = "x86_64-linux"; path = ["cudaPackages" "libcudss"];}
  #   {system = "x86_64-linux"; path = ["cudaPackages" "libnvshmem"];}
  #   {system = "x86_64-linux"; path = ["cudaPackages" "nsight_systems"];}
  #   {system = "x86_64-linux"; path = ["cura-appimage"];}
  #   ...
  # ]

  diffEntries = lib.concatLists (
    lib.forEach supportedSystems (
      system:
      let
        before = getAttrs baselineCudaSupportFalse system;
        after = getAttrs baselineCudaSupportTrue system;
        isAddedOrChanged = name: !(before ? ${name}) || (after.${name} != before.${name});
        addedOrChanged = lib.filter isAddedOrChanged (lib.attrNames after);
      in
      # Cut out "release-checks"
      lib.filter (e: e.path != [ ]) (
        map (pathStr: {
          inherit system;
          path = lib.init (lib.splitString "." pathStr);
        }) addedOrChanged
      )
    )
  );

  ##########################################################
  # STEP 2.5: Also catch packages with a *direct* dependency on cudaPackages

  # `null` scans all of nixpkgs. Set to e.g. [ "python3Packages" "libsForQt5" ]
  # to only scan those subtrees.
  scanRoots = null;

  # Attributes we treat as "direct" dependencies. Covers the usual host/build/
  # target split plus their propagated variants and check inputs.
  depAttrs = [
    "buildInputs"
    "nativeBuildInputs"
    "propagatedBuildInputs"
    "propagatedNativeBuildInputs"
    "checkInputs"
    "nativeCheckInputs"
    "depsBuildBuild"
    "depsBuildBuildPropagated"
    "depsBuildTarget"
    "depsBuildTargetPropagated"
    "depsHostHostPropagated"
    "depsTargetTarget"
    "depsTargetTargetPropagated"
  ];

  # tryEval wrapper returning `default` on any evaluation failure.
  tryOr = default: e: let r = builtins.tryEval e; in if r.success then r.value else default;

  # Instantiate nixpkgs (cudaSupport = true) for a given system.
  pkgsFor = system: import nixpkgs (nixpkgsArgs // { inherit system; });

  # Every drvPath reachable in cudaPackages (context-stripped so it can be used
  # as an attr key / compared cheaply).
  collectDrvPaths =
    value:
    tryOr [ ] (
      if lib.isDerivation value then
        # Force the drvPath *inside* tryEval. Some cudaPackages members (e.g.
        # aarch64-only cuda_compat) throw on `.drvPath`; a lazily-held thunk
        # would escape this guard and blow up later in genAttrs/groupBy.
        let p = builtins.unsafeDiscardStringContext value.drvPath; in builtins.seq p [ p ]
      else if lib.isAttrs value && (value.recurseForDerivations or false) then
        lib.concatMap collectDrvPaths (lib.attrValues value)
      else
        [ ]
    );

  # Direct dependency drvPaths of a single derivation.
  directDepDrvPaths =
    drv:
    let
      raw = lib.concatMap (attr: tryOr [ ] (drv.${attr} or [ ])) depAttrs;
      # Guard isDerivation too: an input on a bad platform throws when forced.
      drvs = lib.filter (x: tryOr false (lib.isDerivation x)) (lib.flatten raw);
    in
    lib.concatMap (
      d: tryOr [ ] (let p = builtins.unsafeDiscardStringContext d.drvPath; in builtins.seq p [ p ])
    ) drvs;

  # Walk an attrset, yielding `{ path = [...]; drv = <drv>; }` for every
  # derivation. Stops at derivations (does not descend into their passthru).
  enumerateSet =
    prefix: attrs:
    lib.concatLists (
      lib.mapAttrsToList (
        name: value:
        let
          path = prefix ++ [ name ];
        in
        tryOr [ ] (
          if lib.isDerivation value then
            [ { inherit path; drv = value; } ]
          else if lib.isAttrs value && (value.recurseForDerivations or false) then
            enumerateSet path value
          else
            [ ]
        )
      ) attrs
    );

  # Restrict the scan universe according to `scanRoots`.
  rootsFor =
    pkgs:
    if scanRoots == null then
      pkgs
    else
      lib.genAttrs (lib.filter (n: pkgs ? ${n}) scanRoots) (n: pkgs.${n});

  cudaDirectDepEntries = lib.concatLists (
    lib.forEach supportedSystems (
      system:
      let
        pkgs = pkgsFor system;
        cudaDrvPaths = collectDrvPaths (pkgs.cudaPackages or { });
        # attrset for O(1) membership tests
        cudaSet = lib.genAttrs cudaDrvPaths (_: true);
        hasCudaDep = { drv, ... }: lib.any (p: cudaSet ? ${p}) (directDepDrvPaths drv);
        allPkgs = enumerateSet [ ] (rootsFor pkgs);
      in
      map (e: { inherit system; inherit (e) path; }) (lib.filter hasCudaDep allPkgs)
    )
  );

  # Union of "affected by cudaSupport" and "directly depends on cudaPackages".
  entries = diffEntries ++ cudaDirectDepEntries;

  ##########################################################
  # STEP 3: Build the jobset that will be consumed by Hydra
  ##########################################################

  # First, we need to map it to:
  #
  # allPackagePlatforms = {
  #   python3Packages.torch = [ "x86_64-linux" "aarch64-linux" ];
  #   python3Packages.foo = [ "x86_64-linux" ];
  #   python3Packages.bar = [ "aarch64-linux" ];
  #   cool = [ "x86_64-linux" "aarch64-linux" ];
  # }
  #
  # thanks to some nix magic by @MattSturgeon (thanks!)

  groupEntries =
    entries:
    lib.pipe entries [
      (lib.groupBy (entry: lib.head entry.path))
      (lib.mapAttrs (_: map (entry: entry // { path = lib.tail entry.path; })))
    ];

  entriesToAttrSet =
    entries:
    lib.mapAttrs (
      _: entries:
      let
        byLeaf = lib.partition (entry: entry.path == [ ]) entries;
      in
      if byLeaf.wrong == [ ] then
        # leaf node (dedup systems: a package may come from both the diff and the
        # direct-dep pass)
        lib.unique (lib.catAttrs "system" entries)
      else if byLeaf.right == [ ] then
        # recursive
        entriesToAttrSet entries
      else
        throw "Conflicting attr paths:${lib.concatMapStrings (entry: "\n- ${entry.path}") entries}"
    ) (groupEntries entries);

  allPackagePlatforms = entriesToAttrSet entries;

  # Explicitly specified platforms take precedence over the platforms
  # automatically inferred in autoPackagePlatforms
  # jobs = release-lib.mapTestOn allPackagePlatforms;
in
  allPackagePlatforms
