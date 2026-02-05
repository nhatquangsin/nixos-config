# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Ho_Chi_Minh";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "vi_VN";
    LC_IDENTIFICATION = "vi_VN";
    LC_MEASUREMENT = "vi_VN";
    LC_MONETARY = "vi_VN";
    LC_NAME = "vi_VN";
    LC_NUMERIC = "vi_VN";
    LC_PAPER = "vi_VN";
    LC_TELEPHONE = "vi_VN";
    LC_TIME = "vi_VN";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nhatquangsin = {
    isNormalUser = true;
    description = "Quang Truong";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
    shell = pkgs.zsh;

    hashedPassword = "$6$9wZvN2e6wIucUB8Q$48PfbBcaF7pkxkBTk5z42bRHxWBSpPg1cCeogVNw1LzvsMoCRSCTFzMmRYB7mBxZwpoOxQ5DfUrJiOoz4eOOL1";
  };

  users.mutableUsers = false;

  users.users.quang = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDcf5viA9mrgmF0oziA7ab4+Rx+Rw2JuwQ394uQTyaxb quangtruong@MacBookPro"
    ];

    hashedPassword = "$6$hMcSBAnGOHkGLR5C$vq2aJgvtSFYgR6cy1FB2SLEgS9fBwdg5CSqZBvnx4lc8mYK/NdzMrc6yNcGjR4Aphhsq/7vmUxMGrhgPhdAJX0";
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Install zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    histSize = 100000;
    histFile = "$HOME/.zsh_history";
    setOptions = [
      "HIST_IGNORE_ALL_DUPS"
    ];

    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
        "z"
      ];
      theme = "robbyrussell";
    };
  };

  # Install tmux
  programs.tmux = {
    enable = true;
    clock24 = true;
  };

  # Install tailscale
  services.tailscale.enable = true;

  # Install neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    configure = {
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [
	  ctrlp
          nvim-treesitter
          telescope-nvim
        ];
      };
      customRC = ''
        set number
        set relativenumber
      '';
    };
  };

  environment.variables.EDITOR = "nvim";

  # Install docker
  virtualisation.docker.enable = true;

  services.vaultwarden = {
    enable = true;

    config = {
      DOMAIN = "https://vault.quangtmn.com";

      SIGNUPS_ALLOWED = false;

      # HTTP (Rocket)
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;

      # WebSocket notifications
      WEBSOCKET_ENABLED = true;
      WEBSOCKET_ADDRESS = "127.0.0.1";
      WEBSOCKET_PORT = 3012;
    };
  };

  services.caddy = {
    enable = true;

    environmentFile = "/etc/nixos/cloudflare.env";

    #virtualHosts."vault.quangtmn.com".extraConfig = ''
      #reverse_proxy /notifications/hub/negotiate 127.0.0.1:8222
      #reverse_proxy /notifications/hub 127.0.0.1:3012
      #reverse_proxy 127.0.0.1:8222
    #'';

    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
      hash = "sha256-dnhEjopeA0UiI+XVYHYpsjcEI6Y1Hacbi28hVKYQURg=";
    };

    virtualHosts."vault.quangtmn.com".extraConfig = ''
      tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
      }

      reverse_proxy /notifications/hub/negotiate 127.0.0.1:8222
      reverse_proxy /notifications/hub 127.0.0.1:3012

      reverse_proxy 127.0.0.1:8222
    '';
  };

  services.logind = {
    settings.Login = {
      HandleSuspendKey = "ignore";
      HandleHibernateKey = "ignore";
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      IdleAction = "ignore";
      # Optional: if you want to ensure it never triggers
      # IdleActionSec = "0";
    };
  };

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;


  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    pkgs.neovim
    # neovim helpers
    ripgrep
    fd
    git
    gcc
    gnumake
    unzip

    # Net tools
    pkgs.nettools
    netcat-gnu
    pkgs.inetutils
    pkgs.socat

    pkgs.bcc
    htop
    ghostty
    pkgs.git
    pkgs.vscode
    pkgs.terraform
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ];

  boot.extraModulePackages = [ pkgs.bcc ];


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;

    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
    };
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  networking.extraHosts = ''
    # 100.77.75.68  vaultwarden.local
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
