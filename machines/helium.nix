{ modulesPath, ... }: {
	imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

	system.stateVersion = "24.05";

	hardware.cpu.intel.updateMicrocode = true;

	boot = {
		initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
		kernelModules = [ "kvm-intel" ];

		initrd.luks.devices.root-decrypted.allowDiscards = true;
	};

	fileSystems = {
		"/" = {
			device = "/dev/disk/by-uuid/35698e90-51dc-45d7-aee0-a100a723504a";
			fsType = "btrfs";
			options = [ "compress=zstd:15" ];
			encrypted = {
				label = "root-decrypted";
				enable = true;
				blkDev = "/dev/disk/by-uuid/6c57d84e-2440-4237-96ee-f51d291b1cbd";
			};
		};

		"/boot" = {
			device = "/dev/disk/by-uuid/26BB-6D03";
			fsType = "vfat";
		};
	};

	swapDevices = [
		{
			device = "/dev/disk/by-partuuid/8af4d245-7795-4de3-9b35-5d3627211d0d";
			randomEncryption.enable = true;
		}
	];

	networking = {
		hostName = "helium";
		useDHCP = true;

		wireless.iwd.enable = true;
	};

	users.users.emily.extraGroups = [ "networkmanager" ];

	programs.nm-applet.enable = true;
}
