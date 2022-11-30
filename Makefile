SHELL := bash

/nix:
	docker run --rm -it -e XDG_CACHE_HOME=/nix/var/wx_cache -v /nix:/nix-host nixos/nix cp -a /nix/. /nix-host
	docker run --rm -it -e XDG_CACHE_HOME=/nix/var/wx_cache --mount type=bind,source="/nix",target="/nix" --mount type=bind,source="$$(pwd)",target="$$(pwd)",readonly --workdir="$$(pwd)" nixos/nix nix-shell

.PHONY:
shell: /nix
	mkdir -p /tmp/nix-upper /tmp/nix-work
	docker run --rm -it -e XDG_CACHE_HOME=/nix/var/wx_cache --mount type=volume,dst=/nix,dst=/nix,volume-driver=local,volume-opt=type=overlay,volume-opt=device=overlay,\"volume-opt=o=lowerdir=/nix,upperdir=/tmp/nix-upper,workdir=/tmp/nix-work\" --mount type=bind,source="$$(pwd)",target="$$(pwd)",readonly --workdir="$$(pwd)" nixos/nix nix-shell || true
