{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    flake-parts.url = "github:hercules-ci/flake-parts";
    mango = {
        url = "github:DreamMaoMao/mango";
	inputs.nixpkgs.follows = "nixpkgs";
     };
     home-manager = {
       url = "github:nix-community/home-manager";
       inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = 
   inputs@{ self, nixpkgs, home-manager, mangowc, flake-parts, ... }:
   flake-parts.lib.mkFlake { inherit inputs; } {
    debug = true;
    systems = [ "x86_64-linux" ];
   flake = {
    nixosConfigurations = {
     nahian = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
      inputs.mango.nixosModules.mango
      {
        programs.mango.enable = true;
      }
         inputs.home-manager.nixosModules.home-manager
        {
	   home-manager = {
	      useGlobalPkgs = true;
	      useUserPackages = true;
	      users.nahian = import ./home.nix;
	      backupFileExtension = "backup";
	    };
           }
	];
     };
  };   
}
