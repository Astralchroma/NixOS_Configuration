{ config, modulesPath, pkgs, ... }: {
	imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

	system.stateVersion = "25.05";

	boot.initrd.availableKernelModules = [ "xhci_pci" "virtio_scsi" ];

	fileSystems = {
		"/" = {
			device = "tmpfs";
			fsType = "tmpfs";
			options = [ "mode=755" ];
			neededForBoot = true;
		};

		"/boot" = {
			device = "/dev/disk/by-uuid/4C51-A2F3";
			fsType = "vfat";
		};

		"/nix" = {
			device = "/dev/disk/by-uuid/71f5a4ef-0a0b-4574-ae9a-b7b006b0337d";
			fsType = "btrfs";
			options = [ "compress=lzo" "subvol=nix" ];
			neededForBoot = true;
		};

		"/etc/persistent" = {
			device = "/dev/disk/by-uuid/71f5a4ef-0a0b-4574-ae9a-b7b006b0337d";
			options = [ "subvol=etc/persistent" ];
			neededForBoot = true;
		};

		"/etc/nixos" = {
			device = "/dev/disk/by-uuid/71f5a4ef-0a0b-4574-ae9a-b7b006b0337d";
			options = [ "subvol=etc/nixos" ];
		};

		"/srv" = {
			device = "/dev/disk/by-uuid/71f5a4ef-0a0b-4574-ae9a-b7b006b0337d";
			options = [ "subvol=srv" ];
		};

		"/var/lib/prometheus" = {
			device = "/dev/disk/by-uuid/71f5a4ef-0a0b-4574-ae9a-b7b006b0337d";
			options = [ "subvol=srv/prometheus" ];
		};
	};

	services.postgresql = {
		enable = true;

		package = pkgs.postgresql_17;
		dataDir = "/srv/postgresql/17";

		ensureUsers = [
			{
				name = "grafana";
				ensureDBOwnership = true;
				ensureClauses.login = true;
			}
		];

		ensureDatabases = [ "grafana" ];
	};

	services.mongodb = {
		enable = true;
		package = pkgs.mongodb-7_0;
		dbpath = "/srv/mongodb";
	};

	services.prometheus = {
		enable = true;

		stateDir = "prometheus";

		retentionTime = "100y"; # Basically forever!
		globalConfig.scrape_interval = "5s"; # This is probably extremely overkill, will likely change it later.

		scrapeConfigs = with config.services.prometheus.exporters; [
			{
				job_name = "node";
				static_configs = [{ targets = [ "localhost:${toString node.port}" ]; }];
			}
			{
				job_name = "postgres";
				static_configs = [{ targets = [ "localhost:${toString postgres.port}" ]; }];
			}
			{
				job_name = "process";
				static_configs = [{ targets = [ "localhost:${toString process.port}" ]; }];
			}
		];

		exporters = {
			node.enable = true;
			postgres.enable = true;

			process = {
				enable = true;

				settings.process_names = [
					{
						name = "prometheus";
						comm = [
							"prometheus"
							"postgres_export"
							"node_exporter"
							"process-exporte"
						];
					}

					{ name = "caddy"; comm = [ "caddy" ]; }
					{ name = "grafana"; comm = [ "grafana" ]; }
					{ name = "postgres"; comm = [ "postgres" ]; }

					{ name = "other"; cmdline = [ ".*" ]; }
				];
			};
		};
	};

	services.grafana = {
		enable = true;

		dataDir = "/srv/grafana";

		settings = {
			server = {
				domain = "monitoring.astralchroma.dev";
				enforce_domain = true;
			};

			database = {
				type = "postgres";
				user = "grafana";
				host = "/var/run/postgresql";
			};

			"auth.anonymous" = {
				enabled = true;
				hide_version = true;
				org_name = "Astralchroma";
			};

			users.password_hint = "correct horse battery staple";

			analytics.enabled = false;
			news.news_feed_enabled = false;
		};
	};

	services.caddy = {
		enable = true;
		configFile = ./Caddyfile;
		dataDir = "/srv/caddy";
	};

	networking = {
		hostName = "beryllium";

		nftables.enable = true;
		useDHCP = true;

		firewall = {
			allowedTCPPorts = [ 80 443 ];
			allowedUDPPorts = [ 443 ];
		};
	};

	environment.etc = {
		"machine-id".source = "/etc/persistent/machine-id";

		"ssh/ssh_host_rsa_key".source = "/etc/persistent/ssh_host_rsa_key";
		"ssh/ssh_host_rsa_key.pub".source = "/etc/persistent/ssh_host_rsa_key.pub";
		"ssh/ssh_host_ed25519_key".source = "/etc/persistent/ssh_host_ed25519_key";
		"ssh/ssh_host_ed25519_key.pub".source = "/etc/persistent/ssh_host_ed25519_key.pub";
	};

	users = {
		mutableUsers = false;

		users.root.initialHashedPassword = "$y$j9T$7Y8zcgUU47qagjVNTVPVH.$uYcBIfNpvQ/hG9uG3dRL4zH8gZKbPYrOcFXO4ZFuCu7";
		users.emily.initialHashedPassword = "$y$j9T$7Y8zcgUU47qagjVNTVPVH.$uYcBIfNpvQ/hG9uG3dRL4zH8gZKbPYrOcFXO4ZFuCu7";

		users.emily.packages = [ pkgs.mongosh ];
	};
}
