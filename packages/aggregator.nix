# Mostly copy pasted from <https://nixos.org/manual/nixpkgs/unstable/#gradle>
{ fetchFromGitHub, gradle, lib, pkgs, stdenv }: stdenv.mkDerivation rec {
	pname = "aggregator";
	version = "1.4.2";

	src = fetchFromGitHub {
		owner = "Astralchroma";
		repo = "Aggregator";
		rev = "c3af0c2";
		hash = "";
	};

	nativeBuildInputs = [ pkgs.gradle ];

	mitmCache = gradle.fetchDeps {
		inherit pname;
		data = ./deps.json;
	};
	
	__darwinAllowLocalNetworking = true;

	gradleFlags = [ "-Dfile.encoding=utf-8" ];

	gradleBuildTask = "build";

	installPhase = ''
		mkdir -p $out/{bin/aggregator}
		cp build/libs/aggregator-all.jar $out/share/aggregator

		makeWrapper ${pkgs.jdk17}/bin/java $out/bin/aggregator \
			--add-flags "-jar $out/share/aggregator/aggregator-all.jar"
	'';

	meta.sourceProvenance = with lib.sourceTypes; [
		fromSource
		binaryBytecode
	];
}
