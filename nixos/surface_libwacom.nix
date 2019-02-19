{stdenv, fetchurl, glib, pkgconfig, udev, libgudev}:
stdenv.mkDerivation rec {
  name = "libwacom-surface-${version}";
  version = "0.32";

  src = fetchurl {
    url = "https://github.com/linuxwacom/libwacom/releases/download/libwacom-${version}/libwacom-${version}.tar.bz2";
    sha256 = "102kz0q7i0bjsnl6yy83vcj2rpir12rs2d4xr0wvhw84rs5sp7bb";
  };

  patches = [ ./libwacom-surface/mei-bus.patch ./libwacom-surface/surface-tablet-data.patch ];

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [ glib udev libgudev ];

  postInstall = ''
    mkdir -p $out/lib/udev/rules.d
    ./tools/generate-udev-rules > "$out/lib/udev/rules.d/65-libwacom.rules"
  '';
}
