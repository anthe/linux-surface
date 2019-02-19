{stdenv, fetchgit, unzip, kmod, coreutils}:
stdenv.mkDerivation rec {
  name = "SB2_firmware";

  src = ./linux-surface;

  buildInputs = [ unzip kmod ];

  patches = [ ./98-keyboardscovers.patch ];

  buildPhase = "";

  installPhase = ''
    mkdir -p "$out/lib/firmware/i915/"
    unzip -o firmware/i915_firmware_kbl.zip -d $out/lib/firmware/i915/

    mkdir -p "$out/lib/firmware/intel/ipts/"
    unzip -o firmware/ipts_firmware_v101.zip -d $out/lib/firmware/intel/ipts/

    mkdir -p "$out/lib/firmware/nvidia/gp108/"
    unzip -o firmware/nvidia_firmware_gp108.zip -d $out/lib/firmware/nvidia/gp108/
    mkdir -p "$out/lib/firmware/nvidia/gv100"
    unzip -o firmware/nvidia_firmware_gv100.zip -d $out/lib/firmware/nvidia/gv100

    mkdir -p "$out/lib/firmware/mrvl/"
    unzip -o firmware/mrvl_firmware.zip -d $out/lib/firmware/mrvl/
    mkdir -p "$out/lib/firmware/mwlwifi/"
    unzip -o firmware/mwlwifi_firmware.zip -d $out/lib/firmware/mwlwifi/

    mkdir -p "$out/lib/udev/rules.d"
    cp root/etc/udev/rules.d/* $out/lib/udev/rules.d/

    sed -i -e "s|modprobe|${kmod}/bin/modprobe|" $out/lib/udev/rules.d/*
    
  '';
}
