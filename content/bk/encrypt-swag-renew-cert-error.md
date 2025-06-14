---
title: "Swag renew certificate error"
date: 2025-01-04T21:56:40+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Notes]
#tags: [Swag,Letsencrypt]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Sau khi mang swag data sang 1 VM mới, mình đã mắc lỗi khiến certificate không thể renew..."
---

## Story

Sau khi backup sang VM mới. mình có mang swag data sang deploy container.

Gần đây phát hiện lỗi ko renew được.

```s
The cert is either expired or it expires within the next day. Attempting to renew. This could take up to 10 minutes.
<------------------------------------------------->

<------------------------------------------------->
cronjob running on Thu Oct 17 09:40:23 +07 2024
Running certbot renew
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Processing /etc/letsencrypt/renewal/DOMAINULD.duckdns.org.conf
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Renewal configuration file /etc/letsencrypt/renewal/DOMAINULD.duckdns.org.conf is broken.
The error was: expected /etc/letsencrypt/live/DOMAINULD.duckdns.org/cert.pem to be a symlink
Skipping.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
No renewals were attempted.
No hooks were run.

Additionally, the following renewal configurations were invalid:
  /etc/letsencrypt/renewal/DOMAINULD.duckdns.org.conf (parsefail)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
0 renew failure(s), 1 parse failure(s)
Ask for help or search for solutions at https://community.letsencrypt.org. See the logfile /var/log/letsencrypt/letsencrypt.log or re-run Certbot with -v for more details.
```

Do khi backup data sang VM mới mình bê hết data cert sang, **Mình ko tạo symlink**.

## Solution

Nên phải vào đây tạo lại symlink (command ln -s), tham khảo bên này: 

```sh
/opt/devops/swag/config/etc/letsencrypt/live/DOMAINULD.duckdns.org# ll
total 28
drwxr-xr-x 2 opc opc 4096 Aug 27 16:20 ./
drwx------ 3 opc opc 4096 Aug 27 16:20 ../
-rw-r--r-- 1 opc opc  692 Aug 27 16:20 README
lrwxrwxrwx 1 opc opc   50 Aug 27 16:20 cert.pem -> ../../archive/DOMAINULD.duckdns.org/cert1.pem
lrwxrwxrwx 1 opc opc   51 Aug 27 16:20 chain.pem -> ../../archive/DOMAINULD.duckdns.org/chain1.pem
lrwxrwxrwx 1 opc opc   55 Aug 27 16:20 fullchain.pem -> ../../archive/DOMAINULD.duckdns.org/fullchain1.pem
-rw-r--r-- 1 opc opc 7224 Aug 27 16:20 priv-fullchain-bundle.pem
lrwxrwxrwx 1 opc opc   53 Aug 27 16:20 privkey.pem -> ../../archive/DOMAINULD.duckdns.org/privkey1.pem
-rw------- 1 opc opc 5637 Aug 27 16:20 privkey.pfx

```

Sau khi sửa lại symlink (bằng command `ln -s`), restart swag, thì renew vẫn lỗi:

```s
Using Let's Encrypt as the cert provider
SUBDOMAINS entered, processing
Wildcard cert for only the subdomains of DOMAINULD.duckdns.org will be requested
E-mail address entered: DOMAINULD@gmail.com
duckdns validation is selected
the resulting certificate will only cover the subdomains due to a limitation of duckdns, so it is advised to set the root location to use www.subdomain.duckdns.org
Certificate exists; parameters unchanged; starting nginx
cont-init: info: /etc/cont-init.d/50-certbot exited 0
cont-init: info: running /etc/cont-init.d/55-permissions
cont-init: info: /etc/cont-init.d/55-permissions exited 0
cont-init: info: running /etc/cont-init.d/60-renew
The cert is either expired or it expires within the next day. Attempting to renew. This could take up to 10 minutes.
<------------------------------------------------->

<------------------------------------------------->
cronjob running on Thu Oct 17 13:56:05 +07 2024
Running certbot renew
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Processing /etc/letsencrypt/renewal/DOMAINULD.duckdns.org.conf
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Found a new certificate /archive/ that was not linked to in /live/; fixing...

Renewing an existing certificate for *.DOMAINULD.duckdns.org
Hook '--manual-auth-hook' for DOMAINULD.duckdns.org ran with output:
 OKsleeping 60
Hook '--manual-auth-hook' for DOMAINULD.duckdns.org ran with error output:
 % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                  Dload  Upload   Total   Spent    Left  Speed

   0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
   0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
 100     2    0     2    0     0      5      0 --:--:-- --:--:-- --:--:--     5

Certbot failed to authenticate some domains (authenticator: manual). The Certificate Authority reported these problems:
  Domain: DOMAINULD.duckdns.org
  Type:   unauthorized
  Detail: Incorrect TXT record "uhX3_XXXXXXfHw" found at _acme-challenge.DOMAINULD.duckdns.org

Hint: The Certificate Authority failed to verify the DNS TXT records created by the --manual-auth-hook. Ensure that this hook is functioning correctly and that it waits a sufficient duration of time for DNS propagation. Refer to "certbot --help manual" and the Certbot User Guide.

Failed to renew certificate DOMAINULD.duckdns.org with error: Some challenges have failed.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
All renewals failed. The following certificates could not be renewed:
  /etc/letsencrypt/live/DOMAINULD.duckdns.org/fullchain.pem (failure)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
1 renew failure(s), 0 parse failure(s)
Ask for help or search for solutions at https://community.letsencrypt.org. See the logfile /var/log/letsencrypt/letsencrypt.log or re-run Certbot with -v for more details.

```

Restart swag, Run lại 1 lần nữa thì thành công:

```s
The cert is either expired or it expires within the next day. Attempting to renew. This could take up to 10 minutes.
<------------------------------------------------->

<------------------------------------------------->
cronjob running on Thu Oct 17 14:10:35 +07 2024
Running certbot renew
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Processing /etc/letsencrypt/renewal/DOMAINULD.duckdns.org.conf
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Renewing an existing certificate for *.DOMAINULD.duckdns.org
Hook '--manual-auth-hook' for DOMAINULD.duckdns.org ran with output:
 OKsleeping 60
Hook '--manual-auth-hook' for DOMAINULD.duckdns.org ran with error output:
 % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                  Dload  Upload   Total   Spent    Left  Speed

   0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
 100     2    0     2    0     0      5      0 --:--:-- --:--:-- --:--:--     5

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Congratulations, all renewals succeeded:
  /etc/letsencrypt/live/DOMAINULD.duckdns.org/fullchain.pem (success)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

```

Vào check lại chỗ symlink thấy swag đã tự động tạo các cert thứ 8 như này:
```sh
/opt/devops/swag/config/etc/letsencrypt/live/DOMAINULD.duckdns.org# ll
total 32
drwxrwxr-x 3 opc opc 4096 Oct 17 07:15 ./
drwxrwxr-x 3 opc opc 4096 Jul 24 17:00 ../
-rwxrwxr-x 1 opc opc  692 Jul 24 17:00 README*
lrwxrwxrwx 1 opc opc   50 Oct 17 07:15 cert.pem -> ../../archive/DOMAINULD.duckdns.org/cert8.pem
lrwxrwxrwx 1 opc opc   51 Oct 17 07:15 chain.pem -> ../../archive/DOMAINULD.duckdns.org/chain8.pem
lrwxrwxrwx 1 opc opc   55 Oct 17 07:15 fullchain.pem -> ../../archive/DOMAINULD.duckdns.org/fullchain8.pem
-rwxrwxr-x 1 opc opc 7224 Oct 17 07:15 priv-fullchain-bundle.pem*
lrwxrwxrwx 1 opc opc   53 Oct 17 07:15 privkey.pem -> ../../archive/DOMAINULD.duckdns.org/privkey8.pem*
-rwxrwxr-x 1 opc opc 5645 Oct 17 07:15 privkey.pfx*
```


