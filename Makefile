# Connectivity info for Nix VM
# Fill in the following info before running make
NIXADDR ?= unset
NIXPORT ?= 22
NIXUSER ?= coryaj

# SSH options that are reused frequently throughout this file
# PubKeyAuthentication -> Specifies whether to try public key authentication; accepted values are yes (default) or no
# UserKnownHostsFile -> Specifies where to store known hosts; default is ~/.ssh/known_hosts; /dev/null discards anything written to it
# StrictHostKeyChecking -> Specifies whether to only connect to known hosts; Prevents connection from possibly being rejected
SSH_OPTIONS=-o PubKeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

# Bootstrap a brand new VM
# Initial setup
vm/bootstrap0:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) root@$(NIXADDR) " \
		parted /dev/sda -- mklabel gpt; \
		parted /dev/sda -- mkpart primary 512MiB -8GiB; \
		parted /dev/sda -- mkpart primary linux-swap -8GiB 100%; \
		parted /dev/sda -- mkpart ESP fat32 1MiB 512 MiB; \
		parted /dev/sda -- set 3 esp on; \
		mkfs.ext4 -L nixos /dev/sda1; \
		mkswap -L swap /dev/sda2; \
		swapon /dev/sda2; \
		mkfs.fat -F 32 -n boot /dev/sda3; \
		mount /dev/disk/by-label/nixos /mnt; \
		mkdir -p /mnt/boot; \
		mount /dev/disk/by-label/boot /mnt/boot; \
		nixos-generate-config --root /mnt; \
		sed --in-place '/system\.stateVersion = .*/a \
			nix.package = pkgs.nixUnstable;\n \
			nix.extraOptions = \"experimental-features = nix-command flakes\";\n \
			services.openssh.enable = true;\n \
			services.openssh.passwordAuthentication = true;\n \
			services.openssh.permitRootLogin = \"yes\";\n \
			users.users.root.initialPassword = \"root\";\n \
		' /mnt/etc/nixos/configuration.nix; \
		nixos-install --no-root-passwd; \
		reboot; \
	"
