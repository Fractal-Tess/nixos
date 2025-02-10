{ lib, ... }:

with lib;

{
  config = {
    # Timezone
    time.timeZone = mkDefault "Europe/Sofia";
  };
}
