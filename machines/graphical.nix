{ config, lib, modulesPath, pkgs, ... }: {
	nixpkgs.overlays = [
		(self: super: { git-of-theseus = super.callPackage ../packages/git-of-theseus.nix {}; })
	];

	hardware = {
		graphics.extraPackages = [ pkgs.libGL ];

		bluetooth = {
			enable = true;
			powerOnBoot = true;
		};

		gpgSmartcards.enable = true;
	};

	boot = {
		kernelPackages = pkgs.linuxPackages_zen;
		kernelParams = [ "libahci.ignore_sss=1" ];
	};

	services = {
		pipewire = {
			enable = true;
			alsa.enable = true;
			alsa.support32Bit = true;
			pulse.enable = true;
		};

		displayManager.sddm = {
			enable = true;
			autoNumlock = true;
			wayland.enable = true;
		};

		speechd.enable = lib.mkForce false; # Not blind, so don't need it lol

		blueman.enable = true;
		envfs.enable = true;
		flatpak.enable = true;
		gnome.gnome-keyring.enable = true;
		pcscd.enable = true;
	};

	virtualisation.docker.enable = true;

	networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
	security.rtkit.enable = true;

	programs = { 
		steam.enable = true;
		gnupg.agent.enable = true;
		hyprland.enable = true;
		wireshark.enable = true;
		java = {
			enable = true;
			package = pkgs.temurin-bin;
		};
	};

	xdg.portal = {
		enable = true;
		extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
		config.common.default = "gtk";
	};

	fonts = {
		packages = with pkgs; [ corefonts jetbrains-mono vistafonts ];
		fontconfig.defaultFonts.monospace = [ "Jetbrains Mono" ];
	};

	users.users.emily = {
		extraGroups = [ "wireshark" ];

		packages = with pkgs; with nur.repos; [
			activitywatch ags aseprite aw-watcher-window-wayland blockbench devenv direnv dunst fastfetch
			fd gamemode gamescope gimp git-of-theseus heroic hyprshot inkscape jetbrains.idea-community
			kitty libreoffice librewolf mangohud nautilus ncdu nltch.spotify-adblock obs-studio obsidian
			onefetch oxipng pavucontrol playerctl prismlauncher qoi rclone renderdoc rsync smartmontools
			swaylock unzip vesktop vlc vmtouch wget wine wine64 wireshark winetricks wofi
			xorg.xcursorthemes yubikey-manager zip

			(vscode-with-extensions.override {
				vscode = vscodium;
				vscodeExtensions = with vscode-extensions; [
					jnoortheen.nix-ide
					matthewpi.caddyfile-support
					mkhl.direnv
					ms-vscode.hexeditor
					rust-lang.rust-analyzer
					serayuzgur.crates
					streetsidesoftware.code-spell-checker
					tamasfe.even-better-toml
				] ++ vscode-utils.extensionsFromVscodeMarketplace [
					{
						name = "aw-watcher-vscode";
						publisher = "activitywatch";
						version = "0.5.0";
						sha256 = "sha256-OrdIhgNXpEbLXYVJAx/jpt2c6Qa5jf8FNxqrbu5FfFs=";
					}
					{
						name = "HOCON";
						publisher = "sabieber";
						version = "0.0.1";
						sha256 = "sha256-m63dWOJF2syRpfImyVXek6XLGb/DdJtYZ4p03eeR/lU=";
					}
					{
						name = "wgsl";
						publisher = "PolyMeilex";
						version = "0.1.17";
						sha256 = "sha256-vGqvVrr3wNG6HOJxOnJEohdrzlBYspysTLQvWuP0QIw=";
					}
				];
			})
		];
	};

	environment.variables = with pkgs; {
		JDK17 = "${openjdk17-bootstrap}";
		JDK21 = "${temurin-bin}";
	};
}
