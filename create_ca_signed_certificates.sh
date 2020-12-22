#!/bin/bash
#
# Author: Sandor Gered sandor.gered at protonmail.com
# Brief:  Creates a root certificate to become a Certificate Authority
#         Then creates and sign certificates using your own Certificate Authority
# Date:   2020-05-30


### You have to fill in these parameters to be able to use this script
### See below the instructions:

## path of your root certificate the path must exist, ex:
##ca_path="/home/johnny/certs"
ca_path=""

## file name of root certificate
## if you don't have a root certificate, it's time to create it,
## just put a your.name here which and ends it in ".ca", ex:
##ca_name="john.doe.ca"
ca_name=""

## Your ISO 3166-1 alpha-2 country code, 2 digits
country=""

## Your two letter county code
state=""

## Your locality
locality=""

## Your organization name, ex:
##organization="My super smart ltd"
organization=""

## Department, ex:
##organization_unit="It Security Dept"
organization_unit=""

## Your name, ex:
##common_name="John Doe"
common_name=""

## Your email:
email=""

### No need to change any other thing after this line


validate_param () {
    if [[ -z $2 ]]; then
        echo "Please fill in $1"
        exit
    fi
}

# Validate parameters:
validate_param "ca_path" $ca_path
validate_param "ca_name" $ca_name
validate_param "country" $country
validate_param "state" $state
validate_param "locality" $locality
validate_param "organization" $organization
validate_param "organization_unit" $organization_unit
validate_param "common_name" $common_name
validate_param "email" $email

execname=`basename $0`

if [ "$#" -eq 0 ]; then
    echo "Usage1: ${execname} gen-cert domain ip"
    echo "      Generates a signed certificate using Certificate Authority ${ca_name}"
    echo "      The CA certificate must be located in ${ca_path}"
    echo "      Example:"
    echo "          ${execname} gen-cert my-smart-site.com 192.168.0.16"
    echo "Usage2: ${execname} gen-ca"
    echo "      Generates root certificate to become a Certificate Authority"
    echo "      Example:"
    echo "          ${execname} gen-ca"
    echo "      Will result in creating ./${ca_name}.key and ./${ca_name}.pem"
    exit 1
fi

if [ "$1" != "gen-cert" ] && [ "$1" != "gen-ca" ]; then
    echo "param 1 is invalid"
    exit 1
fi


if [ "$1" = "gen-ca" ]; then
    if [ "$#" -ne 1 ]; then
        echo "wrong parameters count, try ${execname} with no params!"
        exit 1
    fi
    if test -f "./${ca_name}.key" || test -f "./${ca_name}.pem"; then
        echo "./${ca_name}.key or ./${ca_name}.key already exists!"
        exit 1
    fi
    echo "creating the private key for CA '${ca_name}.key'..."
    openssl genrsa -des3 -out ${ca_name}.key 2048
    echo

    echo "creating the root certificate '${ca_name}.pem'..."
    openssl req -x509 -new -nodes -key ${ca_name}.key -sha256 -days 1825 -out ${ca_name}.pem \
         -subj "/C=${country}/ST=${state}/L=${locality}/O=${organization} Signing Authority/CN=${common_name}"

    echo "testing ${ca_name}.pem..."
    openssl x509 -noout -text -in ${ca_name}.pem
    exit 0
else
    if [ "$#" -ne 3 ]; then
        echo "wrong params count, needs 3, run ${execname} with no params!"
        exit 1
    fi
fi


#
# Now try to create and sign a certificate using my Certificate Authority
#

domain=$2
ip=$3

echo "testing preconditions..."
if test -f "{domain}.key" || test -f "${domain}.pem" || test -f "${domain}.crt" || test -f "${domain}.ext"; then
    echo "${domain} .key or .pem or .csr or .ext already exist in the current dir! Aborting..."
    exit 1
fi

echo "Generating private key for your domain ${domain}..."
openssl genrsa -out ${domain}.key 2048

echo
echo "Creating a certificate sign request (CSR), to define subject alternative name (SAN)..."
openssl req -new -key ${domain}.key -out ${domain}.csr \
    -subj "/C=${country}/ST=${state}/L=${locality}/O=${organization}/OU=${organization_unit}/CN=${common_name}/emailAddress=${email}"
echo "${domain}.csr generated"


ext_file_name=${domain}.ext
echo
echo "generating config file ${ext_file_name} needed to certificate creation..."
echo "authorityKeyIdentifier=keyid,issuer"   >${ext_file_name}
echo "basicConstraints=CA:FALSE"            >>${ext_file_name}
echo "keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment" >>${ext_file_name}
echo "subjectAltName = @alt_names"          >>${ext_file_name}
echo                        >>${ext_file_name}
echo "[alt_names]"          >>${ext_file_name}
echo "DNS.1 = ${domain}"    >>${ext_file_name}

# Important for ESP8266 users! 
# By adding ip address to DNS list, BearSSL, will recognize ip address too as a DNS name and won't fail the handshake
# Long story short: this way we will be able to connect to the server using BearSSL::WiFiClientSecure::connect(name, port) method
# having set in name parameter any of server's DNS and ip as string.
# Without the line below the method connect("192.168.0.250", 443) will fail due to this error:
# Couldn't connect. Error = Expected server name was not found in the chain.
echo "DNS.2 = ${ip}"        >>${ext_file_name}
echo "IP.1  = ${ip}"        >>${ext_file_name}

echo
echo "creating the certificate for ${domain}..."
openssl x509 -req -in ${domain}.csr -CA ${ca_path}/${ca_name}.pem -CAkey ${ca_path}/${ca_name}.key -CAcreateserial \
    -out ${domain}.crt -days 825 -sha256 -extfile ${ext_file_name}
echo "${domain}.crt created"

echo
echo "reviewing ${domain}.crt..."
openssl x509 -noout -text -in ${domain}.crt

echo
echo "  Now that the certificate is ready, follow these steps:"
echo "  1) Move on the machine which deserves ${domain}:"
echo "      - the private key '${domain}.key'"
echo "      - the certificate '${domain}.crt'"
echo "      - optional all other '${domain}.*'"
echo "     in a safe place. Then start the webserver using"
echo "     .key and .crt credentials"
echo "  2) On the client side (browser, SHD-device), you just"
echo "     have to install the certificate ${ca_name}.pem"
echo "     which comes from CA, who have just signed this"
echo "     certificate. This step should be executed only"
echo "     once. If you already did it, just skip 2)"
echo "  Have fun!"
echo
echo "  @sanya 2020 may 29"
echo ""
echo "  Known issues:"
echo "  Domoticz complaints about the missing SSL DH parameter."
echo "  Two possibilities are available:"
echo "      1)  $ sudo openssl dhparam -out dhparam.pem 2048"
echo "          $ sudo cat dhparam.pem >> server_cert.pem"
echo "          $ sudo /etc/init.d/domoticz.sh restart"
echo "          The problem is, it takes ~45 minutes long..."
echo "      2)  copy from domoticz/server_cert.pem the section"
echo "          'DH PARAMETERS' and append it in our new .pem file"
echo "          Then restart domoticz"
