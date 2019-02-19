{stdenv, fetchgit, unzip, kmod}:
stdenv.mkDerivation rec {
  name = "SB2_firmware";
  src = fetchgit {
    url="https://github.com/jakeday/linux-surface";
    rev= "ddda979ec107cb96595048d0a933c156f918cae2";
    sha256 = "00p1qvsyamqf6hwazpwkw5i661vwj6hc0yf85r0gp4shm3lnd0n9";
    fetchSubmodules = false;
  };

  buildInputs = [ unzip kmod ];

  patches = [ ./sbin.patch ];

  buildPhase = "";

  installPhase = ''
    mkdir -p "$out/lib/firmware/i915/"
    unzip -o firmware/i915_firmware_kbl.zip -d $out/lib/firmware/i915/
    mkdir -p "$out/lib/firmware/nvidia/gp108/"
    unzip -o firmware/nvidia_firmware_gp108.zip -d $out/lib/firmware/nvidia/gp108/
    mkdir -p "$out/lib/firmware/intel/ipts/"
    unzip -o firmware/ipts_firmware_v101.zip -d $out/lib/firmware/intel/ipts/
    mkdir -p "$out/lib/firmware/mrvl/"
    unzip -o firmware/mrvl_firmware.zip -d $out/lib/firmware/mrvl/
    mkdir -p "$out/lib/firmware/mwlwifi/"
    unzip -o firmware/mwlwifi_firmware.zip -d $out/lib/firmware/mwlwifi/

    mkdir -p "$out/lib/udev/rules.d"
    cp root/etc/udev/rules.d/* $out/lib/udev/rules.d/

    sed -i -e "s|modprobe|${kmod}/bin/modprobe|" $out/lib/udev/rules.d/*
    
    rm $out/lib/udev/rules.d/98-keyboardscovers.rules
  '';
}
