{ config, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nahian"; 
  
  networking.networkmanager.enable = true; 

  time.timeZone = "Asia/Dhaka";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "bn_BD";
    LC_IDENTIFICATION = "bn_BD";
    LC_MEASUREMENT = "bn_BD";
    LC_MONETARY = "bn_BD";
    LC_NAME = "bn_BD";
    LC_NUMERIC = "bn_BD";
    LC_PAPER = "bn_BD";
    LC_TELEPHONE = "bn_BD";
    LC_TIME = "bn_BD";
  };


  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # user
  users.users.nahian = {
    isNormalUser = true;
    description = "nahian";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

 


   
   services.pipewire = {
     enable = true;
     alsa.enable = true;
     };

     services.wireplumber.enable = true;

     services.bluetooth = {
     enable = true;
     };




  services.getty.autologinUser = "nahian";

  nixpkgs.config.allowUnfree = true;

  #install software here
  environment.systemPackages = with pkgs; [
    git
    neovim 
    wget
    curl
    fastfetch
    foot
    fuzzel
    waybar
    swaybg
    mako
    wl-clipboard
    cliphist
    grim
    slurp
    wlogout
    brightnessctl
    pipewire
    wireplumber
    bluez
    bluez-tools
    pipewire-alsa
    pamixer
    wpctl
    playerctl



  ];

   fonts.packages = with pkgs; [
     nerd-fonts.jetbrains-mono
  ];





  # zram
  zramSwap.enable = true;

  # swapfile
  swapDevices = [
    {
      device = "/swapfile";  
      size = 9415;            
    }
  ];




nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.05"; 

}
