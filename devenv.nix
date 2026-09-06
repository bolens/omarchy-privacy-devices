{ pkgs, config, lib, inputs, ... }:
let
  developmentHome = pkgs.runCommand "development-home" { } ''
    mkdir -p "$out/env" "$out/usr/bin"
    # Runtime helpers deliberately use this trusted interpreter path.
    ln -s ${pkgs.python3}/bin/python3 "$out/usr/bin/python3"
  '';
in
{
  name = "omarchy-privacy-devices";
  # Use existing Nix caches without changing daemon trust configuration.
  cachix.enable = false;
  # This repository has no background services or process-compose configuration.
  process.manager.implementation = "overmind";
  packages = with pkgs; [
    bashInteractive coreutils findutils gawk git gnugrep gnumake gnused
    diffutils nodejs_24 python3 shellcheck ruby jq ripgrep cacert curl gnutar gzip
  ];
  env.SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  env.PRIVACY_RUNTIME_TESTS = "never";
  env.OMARCHY_PLUGIN_VALIDATE = "${inputs.omarchy}/bin/omarchy-plugin-validate";
  scripts.repo-check.exec = "npm ci --ignore-scripts --no-audit && npm test";
  enterTest = "repo-check";

  containers.shell = {
    name = "localhost/omarchy-privacy-devices-dev";
    version = "latest";
    # Mount source when running; never bake checkout files or local secrets in.
    copyToRoot = [ ];
    # Prepare the image's existing home; nothing is mounted here from the host.
    layers = lib.mkAfter [{
      copyToRoot = [ developmentHome ];
      perms = [{ path = developmentHome; regex = "/env"; mode = "1777"; }];
    }];
    entrypoint = [ (pkgs.writeShellScript "development-entrypoint" ''
      export PATH="${lib.makeBinPath config.packages}:$PATH"
      exec "$@"
    '') ];
    startupCommand = "bash";
  };
}
