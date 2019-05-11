#!/bin/bash

# Core Settings
certName={{ Name of the cert file e.g. devSSL }}
domain={{ Domain name or IP of the server e.g. 192.168.0.12 }}
location={{ Location to store the geenrated files e.g "/ssl-certs" }}

# Company Details
country={{ e.g GB }}
state={{ e.g Glasgow }}
locality={{e.g. Lanarkshire }}
organization={{ e.g. Huskii }}
organizationalunit={{ e.g. Development }}
email={{ e.g. test@domain.com }}


# Failsafe
if [ -z "$certName" ]
then 
    echo "Cert Name not provided"
    exit 99
fi

if [ -z "$domain" ]
then 
    echo "Domain not provided"
    exit 99
fi

# Generate Key
echo "Generating $certName for $domain"

openssl req -x509 -nodes -days 370 -newkey rsa:2048 -keyout $location/$certName.key -out $location/$certName.crt \
    -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$domain/emailAddress=$email"

# Restart NGINX
/etc/init.d/nginx reload

# Log Out Succes
echo "-------------------"
echo "SSL Created Successfully"
echo "For: $domain"
echo "Output Location: $location"
echo "-------------------"