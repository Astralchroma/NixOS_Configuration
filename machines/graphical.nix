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

	networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
	security.rtkit.enable = true;

	programs = { 
		steam.enable = true;
		gnupg.agent.enable = true;
		hyprland.enable = true;
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
		packages = with pkgs; with nur.repos; [
			activitywatch ags aseprite aw-watcher-window-wayland blockbench devenv direnv dunst
			fastfetch fd gamemode gamescope gimp git-of-theseus heroic hyprshot inkscape kitty
			libreoffice librewolf mangohud nautilus ncdu nltch.spotify-adblock obs-studio obsidian
			onefetch oxipng pavucontrol playerctl prismlauncher qoi rclone renderdoc rsync
			smartmontools swaylock unzip vesktop vlc vmtouch wget wine wine64 winetricks wofi
			xorg.xcursorthemes yubikey-manager zip

			(vscode-with-extensions.override {
				vscode = vscodium;
				vscodeExtensions = with vscode-extensions; [
					jnoortheen.nix-ide
					matthewpi.caddyfile-support
					mkhl.direnv
					rust-lang.rust-analyzer
					streetsidesoftware.code-spell-checker
					tamasfe.even-better-toml
					vadimcn.vscode-lldb
				] ++ vscode-utils.extensionsFromVscodeMarketplace [
					{
						name = "wgsl";
						publisher = "PolyMeilex";
						version = "0.1.17";
						sha256 = "sha256-vGqvVrr3wNG6HOJxOnJEohdrzlBYspysTLQvWuP0QIw=";
					}
					{
						name = "aw-watcher-vscode";
						publisher = "activitywatch";
						version = "0.5.0";
						sha256 = "sha256-OrdIhgNXpEbLXYVJAx/jpt2c6Qa5jf8FNxqrbu5FfFs=";
					}
				];
			})
		];
	};
}
