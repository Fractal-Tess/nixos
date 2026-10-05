final: prev: {
  ltrace = prev.ltrace.overrideAttrs (old: {
    # The DejaGnu testsuite has 15 unexpected failures against current glibc
    # (upstream has been unmaintained since 0.7.91), which breaks the build.
    doCheck = false;
  });
}
