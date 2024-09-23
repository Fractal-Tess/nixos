{ ... }: {

  services.flameshot = {
    enable = true;
    settings = {
      General = {
        savePath = "/mnt/vault/Screenshots";
        savePathFixed = true;
        saveAsFileExtension = ".jpg";
        disabledTrayIcon = false;
        saveAfterCopy = true;
        copyPathAfterSave = true;
        uploadWithoutConfirmation = true;
      };
    };
  };
}
