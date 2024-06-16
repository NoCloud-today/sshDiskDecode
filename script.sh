#!/bin/bash

login=$(whoami)

ip_address=$(hostname -I | awk '{print $1}')

read -sp "Enter password: " password
echo

read -sp "Enter password for decryption: " password_for_decrypt

qr_text="$login\n$ip_address\n$password\n$password_for_decrypt"

echo -e "Current device IP address: $ip_address"
echo -e "Current user login: $login"

echo -e "$qr_text" | qrencode -o password_qr_code.png
echo "QR code with the information has been created."

