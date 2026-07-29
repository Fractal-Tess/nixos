{ pkgs, serverSource }:

let
  tesseractEnglish = pkgs.tesseract.override { enableLanguages = [ "eng" ]; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "firecrawl-pdf-ocr";
  tag = "local";
  contents = [
    pkgs.cacert
    pkgs.coreutils
    pkgs.poppler-utils
    pkgs.python3
    tesseractEnglish
  ];
  config = {
    Entrypoint = [
      "${pkgs.python3}/bin/python3"
      "${serverSource}"
    ];
    Env = [
      "PATH=${
        pkgs.lib.makeBinPath [
          pkgs.coreutils
          pkgs.poppler-utils
          tesseractEnglish
        ]
      }"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
    User = "65532:65532";
    WorkingDir = "/tmp";
  };
}
