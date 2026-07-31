{ paseo }:
final: _prev: {
  paseo = paseo.packages.${final.stdenv.hostPlatform.system}.paseo;
  paseo-desktop = paseo.packages.${final.stdenv.hostPlatform.system}.desktop;
}
