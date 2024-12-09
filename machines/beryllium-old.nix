{ config, inputs, modulesPath, pkgs, ... }: {
	nixpkgs.overlays = [
		(self: super: {
			autochroma = super.callPackage ./packages/autochroma.nix {};
		})
	];

	containers.mongo = {
		autoStart = true;

		bindMounts = {
			"/srv" = {
				hostPath = "/srv/mongo";
				isReadOnly = false;
			};
		};

		config = {
			nixpkgs.config.allowUnfree = true;
			system.stateVersion = "24.11";

			services.mongodb = {
				enable = true;
				package = pkgs.mongodb-ce;
				dbpath = "/srv";
			};
		};
	};

	containers.caddy = {
		autoStart = true;

		bindMounts = {
			"/srv" = {
				hostPath = "/srv/http";
				isReadOnly = true;
			};
		};

		config = {
			system.stateVersion = "24.11";

			services.caddy = {
				enable = true;
				email = "astralchroma@proton.me";

				virtualHosts."https://astralchroma.dev".extraConfig = ''
					root * /srv/

					file_server {
						hide /srv/.git/
					}
				'';

				virtualHosts."https://tailscale.astralchroma.dev".extraConfig = ''
					reverse_proxy http://localhost:8080
				'';

				# Fuck you cloudflare, let me use subsubdomains damn it
				# Fuck you let's encrypt, let me use `_` damn it
				virtualHosts."https://axolotlclient-api.astralchroma.dev".extraConfig = ''
					handle_path /dev/* {
						reverse_proxy http://localhost:8000
					}
				'';

				# Fuck you cloudflare, let me use subsubdomains damn it
				virtualHosts."https://solarscape-api.astralchroma.dev".extraConfig = ''
					respond "Not Found" 404
				'';
			};
		};
	};

	containers.headscale = {
		autoStart = true;

		bindMounts = {
			"/srv" = {
				hostPath = "/srv/headscale";
				isReadOnly = false;
			};
		};

		config = {
			system.stateVersion = "24.11";

			services.headscale = {
				enable = true;

				settings = {
					database.sqlite.path = "/srv/db.sqlite";
					dns.base_domain = "tailscale.astralchroma.dev";
					noise.private_key_path = "/srv/noise_private.key";
				};
			};

			systemd.services.headscale.serviceConfig.ReadWritePaths = "/srv";
		};
	};

	age.secrets.axolotlClientApiHypixelApiKey = {
		file = ./secrets/axolotl_client-api-hypixel-api-key.age;
		owner = "axolotl_client-api";
		group = "axolotl_client-api";
	};

	services = {
		tailscale.enable = true;

		axolotlClientApi = {
			enable = true;
			postgresUrl = "postgres:///axolotl_client-api";
			hypixelApiKeyFile = config.age.secrets.axolotlClientApiHypixelApiKey.path;
		};
	};

	age.secrets.autochromaDiscordToken = {
		file = ./secrets/autochroma-discord_token.age;
		owner = "autochroma";
		group = "autochroma";
	};

	age.secrets.autochromaDatabaseUri = {
		file = ./secrets/autochroma-database_uri.age;
		owner = "autochroma";
		group = "autochroma";
	};

	users.users.autochroma = { isSystemUser = true; name = "autochroma"; group = "autochroma"; };
	users.groups.autochroma = {};

	systemd.services.autochroma = {
		description = "Autochroma Discord Bot";

		after = [ "postgresql.service" ];
		requires = [ "postgresql.service" ];

		upheldBy = [ "multi-user.target" ];

		serviceConfig = with config.age.secrets; {
			User = "autochroma";
			Group = "autochroma";

			Type = "exec";
			ExecStart = "${pkgs.autochroma}/bin/autochroma --discord-token-file ${autochromaDiscordToken.path} --database-uri-file ${autochromaDatabaseUri.path}";

			CapabilityBoundingSet = "";
			LockPersonality = true;
			MemoryDenyWriteExecute = true;
			NoNewPrivileges = true;
			PrivateDevices = true;
			PrivateMounts = true;
			PrivateTmp = true;
			PrivateUsers = true;
			ProcSubset = "pid";
			ProtectClock = true;
			ProtectControlGroups = true;
			ProtectHome = true;
			ProtectHostname = true;
			ProtectKernelLogs = true;
			ProtectKernelModules = true;
			ProtectKernelTunables = true;
			ProtectProc = "invisible";
			ProtectSystem = "strict";
			RemoveIPC = true;
			RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6";
			RestrictNamespaces = true;
			RestrictRealtime = true;
			RestrictSUIDSGID = true;
			SystemCallArchitectures = "native";
			SystemCallFilter = "@basic-io @file-system @io-event @network-io @process @signal ioctl madvise";
			UMask = "777";
		};
	};
}
