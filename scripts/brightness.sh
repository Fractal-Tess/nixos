for bus in $(ddcutil detect | grep 'I2C bus' | awk '{print $3}' | sed 's/.*-//g'); do
  ddcutil --bus $bus setvcp 10 "$1"
done
