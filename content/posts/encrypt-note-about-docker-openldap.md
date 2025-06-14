---
title: "Notes About Docker OpenLDAP"
date: 2023-02-08T23:10:28+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Notes]
tags: [OpenLDAP]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "This is just my notes when playaround with OpenLDAP"
---

Nếu bạn đang quản lý nhiều application nhưng mỗi app lại có 1 database riêng để lưu trữ user/password,

bạn sẽ cần phải nhớ rất nhiều user/password cho mỗi app. Sau khi đổi password thì lại càng loạn hơn.

Để giải quyết, bạn sẽ muốn chỉ dùng 1 database cho user/password, tất cả application sẽ chọc vào 1 database đó để xác thực user.

Có nhiều phần mềm để thực hiện việc đó, trong đó thì OpenLDAP là 1 open-source rất hay, phù hợp cho các application nội bộ, số lượng user nhỏ.

Bên cạnh OpenLDAP thì còn có Azure Active Directory, AWS Cognito, Auth0, Keycloak,...etc

Bài này mình sẽ chỉ nói về OpenLDAP thôi vì nó free. Tuy nhiên tương lai mình cũng muốn tìm hiểu về Auth0 nữa vì thấy nhiều người recommend.
(Còn AWS Cognito thì mình đã có 1,2 bài nói về nó rồi - apply vào ReactJS Gatsby framework)

# 1. Install

Cài đặt OpenLDAP trong bài này mình sẽ dùng Docker: https://github.com/osixia/docker-openldap

Và guidline mình follow để config OpenLDAP thì ở đây: https://doc.digdash.com/xwiki/wiki/dd2022r2/view/Digdash/deployment/installation/install_guide_ubuntu/...  

Vì mình lấy credit từ document của Digdash nên Nên `digdash` sẽ được dùng xuyên suốt trong bài, bạn có thể sửa thành `digdash` thành bất cứ thứ gì bạn muốn

Chuẩn bị biến môi trường để sử dụng trong bài này:  

```sh
export LDAP_ADMIN_PASSWORD="Abcd1234"
```

Chuẩn bị thư mục, các file ldif chưa có cứ bỏ qua:  

```
.
|__docker-compose.yml
|__docker-resources
  |__openldap
    |__database
    |__config
    |__ldif-custom
      |__ppolicy-module.ldif
      |__ppolicy-conf.ldif
      |__ppolicy-defaut.ldif
      |__neworganisation.ldif
      |__create_user_admin.ldif
      |__add_right_admin.ldif
      |__extend_limit_search.ldif
      |__increase_mem.ldif
```

File `docker-compose.yml`:  

```yml
version: '3'

services:
  openldap-server:
    container_name: openldap-server
    image: osixia/openldap:1.5.0
    restart: unless-stopped
    stdin_open: true
    tty: true
    ports:
    - "11389:389"
    environment:
    - LDAP_ORGANISATION=abc
    - LDAP_DOMAIN=digdash.com
    - LDAP_ADMIN_PASSWORD=$LDAP_ADMIN_PASSWORD
    - LDAP_BASE_DN=dc=digdash,dc=com
    volumes:
    - ./docker-resources/openldap/database:/var/lib/ldap            # Nếu muốn persist data thì chuẩn bị các folder này
    - ./docker-resources/openldap/config:/etc/ldap/slapd.d          # Nếu muốn persist data thì chuẩn bị các folder này
    - ./docker-resources/openldap/ldif-custom:/etc/ldap/ldif-custom # Nếu muốn execute các file ldif thì đặt ở đây
```

Chú ý volume `/etc/ldap/ldif-custom` sẽ chứa các file ldif để sau này mình run config lại với openLDAP

Mặc dù ở [đây](https://github.com/osixia/docker-openldap#seed-ldap-database-with-ldif) có hướng dẫn để seed các file ldif vào luôn, nhưng mình thấy nó ko thể sắp xếp thứ tự execute của các file ldif đó nên mình ko dùng.

Thay vào đó sau khi `docker-compose up -d` xong, mình sẽ run command để chạy 1 shell script, execute các ldif file.

Run:  

```sh
docker-compose up -d

# check xem có log lỗi ko
docker logs openldap-server
```

# 2. Run some commands with ldap daemon

Giờ ssh vào trong container để execute các file ldif file:  

```sh
docker exec -it openldap-server /bin/bash
cd /etc/ldap/ldif-custom
```

## Add ppolicy module

Check xem `ppolicy` module đã được add vào chưa, như này là ok:  
```
root@4366cd65ca46:/# ldapsearch -Y EXTERNAL -s one -H ldapi:/// -b cn=schema,cn=config cn -LLL
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
dn: cn={0}core,cn=schema,cn=config
cn: {0}core

dn: cn={1}cosine,cn=schema,cn=config
cn: {1}cosine

dn: cn={2}nis,cn=schema,cn=config
cn: {2}nis

dn: cn={3}inetorgperson,cn=schema,cn=config
cn: {3}inetorgperson

dn: cn={4}ppolicy,cn=schema,cn=config
cn: {4}ppolicy

dn: cn={5}kopano,cn=schema,cn=config
cn: {5}kopano

dn: cn={6}openssh-lpk,cn=schema,cn=config
cn: {6}openssh-lpk

dn: cn={7}postfix-book,cn=schema,cn=config
cn: {7}postfix-book

dn: cn={8}samba,cn=schema,cn=config
cn: {8}samba
```

Nếu chưa thấy `ppolicy` được add thì dùng command này để add:  

```sh
root@4366cd65ca46:/# ldapmodify -a -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/ppolicy.ldif
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
adding new entry "cn=ppolicy,cn=schema,cn=config"
```

## Activate module ppolicy then verify

File `ppolicy-module.ldif`:  

```
dn: cn=module{0},cn=config
changeType: modify
add: olcModuleLoad
olcModuleLoad: ppolicy
```

Run command:  

```sh
# Run
root@4366cd65ca46:/etc/ldap/ldif-custom# ldapmodify -Y EXTERNAL -H ldapi:/// -f ppolicy-module.ldif
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "cn=module{0},cn=config"

# Verify
root@4366cd65ca46:/etc/ldap/ldif-custom# ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(objectClass=olcModuleList)" olcModuleLoad -LLL
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
dn: cn=module{0},cn=config
olcModuleLoad: {0}back_mdb
olcModuleLoad: {1}memberof
olcModuleLoad: {2}refint
olcModuleLoad: {3}ppolicy
```

## Config hash password của các user

File `ppolicy-conf.ldif`:  

```
dn: olcOverlay=ppolicy,olcDatabase={1}mdb,cn=config
objectClass: olcPpolicyConfig
olcOverlay: ppolicy
olcPPolicyDefault: cn=ppolicy,dc=digdash,dc=com
olcPPolicyUseLockout: TRUE
olcPPolicyHashCleartext: TRUE
```

Run command:  

```sh
# Before 
root@4366cd65ca46:/etc/ldap/ldif-custom# ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(objectClass=olcPpolicyConfig)" -LLL
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0

# Run
root@4366cd65ca46:/etc/ldap/ldif-custom# ldapmodify -a -Y EXTERNAL -H ldapi:/// -f ppolicy-conf.ldif
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
adding new entry "olcOverlay=ppolicy,olcDatabase={1}mdb,cn=config"

# Verify
root@4366cd65ca46:/etc/ldap/ldif-custom# ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(objectClass=olcPpolicyConfig)" -LLL
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
dn: olcOverlay={2}ppolicy,olcDatabase={1}mdb,cn=config
objectClass: olcPPolicyConfig
olcOverlay: {2}ppolicy
olcPPolicyDefault: cn=ppolicy,dc=digdash,dc=com
olcPPolicyHashCleartext: TRUE
olcPPolicyUseLockout: TRUE
```

## Define password policy

File `ppolicy-defaut.ldif` sẽ define user password cần tuân thủ những policy gì:  

```
dn: cn=ppolicy,dc=digdash,dc=com
objectClass: device
objectClass: pwdPolicyChecker
objectClass: pwdPolicy
cn: ppolicy
pwdAllowUserChange: TRUE
pwdAttribute: userPassword
pwdCheckQuality: 1
pwdExpireWarning: 600
pwdFailureCountInterval: 30
pwdGraceAuthNLimit: 5
pwdInHistory: 5
pwdLockout: TRUE
pwdLockoutDuration: 900
pwdMaxAge: 0
pwdMaxFailure: 5
pwdMinAge: 0
pwdMinLength: 12
pwdMustChange: FALSE
pwdSafeModify: FALSE
```

Run command:  

```sh
# Before 
root@4366cd65ca46:/etc/ldap/ldif-custom# ldapsearch -Y EXTERNAL -H ldapi:/// -b dc=digdash,dc=com "(objectClass=pwdPolicy)" -LLL
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0


# Run command
root@4366cd65ca46:/etc/ldap/ldif-custom# ldapmodify -x -a -H ldap://localhost -D cn=admin,dc=digdash,dc=com -f ppolicy-defaut.ldif -w Abcd1234
adding new entry "cn=ppolicy,dc=digdash,dc=com"


# Verify
root@4366cd65ca46:/etc/ldap/ldif-custom# ldapsearch -Y EXTERNAL -H ldapi:/// -b dc=digdash,dc=com "(objectClass=pwdPolicy)" -LLL
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
dn: cn=ppolicy,dc=digdash,dc=com
objectClass: device
objectClass: pwdPolicyChecker
objectClass: pwdPolicy
cn: ppolicy
pwdAllowUserChange: TRUE
pwdAttribute: userPassword
pwdCheckQuality: 1
pwdExpireWarning: 600
pwdFailureCountInterval: 30
pwdGraceAuthNLimit: 5
pwdInHistory: 5
pwdLockout: TRUE
pwdLockoutDuration: 900
pwdMaxAge: 0
pwdMaxFailure: 5
pwdMinAge: 0
pwdMinLength: 12
pwdMustChange: FALSE
pwdSafeModify: FALSE
```

## Create a new organization

File `neworganisation.ldif` dùng để tạo mới organization tên là `ou=default,dc=digdash,dc=com`:  

```
dn: ou=default,dc=digdash,dc=com
objectClass: organizationalUnit
ou: default
```

Run command:  

```sh
# Run
root@4366cd65ca46:/etc/ldap/ldif-custom# ldapadd -H ldap://localhost -D cn=admin,dc=digdash,dc=com -x -f neworganisation.ldif -w Abcd1234
adding new entry "ou=default,dc=digdash,dc=com"

# Verify
root@4366cd65ca46:/etc/ldap/ldif-custom# ldapsearch -x -H ldap://localhost -b dc=digdash,dc=com -D "cn=admin,dc=digdash,dc=com" -w Abcd1234
# extended LDIF
#
# LDAPv3
# base <dc=digdash,dc=com> with scope subtree
# filter: (objectclass=*)
# requesting: ALL
#

# digdash.com
dn: dc=digdash,dc=com
objectClass: top
objectClass: dcObject
objectClass: organization
o: loamics
dc: digdash

# ppolicy, digdash.com
dn: cn=ppolicy,dc=digdash,dc=com
objectClass: device
objectClass: pwdPolicyChecker
objectClass: pwdPolicy
cn: ppolicy
pwdAllowUserChange: TRUE
pwdAttribute: userPassword
pwdCheckQuality: 1
pwdExpireWarning: 600
pwdFailureCountInterval: 30
pwdGraceAuthNLimit: 5
pwdInHistory: 5
pwdLockout: TRUE
pwdLockoutDuration: 900
pwdMaxAge: 0
pwdMaxFailure: 5
pwdMinAge: 0
pwdMinLength: 12
pwdMustChange: FALSE
pwdSafeModify: FALSE

# default, digdash.com
dn: ou=default,dc=digdash,dc=com
objectClass: organizationalUnit
ou: default

# search result
search: 2
result: 0 Success

# numResponses: 4
# numEntries: 3
```

## Create an admin user with the right

File `create_user_admin.ldif` để tạo mới 1 user với uid `admin_default`:  

```
dn: uid=admin,ou=default,dc=digdash,dc=com
objectClass: shadowAccount
objectClass: inetOrgPerson
cn: Admin Domain Default
sn: Default
uid: admin_default
```

Run command:    

```sh
root@4366cd65ca46:/etc/ldap/ldif-custom# ldapadd -H ldap://localhost -D cn=admin,dc=digdash,dc=com -x -f create_user_admin.ldif -w Abcd1234
adding new entry "uid=admin,ou=default,dc=digdash,dc=com"
```

## Add admin right

File `add_right_admin.ldif` để grant quyền cho user:  

```
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcaccess: {0}to dn.subtree=ou=default,dc=digdash,dc=com attrs=userpassword,shadowlastchange by dn.exact=uid=admin,ou=default,dc=digdash,dc=com write by self write by anonymous auth by * read
olcaccess: {1}to dn.subtree=ou=default,dc=digdash,dc=com  by dn.exact=uid=admin,ou=default,dc=digdash,dc=com write by * read
```

Run command:  

```sh
# Run
root@4366cd65ca46:/etc/ldap/ldif-custom# ldapmodify -a -Y EXTERNAL -H ldapi:/// -f add_right_admin.ldif
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "olcDatabase={1}mdb,cn=config"

```

## Set new password for uid=admin,ou=default,dc=digdash,dc=com

```sh
root@4366cd65ca46:/etc/ldap/ldif-custom# ldappasswd -H ldap://localhost -x -D "cn=admin,dc=digdash,dc=com" -S "uid=admin,ou=default,dc=digdash,dc=com" -w Abcd1234
New password:
Re-enter new password:
```

## Extend the 500 limit for LDAP searches

File `extend_limit_search.ldif` để extend giới hạn search của ldap:  

```
dn: olcDatabase={-1}frontend,cn=config
changetype: modify
replace: olcSizeLimit
olcSizeLimit: 3000
```

Run command:  

```sh
root@4366cd65ca46:/etc/ldap/ldif-custom# ldapmodify -a -Y EXTERNAL -H ldapi:/// -f extend_limit_search.ldif
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "olcDatabase={-1}frontend,cn=config"
```

## Increase MDB database memory to 10GB

File `increase_mem.ldif` để tăng giới hạn của DB MDB:  

```
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcDbMaxSize
olcDbMaxSize: 10000000000
```

Run command:  

```sh
# Run
root@4366cd65ca46:/etc/ldap/ldif-custom# ldapmodify -H ldapi:/// -Y EXTERNAL -f increase_mem.ldif
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "olcDatabase={1}mdb,cn=config"

```

## List all group and users trong openldap

```sh
ldapsearch -x -b dc=digdash,dc=com -D "cn=admin,dc=digdash,dc=com" -w Abcd1234
```

## List a specific user identified by uid=hoangdocker

```sh
ldapsearch -x -b dc=digdash,dc=com -D "cn=admin,dc=digdash,dc=com" '(uid=hoangdocker)' -w Abcd1234
```

## Change password user

Trước tiên hãy list user đó ra bằng command bên trên để biết các thông số khác của user đó, như ou,dc là gì, sau đó thì change password như sau:

```sh
ldappasswd -H ldapi:/// -x -D "cn=admin,dc=digdash,dc=com" -w Abcd1234 -S uid=hoangdocker,ou=users,dc=digdash,dc=com
New password:
Re-enter new password:
```

## Check các user và password đã encrypted của chúng trong cn=config

```sh
ldapsearch -LLL -Y EXTERNAL -H ldapi:/// -b cn=config
```

Find the RootDN account and the current RootDN password hash:
(theo https://www.digitalocean.com/community/tutorials/how-to-change-account-passwords-on-an-openldap-server)  

```sh
root@ded2e404d270:/#  ldapsearch -H ldapi:// -LLL -Q -Y EXTERNAL -b "cn=config" "(olcRootDN=*)" dn olcRootDN olcRootPW
dn: olcDatabase={0}config,cn=config
olcRootDN: cn=admin,cn=config
olcRootPW: {SSHA}kDomIgiYEPYYe2tJRrLkFO4jxrayzt0n

dn: olcDatabase={1}mdb,cn=config
olcRootDN: cn=admin,dc=digdash,dc=com
olcRootPW: {SSHA}bq06veDempYLWI3VgWGO10mFaaPhxiwk
```

## Create a password hashed

https://tech.feedyourhead.at/content/openldap-set-config-admin-password

```sh
slappasswd -h {SSHA}
```

# Issue của Digdash và OpenLDAP

Khi mình muốn Thay đổi password của user admin. Mình tiến hành list các user có uid=admin ra:  

```sh
ldapsearch -x -b dc=digdash,dc=com -D "cn=admin,dc=digdash,dc=com" '(uid=admin)' -w Abcd1234

# admin, default, digdash.com
dn: uid=admin,ou=default,dc=digdash,dc=com
objectClass: shadowAccount
objectClass: inetOrgPerson
cn: Admin Domain Default
sn: Default
uid: admin_default
uid: admin
userPassword:: e1NTSEF9MVJhckpidkZMaFNudHJsZzQya0JFMHpCWlg3a3pEMlA=

# admin, users, digdash.com
dn: uid=admin,ou=users,dc=digdash,dc=com
uid: admin
description:: ...
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
sn: admin
cn: admin
userPassword:: e1NTSEF9cnJiTUJmOFRiL2d5TVRPc25tbE1WYVBBZjlITFVWQXQ=
```

=> là `uid=admin,ou=default,dc=digdash,dc=com` và `uid=admin,ou=users,dc=digdash,dc=com`

Nếu chỉ đổi password của `uid=admin,ou=users,dc=digdash,dc=com` thì sẽ có lỗi là login vào được bằng cả admin/admin và admin/New_Password

-> Nên mình thử đổi pass của cả 2 admin user đó:

```sh
ldappasswd -H ldapi:/// -x -D "cn=admin,dc=digdash,dc=com" -w Abcd1234 -S uid=admin,ou=users,dc=digdash,dc=com
-> thành Abcd1234u

ldappasswd -H ldapi:/// -x -D "cn=admin,dc=digdash,dc=com" -w Abcd1234 -S uid=admin,ou=default,dc=digdash,dc=com
-> thành Abcd1234d -> ko ăn thua, ko login với password này được
```

-> vẫn login vào bằng cả admin/admin và admin/Abcd1234u

-> phải lên http://DNS:8080/ddenterpriseapi/serversettings

thì mới sửa được cái password admin/admin, nhưng vẫn login được bằng admin/Abcd1234u

-> Đây là known issue của OpenLDAP: https://github.com/osixia/docker-openldap/issues/161

**Cách giải quyết**

Delete admin user (uid=admin,ou=users,dc=digdash,dc=com) in LDAP server:  

```sh
ldapdelete -x -D "cn=admin,dc=digdash,dc=com" -w Abcd1234 uid=admin,ou=users,dc=digdash,dc=com
```

Delete admin user (uid=admin,ou=default,dc=digdash,dc=com) in LDAP server:  

```sh
ldapdelete -x -D "cn=admin,dc=digdash,dc=com" -w Abcd1234 uid=admin,ou=default,dc=digdash,dc=com
```

Như vậy LDAP sẽ ko có user admin, sẽ chỉ có password được encrpyted trong file: '/digdash/appdata/default/Enterprise Server/ddenterpriseapi/config/serversettings.xml'

Tuy nhiên nếu xóa cả 2 admin user trong LDAP đi thì khi trên UI, list all user ra sẽ ko list dc user admin -> nên ko gán license cho admin được 
-> 1 số trang như Dashboard editor.. thì admin sẽ ko login được vì ko có license

=> như vậy vẫn cần tạo user admin trong LDAP server, nhưng ko tạo password cho nó. Để password sẽ lấy từ file `serversettings.xml`

File tạo user admin cần sửa lại như sau `create_user_admin.ldif`:  

```
dn: uid=admin,ou=users,dc=digdash,dc=com
objectClass: shadowAccount
objectClass: inetOrgPerson
cn: Admin Domain Users
sn: admin
uid: admin

dn: uid=admin,ou=default,dc=digdash,dc=com
objectClass: shadowAccount
objectClass: inetOrgPerson
cn: Admin Domain Default
sn: Default
uid: admin_default
```

Chú ý `uid=admin,ou=users,dc=digdash,dc=com` thì mới hiển thị trên list user,  
chứ `uid=admin,ou=default,dc=digdash,dc=com` sẽ ko hiển thị trên list user, mà cũng ko login được.  
Mình tạo ra nó chỉ để đúng với document mà DigDash cung cấp thôi.  

Nếu bị lỗi khi tạo `uid=admin,ou=users,dc=digdash,dc=com` thì có khả năng bạn đang deploy openLDAP trước (chưa deploy DigDash) nên cần tạo organization `users` đã. 

Vì thế nên file `neworganisation.ldif` mình đã add thêm:  

```
dn: ou=default,dc=digdash,dc=com
objectClass: organizationalUnit
ou: default

dn: ou=users,dc=digdash,dc=com
objectClass: organizationalUnit
ou: users
```

# CREDIT

https://doc.digdash.com/xwiki/wiki/dd2022r2/view/Digdash/deployment/installation/install_guide_ubuntu/  
https://github.com/osixia/docker-openldap#seed-ldap-database-with-ldif  

(pending) Update UI for OpenLDAP by referring this arrticle:  
https://containers.fan/posts/run-openldap-on-docker/#what-is-openldap  