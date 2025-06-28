{ config, modulesPath, pkgs, ... }: {
	imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

	system.stateVersion = "25.05";

	boot.initrd.availableKernelModules = [ "xhci_pci" "virtio_scsi" ];

	fileSystems = {
		"/" = {
			device = "tmpfs";
			fsType = "tmpfs";
			options = [ "defaults" "mode=755" ];
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

		"/persistent" = {
			device = "/dev/disk/by-uuid/71f5a4ef-0a0b-4574-ae9a-b7b006b0337d";
			options = [ "subvol=persistent" ];
			neededForBoot = true;
		};
	};

	environment.persistence."/persistent" = {
		hideMounts = true;

		directories = [
			"/etc/nixos" # NixOS Configuration
			"/var/lib/nixos" # Needed to get Impermanence to stop complaining on build

			# Service Data Directories
			"/var/lib/caddy"
			"/var/lib/forgejo"
			"/var/lib/grafana"
			"/var/lib/headscale"
			"/var/lib/postgresql"
			"/var/lib/prometheus2"
			"/var/lib/tailscale"
		];

		files = [
			"/etc/machine-id"
		];
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

	virtualisation.docker = {
		enable = true;

		rootless = {
			enable = true;
			setSocketVariable = true;
		};
	};

	services.headscale = {
		enable = true;

		settings.dns.base_domain = "headscale.astralchroma.dev";
	};

	services.postgresql = {
		enable = true;

		package = pkgs.postgresql_17;

		ensureUsers = [
			{
				name = "axolotl_client-api";
				ensureDBOwnership = true;
				ensureClauses.login = true;
			}
			{
				name = "grafana";
				ensureDBOwnership = true;
				ensureClauses.login = true;
			}
		];

		ensureDatabases = [ "axolotl_client-api" "grafana" ];
	};

	# Disable mongodb for now as it's causing problems and nothing is actually using it
	/*
	services.mongodb = {
		enable = true;
		package = pkgs.mongodb-ce;
		dbpath = "/srv/mongodb";
	};
	*/

	services.prometheus = {
		enable = true;

		retentionTime = "100y"; # Basically forever!
		globalConfig.scrape_interval = "5s"; # This is probably extremely overkill, will likely change it later.

		scrapeConfigs = with config.services.prometheus.exporters; [
			{
				job_name = "node";
				static_configs = [{ targets = [ "localhost:${toString node.port}" ]; }];
			}
			{
				job_name = "process";
				static_configs = [{ targets = [ "localhost:${toString process.port}" ]; }];
			}
			{
				job_name = "axolotl_client-api";
				static_configs = [{ targets = [ "localhost:8000"]; }];
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
							"node_exporter"
							"process-exporte"
						];
					}

					{ name = "axolotl_client-api"; comm = [ "axolotl_client-" ]; }
					{ name = "caddy"; comm = [ "caddy" ]; }
					{ name = "forgejo"; comm = [ ".gitea-wrapped" ]; }
					{ name = "grafana"; comm = [ "grafana" ]; }
					{ name = "mongod"; comm = [ "mongod" ]; }
					{ name = "postgres"; comm = [ "postgres" ]; }

					{ name = "other"; cmdline = [ ".*" ]; }
				];
			};
		};
	};

	services.grafana = {
		enable = true;

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

	services.forgejo = {
		enable = true;
		
		database.type = "postgres";
		
		settings = {
			DEFAULT = {
				APP_NAME = "git.astralchroma.dev";
				APP_SLOGAN = "";
				APP_DISPLAY_NAME_FORMAT = "git.astralchroma.dev";
			};

			repository = {
				DISABLE_MIGRATIONS = true;
				DISABLE_DOWNLOAD_SOURCE_ARCHIVES = true;
			};

			server = {
				DOMAIN = "git.astralchroma.dev";
				ROOT_URL = "https://git.astralchroma.dev/";

				HTTP_PORT = 4000;
			};

			security = {
				MIN_PASSWORD_LENGTH = 12;
				PASSWORD_COMPLEXITY = "lower,upper,digit,spec";
			};

			session.COOKIE_SECURE = true;
			admin.DISABLE_REGULAR_ORG_CREATION = true;
			service.DISABLE_REGISTRATION = true;
			packages.ENABLED = false;
		};
	};

	age.secrets.axolotlClientApiHypixelApiKey = {
		file = ../../secrets/axolotl_client-api-hypixel-api-key.age;
		owner = "axolotl_client-api";
		group = "axolotl_client-api";
	};

	services.axolotlClientApi = {
		enable = true;
		postgresUrl = "postgres:///axolotl_client-api";
		hypixelApiKeyFile = config.age.secrets.axolotlClientApiHypixelApiKey.path;
	};

	services.caddy = {
		enable = true;
		configFile = ./Caddyfile;
	};

	environment.etc = {
		"ssh/ssh_host_rsa_key".source = "/persistent/etc/ssh/ssh_host_rsa_key";
		"ssh/ssh_host_rsa_key.pub".source = "/persistent/etc/ssh/ssh_host_rsa_key.pub";
		"ssh/ssh_host_ed25519_key".source = "/persistent/etc/ssh/ssh_host_ed25519_key";
		"ssh/ssh_host_ed25519_key.pub".source = "/persistent/etc/ssh/ssh_host_ed25519_key.pub";
	};

	users = {
		mutableUsers = false;

		users.root.initialHashedPassword = "$y$j9T$7Y8zcgUU47qagjVNTVPVH.$uYcBIfNpvQ/hG9uG3dRL4zH8gZKbPYrOcFXO4ZFuCu7";
		users.emily.initialHashedPassword = "$y$j9T$7Y8zcgUU47qagjVNTVPVH.$uYcBIfNpvQ/hG9uG3dRL4zH8gZKbPYrOcFXO4ZFuCu7";

		users.emily.packages = [ pkgs.mongosh ];
	};
}
