final: prev:
let
  version = "9724";
in
{
  llama-cpp-cuda =
    (prev.llama-cpp.override {
      cudaSupport = true;
      cudaPackages = final.cudaPackages;
      # nixpkgs builds the llama.cpp web UI with `nodejs_latest`, which is node 26
      # on recent revisions. Binary caches lag freshly bumped nodejs majors, so
      # every llama.cpp build would drag a full V8 compile along with it.
      # nodejs_22 is already in the system closure and satisfies the UI's
      # engine floor (vite: ^20.19.0 || >=22.12.0).
      nodejs_latest = final.nodejs_22;
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
          ++ [ (final.lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" "86") ];
      });
}
