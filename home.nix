{ config, pkgs, lib, ... }:

{
  home.username = "nahian";
  home.homeDirectory = "/home/nahian";
  home.stateVersion = "25.05";

  programs.git.enable = true;

  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo I use nixos, btw";
    };
  };
   home.packages = with pkgs; [
   google-chrome




   ];

}

