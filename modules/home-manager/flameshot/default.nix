{ ... }: {
  services.flameshot = {
    enable = true;
    settings = {
      General = {
        savePath = "/home/fractal-tess/stuff/screenshots/";
        savePathFixed = true;
        saveAsFileExtension = ".jpg";
        disabledTrayIcon = false;
        saveAfterCopy = true;
        copyPathAfterSave = true;
        copyAndCloseAfterUpload = true;
        uploadWithoutConfirmation = true;
      };
    };
  };
}
