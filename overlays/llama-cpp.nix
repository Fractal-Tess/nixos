final: prev:
let
  version = "8797";
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
          hash = "sha256-2W8rW0rlQc/foE+fnw5O0a9cqaiNL0Ie2Oi915jqtSQ=";
          leaveDotGit = true;
          postFetch = ''
            git -C "$out" rev-parse --short HEAD > "$out/COMMIT"
            find "$out" -name .git -print0 | xargs -0 rm -rf
          '';
        };
        npmDepsHash = "sha256-RAFtsbBGBjteCt5yXhrmHL39rIDJMCFBETgzId2eRRk=";
        cmakeFlags =
          let
            keepFlag = flag: !(final.lib.hasInfix "CMAKE_CUDA_ARCHITECTURES" flag);
          in
          (builtins.filter keepFlag old.cmakeFlags)
          ++ [ (final.lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" "61;86") ];
      });
}
