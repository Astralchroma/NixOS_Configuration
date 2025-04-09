{ config, inputs, lib, modulesPath, pkgs, ... }: {
	imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

	system.stateVersion = "24.05";

	nix.gc.automatic = false;

	hardware.cpu.amd.updateMicrocode = true;

	boot = {
		swraid.enable = true;

		initrd = {
			availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
			kernelModules = [ "bcache" ];

			services.bcache.enable = true;

			luks.devices.lithium = {
				device = "/dev/disk/by-uuid/63a975e1-85cd-4e95-a04f-b2be3e026c27";

				tryEmptyPassphrase = true;
				allowDiscards = true;
				bypassWorkqueues = true;
			};
		};

		kernelModules = [ "kvm-amd" ];
		
		loader.systemd-boot.extraInstallCommands = ''
			if ${pkgs.util-linux}/bin/mountpoint -q /boot2
			then
				printf "\033[1;34mMirroring /boot to /boot2. EFI System Partition will be redundant!\033[0m\n"
				${pkgs.rsync}/bin/rsync -aUH --delete-after /boot/ /boot2/
			else
				printf "\033[1;31mMountpoint /boot2 does not exist! EFI System Partition will not be redundant!\033[0m\n"
			fi
		'';

		bcache.enable = true;
	};

	fileSystems = {
		"/" = {
			device = "/dev/mapper/lithium";
			fsType = "btrfs";
			options = [ "compress=zstd:15" ];
		};

		"/media/Data" = {
			device = "/dev/mapper/lithium";
			fsType = "btrfs";
			options = [ "subvol=/data" ];
		};

		"/media/Library" = {
			device = "/dev/mapper/lithium";
			fsType = "btrfs";
			options = [ "subvol=/library" ];
		};

		"/boot" = {
			device = "/dev/disk/by-uuid/8292-4648";
			fsType = "vfat";
		};

		"/boot2" = {
			device = "/dev/disk/by-uuid/8236-8023";
			fsType = "vfat";
		};
	};

	networking = {
		hostName = "lithium";
		defaultGateway = "192.168.1.254";
		useDHCP = false;

		interfaces.enp7s0.ipv4.addresses = [{
			address = "192.168.2.1";
			prefixLength = 16;
		}];

		firewall = {
			allowedTCPPorts = [
				8096 # Jellyfin
				22000 # Syncthing
			];

			allowedUDPPorts = [
				21027 # Syncthing
				22000 # Syncthing
			];
		};
	};

	services = {
		syncthing = {
			enable = true;
			user = "emily";
			configDir = "/home/emily/.config/syncthing";
			overrideDevices = true;
			overrideFolders = true;
			settings = {
				devices = {
					"Phone" = { id = "QW5ZI4M-GFPS4KC-V6XZ43A-Y46P6KR-TBK7QKA-JJV75WI-DZPVUPG-44U3AQP"; };
				};
				folders = {
					"Journal" = {
						path = "/media/Data/Journal";
						devices = [ "Phone" ];
					};
				};
			};
		};

		lvm.boot.thin.enable = true;
		jellyfin.enable = true;
	};

	systemd.targets.sleep.enable = lib.mkForce false;
	systemd.targets.suspend.enable = lib.mkForce false;
	systemd.targets.hibernate.enable = lib.mkForce false;
	systemd.targets.hybrid-sleep.enable = lib.mkForce false;
	
	environment.systemPackages = [
		inputs.agenix.packages."${pkgs.system}".default
		pkgs.rclone
	];

	age.secrets.rclone.file = ../secrets/rclone.conf.age;

	systemd.services.rclone = {
		enable = true;
		requires = [ "media-Data.mount" ];
		serviceConfig = {
			Type = "oneshot";
			ExecStart = "${pkgs.rclone}/bin/rclone --config ${config.age.secrets.rclone.path} sync --copy-links --order-by size,descending --delete-during --track-renames --verbose --delete-excluded --exclude-from /media/Data/.excluded --fast-list /media/Data backblaze:astralchroma-horizon";
		};
	};

	systemd.timers.rclone = {
		enable = true;
		wantedBy = [ "timers.target" ];
		timerConfig = {
			OnCalendar = "hourly";
			Persisent = true;
		};
	};

	users.users.emily.packages = with pkgs; [
		nvtopPackages.amd nur.repos.iuricarras.truckersmp-cli

		(ciscoPacketTracer8.overrideAttrs { dontCheckForBrokenSymlinks = true; })
	];
}
