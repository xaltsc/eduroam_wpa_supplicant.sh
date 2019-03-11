#!/bin/bash

print_help(){
  echo "lol"
}

wpa_dir=/etc/wpa_supplicant
config_file=""
user=""
pswd=""

while getopts "hvc:d:u:p:" opt; do
  case $opt in
    [h\?]) print_help
      exit 0;;
    v) VERBOSE=1;;
    c) config_file="$OPTARG";;
    d) wpa_dir="$OPTARG";;
    u) user="$OPTARG";;
    p) pswd="$OPTARG";;
  esac
done

if [ -z "$config_file" ]; then
  echo "An eap-config file should be provided through the '-c' option."
  print_help
  exit 1
fi

ssid="$(xml sel -t -v //SSID $config_file)"
key_mgmt="WPA-EAP"
eap="PEAP"
phase2="auth=MSCHAPV2"

[ -z "$user" ] && read -p "username: " user
[ -z "$pswd" ] && read -rsp "password: " pswd

hashed_pswd="$(echo -n $pswd | iconv -t utf16le | openssl md4 | sed 's/.*= //')"

endcertif="-----END CERTIFICATE-----"
begincertif="-----BEGIN CERTIFICATE-----"

xml sel -t -v //CA $config_file | sed -e"/^/ i$begincertif" -e"/^/ a$endcertif" > $wpa_dir/ca-$user.pem

newnetwork="network={
  ssid=\"$ssid\"
  key_mgmt=$key_mgmt
  eap=$eap
  ca_cert=$wpa_dir/ca-$user.pem
  identity=$user
  phase2=$phase2
  password=\"hash:$hashed_pswd\"
}"

echo "${newnetwork}" >> $wpa_dir/wpa_supplicant.conf
