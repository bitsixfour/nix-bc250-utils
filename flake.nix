{
  description = "bc-250 governor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-stable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils }:
    let
      perSystem = flake-utils.lib.eachDefaultSystem (system:
        let
          overlays = [ (import rust-overlay) ];
          pkgs = import nixpkgs { inherit system overlays; };
          rustToolchain = pkgs.rust-bin.stable.latest.default;
        in {
          packages.default = pkgs.rustPlatform.buildRustPackage {
            pname = "cyan-skillfish-governor";
            version = "0.3.0";
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;
            buildInputs = [ pkgs.libdrm ];
            nativeBuildInputs = [ rustToolchain ];
            meta = {
              description = "GPU governor for the AMD Cyan Skillfish APU";
              license = pkgs.lib.licenses.mit;
              platforms = [ "x86_64-linux" ];
            };
          };

          devShells.default = pkgs.mkShell {
            packages = [ rustToolchain pkgs.libdrm ];
          };
        }
      );

      nixosModule = { pkgs, ... }: { # edid from git repository to
        hardware.firmware = [
          (pkgs.runCommand "bc250-edid" {} ''
            mkdir -p $out/lib/firmware/edid
            cp ${./edid/1920x1080.bin} $out/lib/firmware/edid/bc250-1080p.bin
          '')
        ];

        boot.kernelParams = [
          "drm.edid_firmware=HDMI-A-1:edid/bc250-1080p.bin"
          "video=HDMI-A-1:1920x1080@60"
        ];
      };

    in
      perSystem // {
        nixosModules.default = nixosModule;
      };
}
