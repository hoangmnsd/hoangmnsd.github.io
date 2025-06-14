---
title: "Increase disk size Ubuntu20 on VirtualBox"
date: 2025-03-11T21:46:36+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [VirtualBox,Ubuntu]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Cách tăng disk size của Ubuntu20 VM trong Oracle VirtualBox"
---

Trên 1 VM ubuntu 20.04, cài trên VirtualBox, ban đầu mình chỉ allocate 10GB, nhưng về sau cần nhiều hơn, nên đã dùng Windows Command để resize file vdi thành 20.7GB
Dùng command trên Windows Command Line: (source: https://www.howtogeek.com/124622/how-to-enlarge-a-virtual-machines-disk-in-virtualbox-or-vmware/)
```
VBoxManage modifyhd "C:\Users\USERNAME\VirtualBox VMs\Windows 10\Windows 7.vdi" --resize 21920
hoặc:
VBoxManage modifymedium disk "C:\Users\USERNAME\VirtualBox VMs\Windows 10\Windows 10.vdi" --resize 21920
```

Nhưng sau khi restart, bây giờ vào VM, thì thấy sda disk đúng là 20.7GB, nhưng `df -h` vẫn chỉ có 10G (8.1G + 1.7G).
Nghĩa là đã resize nhưng vẫn đang ở trạng thái unallocated nên chưa dùng được 20.7GB.
Vì vậy cần expand partition ra để sử dụng. (source: https://askubuntu.com/a/1536877)

```
$ lsblk
NAME                      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda                         8:0    0  20.7G  0 disk
├─sda1                      8:1    0     1M  0 part
├─sda2                      8:2    0   1.8G  0 part /boot
└─sda3                      8:3    0   8.3G  0 part
  └─ubuntu--vg-ubuntu--lv 253:0    0   8.3G  0 lvm  /
sr0                        11:0    1  1024M  0 rom


$ df -h
Filesystem                         Size  Used Avail Use% Mounted on
udev                               940M     0  940M   0% /dev
tmpfs                              198M  1.2M  197M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv  8.1G  6.1G  1.6G  80% /
tmpfs                              986M     0  986M   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
tmpfs                              986M     0  986M   0% /sys/fs/cgroup
/dev/sda2                          1.7G  111M  1.5G   7% /boot
tmpfs                              198M     0  198M   0% /run/user/1000


$ sudo vgdisplay
  --- Volume group ---
  VG Name               ubuntu-vg
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  2
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               1
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <8.25 GiB
  PE Size               4.00 MiB
  Total PE              2111
  Alloc PE / Size       2111 / <8.25 GiB
  Free  PE / Size       0 / 0
  VG UUID               s3TySA-BFWy-32DO-VWul-cF8E-PDUr-FlgVnf


$ sudo lvdisplay
  --- Logical volume ---
  LV Path                /dev/ubuntu-vg/ubuntu-lv
  LV Name                ubuntu-lv
  VG Name                ubuntu-vg
  LV UUID                Kn2gey-G6MC-Kzvw-wLew-QT9V-Cg2X-pV6Yf9
  LV Write Access        read/write
  LV Creation host, time ubuntu-server, 2025-02-28 08:27:32 +0000
  LV Status              available
  # open                 1
  LV Size                <8.25 GiB
  Current LE             2111
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:0
```

Bắt đầu expand, sau command `sudo growpart /dev/sda 3` này đã thấy lsblk trả về sda lên 19G:
```
$ sudo growpart /dev/sda 3
CHANGED: partition=3 start=3674112 old: size=17295360 end=20969472 new: size=39743455 end=43417567

$ lsblk
NAME                      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda                         8:0    0  20.7G  0 disk
├─sda1                      8:1    0     1M  0 part
├─sda2                      8:2    0   1.8G  0 part /boot
└─sda3                      8:3    0    19G  0 part
  └─ubuntu--vg-ubuntu--lv 253:0    0   8.3G  0 lvm  /
sr0                        11:0    1  1024M  0 rom

$ sudo lvdisplay
  --- Logical volume ---
  LV Path                /dev/ubuntu-vg/ubuntu-lv
  LV Name                ubuntu-lv
  VG Name                ubuntu-vg
  LV UUID                Kn2gey-G6MC-Kzvw-wLew-QT9V-Cg2X-pV6Yf9
  LV Write Access        read/write
  LV Creation host, time ubuntu-server, 2025-02-28 08:27:32 +0000
  LV Status              available
  # open                 1
  LV Size                <8.25 GiB
  Current LE             2111
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:0

$ sudo vgdisplay
  --- Volume group ---
  VG Name               ubuntu-vg
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  3
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               1
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <8.25 GiB
  PE Size               4.00 MiB
  Total PE              2111
  Alloc PE / Size       2111 / <8.25 GiB
  Free  PE / Size       0 / 0
  VG UUID               s3TySA-BFWy-32DO-VWul-cF8E-PDUr-FlgVnf
```


Tiếp, sau command `sudo pvresize /dev/sda3` này, thấy vgdisplay đã thay đổi VG Size thành <18.95 GiB:
```
$ sudo pvresize /dev/sda3
  Physical volume "/dev/sda3" changed
  1 physical volume(s) resized or updated / 0 physical volume(s) not resized


$ lsblk
NAME                      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda                         8:0    0  20.7G  0 disk
├─sda1                      8:1    0     1M  0 part
├─sda2                      8:2    0   1.8G  0 part /boot
└─sda3                      8:3    0    19G  0 part
  └─ubuntu--vg-ubuntu--lv 253:0    0   8.3G  0 lvm  /
sr0                        11:0    1  1024M  0 rom

$ sudo vgdisplay
  --- Volume group ---
  VG Name               ubuntu-vg
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  4
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               1
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <18.95 GiB
  PE Size               4.00 MiB
  Total PE              4851
  Alloc PE / Size       2111 / <8.25 GiB
  Free  PE / Size       2740 / 10.70 GiB
  VG UUID               s3TySA-BFWy-32DO-VWul-cF8E-PDUr-FlgVnf

$ sudo lvdisplay
  --- Logical volume ---
  LV Path                /dev/ubuntu-vg/ubuntu-lv
  LV Name                ubuntu-lv
  VG Name                ubuntu-vg
  LV UUID                Kn2gey-G6MC-Kzvw-wLew-QT9V-Cg2X-pV6Yf9
  LV Write Access        read/write
  LV Creation host, time ubuntu-server, 2025-02-28 08:27:32 +0000
  LV Status              available
  # open                 1
  LV Size                <8.25 GiB
  Current LE             2111
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:0

$ df -h
Filesystem                         Size  Used Avail Use% Mounted on
udev                               940M     0  940M   0% /dev
tmpfs                              198M  1.2M  197M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv  8.1G  6.1G  1.6G  80% /
tmpfs                              986M     0  986M   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
tmpfs                              986M     0  986M   0% /sys/fs/cgroup
/dev/sda2                          1.7G  111M  1.5G   7% /boot
```

Cuối cùng, sau command `sudo lvextend -l +100%FREE -r /dev/mapper/ubuntu--vg-ubuntu--lv` này, mọi thứ đã oK:
```
$ sudo lvextend -l +100%FREE -r /dev/mapper/ubuntu--vg-ubuntu--lv
  Size of logical volume ubuntu-vg/ubuntu-lv changed from <8.25 GiB (2111 extents) to <18.95 GiB (4851 extents).
  Logical volume ubuntu-vg/ubuntu-lv successfully resized.
resize2fs 1.45.5 (07-Jan-2020)
Filesystem at /dev/mapper/ubuntu--vg-ubuntu--lv is mounted on /; on-line resizing required
old_desc_blocks = 2, new_desc_blocks = 3
The filesystem on /dev/mapper/ubuntu--vg-ubuntu--lv is now 4967424 (4k) blocks long.


$ lsblk
NAME                      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda                         8:0    0  20.7G  0 disk
├─sda1                      8:1    0     1M  0 part
├─sda2                      8:2    0   1.8G  0 part /boot
└─sda3                      8:3    0    19G  0 part
  └─ubuntu--vg-ubuntu--lv 253:0    0    19G  0 lvm  /
sr0                        11:0    1  1024M  0 rom

$ sudo lvdisplay
  --- Logical volume ---
  LV Path                /dev/ubuntu-vg/ubuntu-lv
  LV Name                ubuntu-lv
  VG Name                ubuntu-vg
  LV UUID                Kn2gey-G6MC-Kzvw-wLew-QT9V-Cg2X-pV6Yf9
  LV Write Access        read/write
  LV Creation host, time ubuntu-server, 2025-02-28 08:27:32 +0000
  LV Status              available
  # open                 1
  LV Size                <18.95 GiB
  Current LE             4851
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:0


$ sudo vgdisplay
  --- Volume group ---
  VG Name               ubuntu-vg
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  5
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               1
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <18.95 GiB
  PE Size               4.00 MiB
  Total PE              4851
  Alloc PE / Size       4851 / <18.95 GiB
  Free  PE / Size       0 / 0
  VG UUID               s3TySA-BFWy-32DO-VWul-cF8E-PDUr-FlgVnf

$ df -h
Filesystem                         Size  Used Avail Use% Mounted on
udev                               940M     0  940M   0% /dev
tmpfs                              198M  1.2M  197M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv   19G  6.1G   12G  35% /
tmpfs                              986M     0  986M   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
tmpfs                              986M     0  986M   0% /sys/fs/cgroup
/dev/sda2                          1.7G  111M  1.5G   7% /boot

```


