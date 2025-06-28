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

	age.secrets.aggregator_discord_token = {
		file = ./secrets/aggregator_discord_token.age;
	};

	containers.aggregator = {
		autoStart = true;

		bindMounts = {
			"/srv" = {
				hostPath = "/srv/aggregator";
				isReadOnly = false;
			};
			"${config.age.secrets.aggregator_discord_token.path}" = {
				isReadOnly = true;
			};
		};

		config = {
			system.stateVersion = "24.11";

			environment.systemPackages = [ pkgs.jdk17 ];

			systemd.services.aggregator = {
				enable = true;
				description = "Aggregator";
				unitConfig.Type = "simple";
				script = ''DISCORD_TOKEN=$(cat "${config.age.secrets.aggregator_discord_token.path}") ${pkgs.jdk17}/bin/java -jar /srv/build/libs/Aggregator-1.4.1-all.jar'';
				wantedBy = [ "multi-user.target" ];
				environment = {
					MONGO_URI = "mongodb://localhost";
					MONGO_DATABASE = "aggregator";
					OWNER_SNOWFLAKE = "521031433972744193";
				};
			};
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
