{
  description = "A nix flake for the RTL2VHDL plugin for Yosys";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    yosys.url = "git+https://github.com/YosysHQ/yosys?submodules=1"; # Yosys as a flake input
  };

  outputs = { self, nixpkgs, flake-utils, yosys }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        yosysPkg = yosys.packages.${system}.default;  # Import Yosys package from the flake
        rtl2vhdl = pkgs.clangStdenv.mkDerivation {
          name = "rtl2vhdl";
          src = ./.;
          buildInputs = with pkgs; [ yosysPkg clang llvmPackages.libcxxClang bison flex libffi readline python3 git zlib ];
          propagatedBuildInputs = [ yosysPkg ];
          preConfigure = ''
            export YOSYS_ROOT=${yosysPkg}
          '';
          buildPhase = ''
            make -j$(nproc) YOSYS_ROOT=$YOSYS_ROOT
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp rtl2vhdl.so $out/bin/
          '';
          meta = with pkgs.lib; {
            description = "RTLIL to VHDL backend plugin for Yosys";
            homepage = "https://github.com/yourname/rtl2vhdl";
            license = licenses.isc;
            maintainers = with maintainers; [ ];
          };
        };
      in {
        packages.default = rtl2vhdl;
        defaultPackage = rtl2vhdl;
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ yosysPkg clang llvmPackages.bintools bison flex libffi readline python3 git zlib ];
        };
      }
    );
}
