final: prev:
let
  version = "9724";
in
{
  llama-cpp-cuda =
    (prev.llama-cpp.override {
      cudaSupport = true;
      cudaPackages = final.cudaPackages;
    }).overrideAttrs
      (old: {
        inherit version;
        src = prev.fetchFromGitHub {
          owner = "ggml-org";
          repo = "llama.cpp";
          tag = "b${version}";
          hash = "sha256-VOkQGsM36hRgN190DL5IgtFG28xa47CFDhmhkwMfRgo=";
          leaveDotGit = true;
          postFetch = ''
            git -C "$out" rev-parse --short HEAD > "$out/COMMIT"
            find "$out" -name .git -print0 | xargs -0 rm -rf
          '';
        };
        npmDepsHash = "sha256-0dctM/apI3ysMIEVBaBXO9hZMWskpJpNpOws1gwiOYc=";
        cmakeFlags =
          let
            keepFlag = flag: !(final.lib.hasInfix "CMAKE_CUDA_ARCHITECTURES" flag);
          in
          (builtins.filter keepFlag old.cmakeFlags)
          ++ [ (final.lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" "61;86") ];
      });
}
