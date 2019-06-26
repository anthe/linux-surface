{config, lib, pkgs, ... }:
{ 
  nixpkgs.overlays = [(self: super: {
    libwacom = super.callPackage ./surface_libwacom.nix {};
    SB2_firmware = super.callPackage ./SB2_firmware.nix {};
    SB2_kernel = super.linuxPackages_5_1.extend( self: (ksuper: {
      kernel = ksuper.kernel.override {
        kernelPatches = [
          pkgs.kernelPatches.bridge_stp_helper
          pkgs.kernelPatches.modinst_arg_list_too_long
          { patch = ../patches/5.1/0001-surface-acpi.patch; name = "SB2-acpi"; }
          { patch = ../patches/5.1/0002-suspend.patch; name = "SB2-suspend"; }
          { patch = ../patches/5.1/0003-buttons.patch; name = "SB2-buttons"; }
          { patch = ../patches/5.1/0004-cameras.patch; name = "SB2-cameras"; }
          { patch = ../patches/5.1/0005-ipts.patch; name = "SB2-ipts"; }
          { patch = ../patches/5.1/0006-hid.patch; name = "SB2-hid"; }
          { patch = ../patches/5.1/0007-sdcard-reader.patch; name = "SB2-sdcard"; }
          { patch = ../patches/5.1/0008-wifi.patch; name = "SB2-wifi"; }
          { patch = ../patches/5.1/0009-surface3-power.patch; name = "S3-power"; }
          { patch = ../patches/5.1/0010-mwlwifi.patch; name = "SB2-mwlwifi"; }
          { patch = ../patches/5.1/0011-surface-lte.patch; name = "SB2-lte"; }
        ];
        extraConfig = (builtins.readFile ./kernel-config);
      };
    }));
  })];


  hardware.firmware = [ pkgs.SB2_firmware ];

  boot = {
    blacklistedKernelModules = [ "surfacepro3_button" "nouveau" ];
    #blacklistedKernelModules = [ "surfacepro3_button" ];
    kernelPackages = pkgs.SB2_kernel;
    extraModulePackages = [ pkgs.SB2_kernel.bbswitch ];
    extraModprobeConfig = (builtins.readFile ../root/etc/modprobe.d/snd-hda-intel.conf) + (builtins.readFile ../root/etc/modprobe.d/soc-button-array.conf);
    initrd = {
      kernelModules = [ "hid" "hid_sensor_hub" "i2c_hid" "hid_generic" "usbhid" "hid_multitouch" "intel_ipts" "surface_acpi" ];
      availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
    };
  };

  services.udev.packages = [ pkgs.SB2_firmware pkgs.libwacom ];

  powerManagement = {
    enable = true;
  };

  services.acpid = {
    enable = true;
    handlers = {
      lid = { action = ""; event = "button/lid.*"; };
    };
  };

  services.xserver.videoDrivers = [ "intel" ];
  #services.xserver.videoDrivers = [ "nouveau" ];
  # bbswitch doesn't load
  # switcheroo doesn't work
  # nvidia-smi doesn't detect any hardware, it might only detect it with X
  # lshw -C display does detect the graphics card
  # X loads nvidia, then unloads it due to GLX error, this is maybe the best place to start
  hardware.bumblebee = {
    enable = false;
    driver = "nvidia";
    pmMethod = "switcheroo";
  };

  hardware.nvidia = {
    modesetting.enable = false;
    optimus_prime = {
      enable = false;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:2:0:0";
    };
  };
 
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
    systemctl stop home-izak-.org_sync.mount
    systemctl stop wpa_supplicant.service
    modprobe -r mwlwifi
    modprobe -r intel_ipts
    modprobe -r mei_me
    modprobe -r mei
    modprobe -r mwifiex_pcie;
    modprobe -r mwifiex;
    modprobe -r cfg80211;
  '';

    #acpitool -W 21 >2 /dev/null
    #acpitool -W 5 >2 /dev/null
    #echo disabled > /sys/devices/LNXSYSTM:00/LNXSYBUS:00/PNP0C0D:00/power/wakeup
    #acpitool -W 2 >2 /dev/null
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
    modprobe -r soc_button_array
    modprobe -i soc_button_array
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
    systemctl start home-izak-.org_sync.mount
  '';
}
