{ config, inputs, lib, modulesPath, pkgs, ... }: {
	imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

	system.stateVersion = "24.05";

	nix.gc.automatic = false;

	hardware.cpu.amd.updateMicrocode = true;

	boot = {
		swraid.enable = true;

		initrd = {
			availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];

			luks.devices.root = {
				device = "/dev/disk/by-uuid/63a975e1-85cd-4e95-a04f-b2be3e026c27";

				tryEmptyPassphrase = true;
				allowDiscards = true;
				bypassWorkqueues = true;
			};

			luks.devices.secondary = {
				device = "/dev/disk/by-uuid/9d3822ba-9f35-4bb5-b12a-3e0a5a41eec1";

				tryEmptyPassphrase = true;
				allowDiscards = true;
				bypassWorkqueues = true;
			};

			luks.devices.secondary-cache = {
				device = "/dev/disk/by-uuid/c28c020b-127c-4d85-817c-80fdcdd16d39";

				tryEmptyPassphrase = true;
				allowDiscards = true;
				bypassWorkqueues = true;
			};
		};

		kernelModules = [ "kvm-amd" ];
	};

	fileSystems = {
		"/" = {
			device = "/dev/mapper/root";
			fsType = "btrfs";
			options = [ "compress=zstd:15" ];
		};

		"/media/Data" = {
			device = "/dev/mapper/root";
			fsType = "btrfs";
			options = [ "subvol=/data" ];
			neededForBoot = false;
		};

		"/boot" = {
			device = "/dev/disk/by-uuid/8292-4648";
			fsType = "vfat";
		};

		"/media/secondary" = {
			device = "/dev/mapper/secondary";
			fsType = "bcachefs";
			neededForBoot = false;
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
	
	environment.systemPackages = with pkgs; [
		bcachefs-tools
		inputs.agenix.packages."${pkgs.system}".default
		rclone
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
			Persistent = true;
		};
	};

	users.users.emily.packages = with pkgs; [
		nvtopPackages.amd nur.repos.iuricarras.truckersmp-cli

		(ciscoPacketTracer8.overrideAttrs { dontCheckForBrokenSymlinks = true; })
	];
}
