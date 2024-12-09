{
	inputs = {
		agenix.url = github:ryantm/agenix;
		ags.url = github:Aylur/ags;
		axolotlClientApi.url = github:AxolotlClient/AxolotlClient-API;
		nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
		nur.url = github:nix-community/NUR;
	};

	outputs = inputs@{ self, agenix, ags, axolotlClientApi, nixpkgs, nur }: {
		nixosConfigurations.helium = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				nur.nixosModules.nur
				machines/all.nix
				machines/graphical.nix
				machines/helium.nix
				agenix.nixosModules.default
			];
			specialArgs = { inherit inputs; };
		};

		nixosConfigurations.lithium = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				nur.nixosModules.nur
				machines/all.nix
				machines/graphical.nix
				machines/lithium.nix
				agenix.nixosModules.default
			];
			specialArgs = { inherit inputs; };
		};

		nixosConfigurations.beryllium = nixpkgs.lib.nixosSystem {
			system = "aarch64-linux";
			modules = [
				machines/all.nix
				machines/beryllium
				agenix.nixosModules.default
			];
			specialArgs = { inherit inputs; };
		};
	};
}
