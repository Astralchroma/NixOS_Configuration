{ inputs, lib, pkgs, ... }: {
	nixpkgs.config.allowUnfree = true;

	nix = {
		settings = {
			allowed-users = [ "@wheel" ];
			auto-optimise-store = true;
			experimental-features = [ "flakes" "nix-command" ];
			trusted-users = [ "@wheel" ];
		};

		gc = {
			automatic = lib.mkDefault true;
			dates = "04:15";
			options = "--delete-older-than 28d";
		};
	};

	system.autoUpgrade = {
		enable = true;
		flake = inputs.self.outPath;
		flags = [ "--upgrade-all" "--verbose" "-L" ];
		dates = "04:15";
	};

	systemd.services.nix-gc.after = [ "nixos-upgrade.service" ];

	boot = {
		loader.systemd-boot = {
			enable = true;
			editor = false;
		};

		loader.efi.canTouchEfiVariables = true;

		initrd.systemd.enable = true;
	};

	services.openssh = {
		enable = true;
		settings = {
			KbdInteractiveAuthentication = false;
			PasswordAuthentication = false;
			PermitRootLogin = "no";
		};
	};

	services.tailscale.enable = true;

	documentation = {
		man.enable = false;
		nixos.enable = false; 
	};

	console.keyMap = "uk";
	environment.defaultPackages = lib.mkForce [ pkgs.rsync ];
	i18n.defaultLocale = "en_GB.UTF-8";
	time.timeZone = "Europe/London";

	users.users.emily = {
		isNormalUser = true;
		extraGroups = [ "wheel" ];
		
		openssh.authorizedKeys.keys = [
			"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICMFmGardIjKxRdrlDqUQtzSIBad+1PKbao4MWS/++AL"
		];

		packages = with pkgs; [ btop git ];
	};
}
