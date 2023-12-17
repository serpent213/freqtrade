# Run
# 
#   nix develop .#setupShell
# 
# to install packages via pip initially (and stay in shell), and run
# 
#   nix develop
# 
# to run development shell afterwards.

{
  description = "Freqtrade crypto trading bot";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";
    # or for unstable
    # nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      pythonPatched = (pkgs.python311.override {
        packageOverrides = pyfinal: pyprev: {
          # Fix Jupyter builds until https://nixpk.gs/pr-tracker.html?pr=267121 is merged
          urllib3 = pyprev.urllib3.overrideAttrs {
            patches = [
              (pkgs.fetchpatch {
                name = "revert-threadsafe-poolmanager.patch";
                url = "https://github.com/urllib3/urllib3/commit/710114d7810558fd7e224054a566b53bb8601494.patch";
                revert = true;
                hash = "sha256-2O0y0Tij1QF4Hx5r+WMxIHDpXTBHign61AXLzsScrGo=";
              })
            ];
          };
        };
      }).withPackages(pp: with pp; [
        pip
        virtualenv

        # for Jupyter analysis
        # tabulate
        # pandas
        # python-rapidjson
        # tqdm
        # quantstats
        # ipywidgets
        # joblib

        # plotly
        # bokeh

        # jupyter
      ]);
      buildInputs = with pkgs; [
        pythonPatched
        # python311Packages.pip
        # python311Packages.virtualenv
        # python311Packages.jupyter
        ta-lib
      ];
    in {
      devShells.default = pkgs.mkShell {
        inherit buildInputs;
        shellHook = ''
          export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib/
          source .venv/bin/activate
        '';
      };
      devShells.setupShell = pkgs.mkShell {
        inherit buildInputs;
        shellHook = ''
          export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib/
          rm -rf .venv
          virtualenv --no-setuptools .venv
          source .venv/bin/activate
          pip install -r requirements-dev.txt
          pip install -e .
        '';
      };
    });
}
