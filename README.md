# SSL Generation Script
Bash script that generates a development certificate for use with servers. Intended for use within a cloudflare setup where the connection between the backend and the proxy requires a SSL connection to allow 443. 

This will generate an OpenSSL Self Signed Certificate with the following properties:

* Valid for:  370 Days
* RSA:2048 bit encryption
* .key & .crt files.

**Requirements**
 * openssl
   ```
    sudo apt-get update && sudo apt-get install openssl
   ```
 * nano
   ```
    sudo apt-get update && sudo apt-get install nano
   ```
---
## How To Use
1. Create a directory on the server to store the SSL cert files. We will use "/ssl-certs".

```
    sudo mkdir /ssl-certs
```

Then make it writable (required for cron task).
```
    sudo chown {{username e.g admin}}: /ssl-certs
```

2. Create a directory on the server to store the bash script that will generate the SSL. We will use "/scripts".

```
    sudo mkdir /scripts
```

3. Create the "ssl-generation.bash" script & paste the contents into the file.
```
    // Create File
    sudo nano /scripts/ssl-generation.bash

    // Pate in the contents
    Right Click + Paste
```

4. Edit the relevant information to match your needs.

```
    // -----------------------
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
    // -----------------------

    If you are not using NGINX. Comment out the following line
    # /etc/init.d/nginx reload
    
    // Exit the editor & Save
    ctrl + x
    y
```

5. Make the file executable.
```
    sudo chmod +x /scripts/ssl-generation.bash
```

6. Run the script.
```
    cd /scripts
    sudo ./ssl-generation.bash
```
---
### (Optional) Set up cronjob to renew certs once a year.
    
1 Open crontab in the editor of choice
```
    sudo crontab -e 

    // Choose Editor (nano is the easiest so lets use that)
    2
```
2 Set cronjob to run once a year
```
    0 0 1 1 * /bin/bash -c "/scripts/ssl-generation.bash"
```
3 Save Cron Job
```
    ctrl + x
    y
```
4. Make the ssl-certs directory writable by the cron.
```
    sudo chmod +x /ssl-certs
```

7.4 Success, The command will now run every year on January 1st.
7.5 (Optional) - Test the cron job 
```
    // Open crontab in nano
    sudo crontab -e 
    2

    // Set task to run every minute
    * * * * * /bin/bash -c "/scripts/ssl-generation.bash"

    // Save the job
    ctrl + x
    y

    // wait one minute
    // Check the system logs
    grep CRON /var/log/syslog

    // You should see the cron log from the script

    // Remove the cronjob
    sudo crontab -e

    // Save
    ctrl + x
    y
```
---
## Use With NGINX

Create dhparam file:
```
    sudo openssl dhparam -out /etc/nginx/dhparam.pem 4096
```

Create Config Snippet File:
```
    sudo nano /etc/nginx/snippets/self-signed.conf
```

Add properties:
```
    ssl_certificate /et##c/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
```

then save and exit.

Create SSL Params File:
```
    sudo nano /etc/nginx/snippets/ssl-params.conf
```

Add properties:
```
    ssl_protocols TLSv1.2;
    ssl_prefer_server_cipherson;
    ssl_dhparam /etc/nginx/dhparam.pem;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_ecdh_curve secp384r1; # Requires nginx >= 1.1.0
    ssl_session_timeout  10m;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off; # Requires nginx >= 1.5.9
    ssl_stapling on; # Requires nginx >= 1.3.7
    ssl_stapling_verify on; # Requires nginx => 1.3.7
    resolver 8.8.8.88.8.4.4 valid=300s;
    resolver_timeout 5s;
    # Disable strict transport security for now. You can uncomment the following
    # line if you understand the implications.
    # add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
```

then save and exit.

Once the above is complete simply add the following under "listen" within the NGINX server block:
```
    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        
        include snippets/self-signed.conf;
        include snippets/ssl-params.conf;
        
        server_name example.com www.example.com;
        
        root /var/www/example.com/html;
        index index.html index.htm index.nginx-debian.html;
        . . .
    }
```

Then restart NGINX
```
    sudo systemctl restart nginx
```

---
###  General Help 
**Cronjob fails without output**
This could be many issues, The best way to check what the issue is caused by is to check the syslog:
```
    // Open Syslog with only cron entries    
    grep CRON /var/log/syslog

    // Open the full log
    nano /var/log/syslog
```

**Permission Errors Within Cronjob**
This will happen when the cronjob is not run as root. It requires root privellages to write to the "/" dir and to reload the NGINX service.

To check the root cron list, Run the following command:
```
    sudo crontab -e
```
If the tasks are not there then del;ete them from the user cron list and add them to the root cronlist.

---
## Underlying Command
Information in this section was taken from the following [Digital Ocean Tutorial](https://www.digitalocean.com/community/tutorials/how-to-create-an-ssl-certificate-on-nginx-for-ubuntu-14-04)).

We will be running the following command:

```
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt
```

* **openssl**: This is the basic command line tool for creating and managing OpenSSL certificates, keys, and other files. 

* **req**: This subcommand specifies that we want to use X.509 certificate signing request (CSR) management. The "X.509" is a public key infrastructure standard that SSL and TLS adheres to for its key and certificate management. We want to create a new X.509 cert, so we are using this subcommand.

* **-x509**: This further modifies the previous subcommand by telling the utility that we want to make a self-signed certificate instead of generating a certificate signing request, as would normally happen.

* **-nodes**: This tells OpenSSL to skip the option to secure our certificate with a passphrase. We need Nginx to be able to read the file, without user intervention, when the server starts up. A passphrase would prevent this from happening because we would have to enter it after every restart.

* **-days 370**: This option sets the length of time that the certificate will be considered valid. We set it for one year here (Set to 370 as failsafe for leap years).

* **-newkey rsa:2048**: This specifies that we want to generate a new certificate and a new key at the same time. We did not create the key that is required to sign the certificate in a previous step, so we need to create it along with the certificate. The rsa:2048 portion tells it to make an RSA key that is 2048 bits long.

* **-keyout**: This line tells OpenSSL where to place the generated private key file that we are creating.

* **-out**: This tells OpenSSL where to place the certificate that we are creating.