{
  description = "A very basic flake";

  outputs = { self, nixpkgs }: 
  let 
    system = "x86_64-linux"; 
    pkgs = import nixpkgs {inherit system;}; 
    slidev = pkgs.writeShellScriptBin "slidev" '' 
      npx slidev
    '';
  in {
    devShells.${system}.default = pkgs.mkShell { buildInputs = [ slidev pkgs.nodejs pkgs.yarn ]; };
  };
}
