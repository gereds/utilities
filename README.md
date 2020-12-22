# Utilities
This is my collection of  utilities created to simplify our lifes

## create_ca_signed_certificates.sh
You have a server with https access and you use your self signed certificates. The browser always complains that your site is not secure. With this script you can become a Certificate Authority, then you'll be able to generate and sign any number of certificates.
Edit the script and fill in the needed variables, as described there. When you are ready with is, just run the script with no parameters and follow the instructions on the screen.

## create_public_private_keys.sh
You access frequently the remote linux server B from machine A, but you'd prefer to login using private/public keys and forget the password. Just download this script to machine A, run it with no parameters and follow the instruction.
It creates the private/public keys, install them and create an alias for you. You'll love it.

## License
Unlicense
