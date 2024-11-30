let
	emily = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICMFmGardIjKxRdrlDqUQtzSIBad+1PKbao4MWS/++AL";
	users = [ emily ];

	lithium = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJiuSH1QYRaxoZGfrFJy1SWcP0miL09+m6fKnuPoRg7";
	beryllium-old = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOTkdeQiCd4y+ZsIVyoMlMnnFUTqOX6qdWw/QLmsc4ck";
	
	systems = [ lithium beryllium-old ];
in {
	"aggregator_discord_token.age".publicKeys = [ emily beryllium-old ];

	"autochroma-database_uri.age".publicKeys = [ emily beryllium-old ];
	"autochroma-discord_token.age".publicKeys = [ emily beryllium-old ];

	"axolotl_client-api-hypixel-api-key.age".publicKeys = [ emily beryllium-old ];

	"rclone.conf.age".publicKeys = [ emily lithium ];
}
