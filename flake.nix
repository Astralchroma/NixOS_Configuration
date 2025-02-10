{
	inputs = {
		agenix.url = github:ryantm/agenix;
		ags.url = github:Aylur/ags;
		axolotlClientApi.url = github:AxolotlClient/AxolotlClient-API;
		impermanence.url = "github:nix-community/impermanence";
		nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
		nur.url = github:nix-community/NUR;
	};

	outputs = inputs@{ self, agenix, ags, axolotlClientApi, impermanence, nixpkgs, nur }: {
		nixosConfigurations.helium = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				nur.modules.nixos.default
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
				nur.modules.nixos.default
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
				impermanence.nixosModules.impermanence
				axolotlClientApi.nixosModules.default
				machines/all.nix
				machines/beryllium
				agenix.nixosModules.default
			];
			specialArgs = { inherit inputs; };
		};
	};
}
