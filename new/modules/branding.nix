{ config, lib, pkgs, ... }:

{
  boot.plymouth.enable = true;
  
  environment.etc."os-release".text =
    ''
      NAME="Bloom OS"
      ID=bloom-os
      PRETTY_NAME="Bloom OS"
      VERSION="1.0"
      VERSION_ID="1.0"
      HOME_URL="https://example.com/"
      SUPPORT_URL="https://example.com/support"
      BUG_REPORT_URL="https://example.com/bugs"
      LOGO=bloom-logo.png
    '';
}
