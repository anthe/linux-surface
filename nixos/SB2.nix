{config, lib, pkgs, ... }:
{ 
  nixpkgs.overlays = [(self: super: {
    libwacom = super.callPackage ./surface_libwacom.nix {};
    SB2_firmware = super.callPackage ./SB2_firmware.nix {};
    SB2_kernel = super.linuxPackages_4_19.extend( self: (ksuper: {
      kernel = ksuper.kernel.override {
        kernelPatches = [
          pkgs.kernelPatches.bridge_stp_helper
          pkgs.kernelPatches.modinst_arg_list_too_long
          { patch = ./linux-surface/patches/4.19/0001-surface-acpi.patch; name = "SB2-acpi"; }
          { patch = ./linux-surface/patches/4.19/0002-suspend.patch; name = "SB2-suspend"; }
          { patch = ./linux-surface/patches/4.19/0003-buttons.patch; name = "SB2-buttons"; }
          { patch = ./linux-surface/patches/4.19/0004-cameras.patch; name = "SB2-cameras"; }
          { patch = ./linux-surface/patches/4.19/0005-ipts.patch; name = "SB2-ipts"; }
          { patch = ./linux-surface/patches/4.19/0006-hid.patch; name = "SB2-hid"; }
          { patch = ./linux-surface/patches/4.19/0007-sdcard-reader.patch; name = "SB2-sdcard"; }
          { patch = ./linux-surface/patches/4.19/0008-wifi.patch; name = "SB2-wifi"; }
          { patch = ./linux-surface/patches/4.19/0009-surface3-power.patch; name = "S3-power"; }
          { patch = ./linux-surface/patches/4.19/0010-surface-dock.patch; name = "SB2-dock"; }
          { patch = ./linux-surface/patches/4.19/0011-mwlwifi.patch; name = "SB2-mwlwifi"; }
        ];
        extraConfig = (builtins.readFile ./config);
        /*
        structuredExtraConfig = {
          #LOCALVERSION="-surface";
          CFG80211_DEFAULT_PS="n";
          PCIEPORTBUS="y";
          INTEL_IPTS="m";
          #VIDEO_IPU3_CIO2="m";
          #VIDEO_OV5693="m";
          #VIDEO_OV8865="m";
          DRM_I915_ALPHA_SUPPORT="y";
          #INTEL_ATOMISP="y";
          SURFACE_ACPI="m";
          DEBUG_INFO="n";
          SERIAL_DEV_BUS="y";
          SERIAL_DEV_CTRL_TTYPORT="y";
          NF_CONNTRACK_IPV6="m";
          NF_TABLES_IPV6="y";
          NFT_CHAIN_ROUTE_IPV6="m";
          NFT_CHAIN_NAT_IPV6="m";
          NFT_MASQ_IPV6="m";
          NFT_REDIR_IPV6="m";
          NFT_REJECT_IPV6="m";
          NFT_DUP_IPV6="m";
          NFT_FIB_IPV6="m";
          NF_NAT_IPV6="m";
          NF_NAT_MASQUERADE_IPV6="y";
          IP6_NF_MATCH_SRH="m";
          IP6_NF_NAT="m";
          IP6_NF_TARGET_MASQUERADE="m";
          IP6_NF_TARGET_NPT="m";
          MWLWIFI="m";
        };
        */
      };
    }));
  })];

  hardware.firmware = [ pkgs.SB2_firmware ];
  services.udev.packages = [ pkgs.SB2_firmware pkgs.libwacom ];
  hardware.bluetooth.enable = true;
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  services.acpid.enable = true; 

  boot = {
    blacklistedKernelModules = [ "nouveau" "surfacepro3_button" ];
    kernelPackages = pkgs.SB2_kernel;
    initrd = {
      kernelModules = [ "hid" "hid_sensor_hub" "i2c_hid" "hid_generic" "usbhid" "hid_multitouch" "intel_ipts" "surface_acpi" ];
      availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
    };
  };
  
  services.xserver.videoDrivers = [ "intel" ];
  #hardware.bumblebee = {
    #enable = true;
    #driver = "nouveau";
    #pmMethod = "switcheroo";
  #};
 
  services.xserver.xkbOptions = "caps:hyper";
  
  networking.networkmanager = {
    enable = true;
    #packages = [ "ifupdown" "keyfile" "ofono" ];
    wifi = {
      scanRandMacAddress = false;
      powersave = true;
    };
  };

  environment.etc = { "systemd/sleep.conf".text = "SuspendState=freeze\n"; };

  powerManagement.powerDownCommands = ''
    source /etc/profile
    systemctl stop wpa_supplicant.service
    modprobe -r mwlwifi
    modprobe -r intel_ipts
    modprobe -r mei_me
    modprobe -r mei
    modprobe -r mwifiex_pcie;
    modprobe -r mwifiex;
    modprobe -r cfg80211;
  '';

  powerManagement.powerUpCommands = ''
    source /etc/profile
    modprobe -r intel_ipts
    modprobe -r mwlwifi
    modprobe -r mei_me
    modprobe -r mei
    modprobe -r mwifiex_pcie;
    modprobe -r mwifiex;
    modprobe -r cfg80211;
    # and reload
    modprobe -i intel_ipts
    modprobe -i mei_me
    modprobe -i mei
    modprobe -i cfg80211;
    modprobe -i mwifiex;
    modprobe -i mwifiex_pcie;
    modprobe -i mwlwifi
    echo 1 > /sys/bus/pci/rescan
    systemctl restart wpa_supplicant.service
  '';
  powerManagement.resumeCommands = ''
    source /etc/profile
    modprobe -r intel_ipts
    modprobe -r mwlwifi
    modprobe -r mei_me
    modprobe -r mei
    modprobe -r mwifiex_pcie;
    modprobe -r mwifiex;
    modprobe -r cfg80211;
    modprobe -r soc_button_array
    # and reload
    modprobe -i intel_ipts
    modprobe -i mei_me
    modprobe -i mei
    modprobe -i cfg80211;
    modprobe -i mwifiex;
    modprobe -i mwifiex_pcie;
    modprobe -i mwlwifi
    modprobe -i soc_button_array
    echo 1 > /sys/bus/pci/rescan
    systemctl restart wpa_supplicant.service
  '';
}
