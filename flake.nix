{
  description = "Online store — Java (Maven), MySQL (order-service), MongoDB (product-service)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      });

      mkStartLocalDatabases = pkgs: pkgs.writeShellApplication {
        name = "start-local-databases";
        runtimeInputs = [
          pkgs.mysql84
          pkgs.mongodb
          pkgs.mongosh
        ];
        text = builtins.readFile ./scripts/start-local-databases.sh;
      };
    in
    {
      packages = forEachSupportedSystem ({ pkgs }:
        let start-local-databases = mkStartLocalDatabases pkgs; in
        {
          inherit start-local-databases;
          default = start-local-databases;
        });

      apps = forEachSupportedSystem ({ pkgs }:
        let start-local-databases = mkStartLocalDatabases pkgs; in
        {
          default = {
            type = "app";
            program = "${start-local-databases}/bin/start-local-databases";
          };
        });

      devShells = forEachSupportedSystem ({ pkgs }:
        let start-local-databases = mkStartLocalDatabases pkgs; in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              jdk17
              maven
              mysql84
              mongodb
              mongosh
              start-local-databases
            ];

            shellHook = ''
              echo "Java toolchain: jdk17 + maven"
              echo "Databases (flake): mysql84 + mongodb (SSPL; allowUnfree enabled in this flake)"
              echo "  Run:  nix run .#   or  start-local-databases"
              echo "  Data defaults to TMPDIR/onlinestore-databases — not under the repo (avoids Nix + socket files)"
              echo "  MySQL: port MYSQL_PORT (default 3306), db \`order-service\`, user root / password mysql"
              echo "  If 3306 is busy:  MYSQL_PORT=3307 nix run .#"
              echo "  Mongo: port MONGO_PORT (default 27017), database product-service"
            '';
          };
        });
    };
}
