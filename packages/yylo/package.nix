{
  buildNpmPackage,
  fetchurl,
  lib,
  mkUpdater,
  runCommand,
  versionCheckHook,
  versionCheckHomeHook,
  flake,
}:

let
  versionData = lib.importJSON ./hashes.json;
  version = versionData.version;
  # The npm tarball ships no lockfile; add the vendored one for buildNpmPackage.
  srcWithLock = runCommand "yylo-src-with-lock" { } ''
    mkdir -p $out
    tar -xzf ${
      fetchurl {
        url = "https://registry.npmjs.org/@yylo/cli/-/cli-${version}.tgz";
        hash = versionData.sourceHash;
      }
    } -C $out --strip-components=1
    cp ${./package-lock.json} $out/package-lock.json
  '';
in
buildNpmPackage {
  npmDepsFetcherVersion = 2;
  pname = "yylo";
  inherit version;

  src = srcWithLock;

  npmDepsHash = versionData.npmDepsHash;

  npmInstallFlags = [ "--ignore-scripts" ];
  npmRebuildFlags = [ "--ignore-scripts" ];

  # The package from npm is already built (dist/ ships in the tarball).
  dontNpmBuild = true;

  # Use environment variables to forcefully disable all scripts; the published
  # package.json carries repo-only lifecycle scripts (prepack rebuilds from
  # src/, which the tarball does not include).
  NPM_CONFIG_IGNORE_SCRIPTS = "true";

  # patchShebangs rewrites the bash shebang of the shipped yylo.sh/ypl.sh
  # wrapper bins, so the default npm bin links work unmodified.

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    versionCheckHook
    versionCheckHomeHook
  ];

  passthru.category = "AI Coding Agents";
  passthru.updater = mkUpdater {
    kind = "npm";
    purl = "pkg:npm/%40yylo/cli";
  };

  meta = with lib; {
    description = "Task-driven AI subagent orchestration for coding agents";
    homepage = "https://github.com/yylo-dev/yylo";
    changelog = "https://github.com/yylo-dev/yylo/releases";
    downloadPage = "https://www.npmjs.com/package/@yylo/cli";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
    maintainers = with flake.lib.maintainers; [ InsightFactoryAPP ];
    mainProgram = "yylo";
    platforms = platforms.all;
  };
}
