{ ... }: {
  programs.btop = {
    enable = true;
    settings = {
      update_ms = 1000;
      proc_sorting = "cpu_direct";
    };
  };
}
