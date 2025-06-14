---
title: "AWS: EC2 Storage with IOPS focus"
date: 2023-03-30T21:54:05+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Notes]
tags: [AWS]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Chúng ta đều biết rằng dùng Cloud chưa bao giờ là giải pháp để lựa chọn nếu công ty bạn ít tiền cả."
---

# 1. Story

Rút ra sau khi đọc bài này: https://taoquangne.com/post/how-to-resolve-io-issue-on-cloud/

Chúng ta đều biết rằng dùng Cloud chưa bao giờ là giải pháp để lựa chọn nếu công ty bạn ít tiền cả.

Nếu bạn test/dev thật nhanh 1 dự án, hoặc muốn go LIVE 1 ý tưởng nhanh nhất có thể, hoặc muốn giảm thiểu tối đa công việc maintain phần cứng về long-term, thì dùng Cloud Service là lựa chọn số 1.

Nhưng nếu bạn có 1 project to đùng, muốn đưa lên Cloud theo trend, mà bạn lại ít tiền thì có lẽ sau khi tính toán giá cả bạn sẽ ngã ngửa ra là "sao Cloud tốn tiền thế" ngay.

Mình chưa từng có kinh nghiệm handons để migrate 1 Database to oạch từ Onpremise lên Cloud bao giờ, nhưng việc tiết kiệm tiền khi lên Cloud luôn là 1 vấn đề rất quan trọng mà bất cứ bussiness nào cũng cần để tâm.

Tuy nhiên, nếu biết cách và sẵn sàng đánh đổi những tradeoff thì bạn vẫn có thể "tiền ít mà hít đồ thơm" được ở 1 vài khía cạnh.

Ở đây mình ko nói về cách chọn EC2 để phù hợp cho Database và cách migrate/backup Database (bởi vì bài viết trên đã nói hết rồi).  

Cái mình muốn take note là cách lựa chọn EC2 và storage của nó trên AWS sao cho tiết kiệm mà vẫn có được performance tốt.

Ngắn gọn thôi, AWS EC2 có:

- `EBS`: data persistent nhưng có giới hạn về tốc độ. EBS lại chia làm một số loại nhỏ, nhưng ở đây ta chỉ nói về `gp2` và `io1`
    + `gp2` là EBS giá rẻ, IOPS phụ thuộc vào kích thước của đĩa (muốn tăng IOPS phải resize disk), thường xài cho OS và các nhu cầu chung chung khác. Kích thước từ 1GB - 16TB, Max IOPS/volume là 16,000, max throughput/volume 250 MB/s, max IOPS/instance là 80,000, max throughput/instance 1,750 MB/s. Ngoài ra gp2 có một khái niệm là IO credit và baseline performance, nói 1 cách dễ hiểu là chỉ xài đc 100% performance trong 1 khoảng thời gian và credit có được phụ thuộc vào thời gian sử dụng. Ví dụ đĩa 4TB sẽ có IOPS là 12.288 và giá là ~ $406 tại region us-east-1.
    + `io1` là loại EBS mà IOPS không phụ thuộc vào kích thước đĩa, có thể mua riêng IOPS. Thường xài khi cần nhiều IOPS ví dụ các ứng dụng database. Kích thước từ 4 GB - 16TB. Max IOPS/volume là 64,000, max throughput/volume 1,000 MB/s, max IOPS/instance là 80.000, max throughput/instance 1750 MB/s. Ví dụ với 4TB dữ liệu + 12,288 IOPS sẽ có throughput là 1000 MB/s, thì sẽ có giá là $1441 tại region us-east-1 -> một sự chênh lệnh rất lớn so với gp2.

- `Instance storage`: Đặc điểm chính là có tốc độ cao hơn nhưng dữ liệu không persistent (nghĩa là sẽ mất dữ liệu nếu instance bị stop hoặc terminate hoặc đĩa bị fail). Nhưng restart thì data vẫn ko sao. Ở đây ko nói tốc cao cụ thể là bao nhiêu nên mình muốn tìm hiểu kỹ hơn 1 chút.

# 2. Benchmark trên scalebench.com

1 benchmark trên https://scalebench.com cho 4 loại disk sau:  
- 1 - EBS SSD general iops (about 3k for a 1TB volume)      ----> Chính là EBS `gp2`  
- 2 - EBS SSD provisioned iops (about 50k for a 1TB volume) ----> Chính là EBS `io1`  
- 3 - NVMe SSD local disk (one disk raid 0)                 ----> Chính là `Instance storage`  
- 4 - NVMe SSD local disk (two disks striped raid 1)  

Có thể thấy `Instance storage` vượt trội gấp đôi so với `io1`:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/disk-iops-diff-wr.jpg)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/disk-iops-diff-re.jpg)  

# 3. Tự test trên Oracle

Vì ko có nhiều kiến thức về Oracle, ko biết họ có khái niệm Instance store giống AWS hay ko, nên mình [benmark](https://woshub.com/check-disk-performance-iops-latency-linux/) đơn giản xem IOPS bình thường và IOPS của Instance store giữa các Cloud như thế nào.

Mình đã test thử IOPS của Oracle VM.Standard.A1.Flex, Network bandwidth 4 Gbps, 4CPU, 24GB RAM, Disk Block storage only 145GB. Giá: Free.  
**Kết quả**:  
read: IOPS=6797, BW=26.6MiB/s.  
write: IOPS=2269, BW=9080KiB/s.  

```
# Command sau làm nhiệm vụ: Tạo 1 file 8GB, số lượng request read/write là 75%/25%:  
$ sudo apt-get install fio
$ fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=testfio --bs=4k --iodepth=64 --size=8G --readwrite=randrw --rwmixread=75
th=64
fio-3.1
Starting 1 process
fiotest: Laying out IO file (1 file / 8192MiB)

Jobs: 1 (f=1): [m(1)][100.0%][r=27.3MiB/s,w=9373KiB/s][r=6992,w=2343 IOPS][eta 00m:00s]
fiotest: (groupid=0, jobs=1): err= 0: pid=21923: Thu Mar 30 11:11:11 2023
   read: IOPS=6797, BW=26.6MiB/s (27.8MB/s)(6141MiB/231293msec)
   bw (  KiB/s): min=22224, max=116472, per=100.00%, avg=27200.44, stdev=4411.03, samples=462
   iops        : min= 5556, max=29118, avg=6800.11, stdev=1102.76, samples=462
  write: IOPS=2269, BW=9080KiB/s (9297kB/s)(2051MiB/231293msec)
   bw (  KiB/s): min= 7240, max=38600, per=100.00%, avg=9083.11, stdev=1482.05, samples=462
   iops        : min= 1810, max= 9650, avg=2270.77, stdev=370.51, samples=462
  cpu          : usr=3.50%, sys=17.26%, ctx=1297261, majf=0, minf=6
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=100.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.1%, >=64=0.0%
     issued rwt: total=1572145,525007,0, short=0,0,0, dropped=0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=64

Run status group 0 (all jobs):
   READ: bw=26.6MiB/s (27.8MB/s), 26.6MiB/s-26.6MiB/s (27.8MB/s-27.8MB/s), io=6141MiB (6440MB), run=231293-231293msec
  WRITE: bw=9080KiB/s (9297kB/s), 9080KiB/s-9080KiB/s (9297kB/s-9297kB/s), io=2051MiB (2150MB), run=231293-231293msec

Disk stats (read/write):
  sda: ios=1572005/525391, merge=0/229, ticks=12328846/2400630, in_queue=13192932, util=100.00%

```

# 4. Tự test trên Azure

Trên Azure cũng ko biết có khái niệm Instance store giống AWS ko, nên mình cũng chỉ test 1 VM bình thường thôi.  
Test trên Azure, VM Standard_DS2_v2 (2CPU, 7GB RAM) Disk là Premium SSD LRS 30GB, Max IOPS 120 Max throughput (MBps) 25, OS Ubuntu. Giá 0.1360 $ / giờ.  
**Kết quả**:  
read: IOPS=4720, BW=18.4MiB/s.  
write: IOPS=1576, BW=6305KiB/s.  

```
# Command sau làm nhiệm vụ: Tạo 1 file 8GB, số lượng request read/write là 75%/25%:  
$ sudo apt-get install fio
$ fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=testfio --bs=4k --iodepth=64 --size=8G --readwrite=randrw --rwmixread=75

Starting 1 process
fiotest: Laying out IO file (1 file / 8192MiB)
Jobs: 1 (f=1): [m(1)][100.0%][r=18.6MiB/s,w=6286KiB/s][r=4754,w=1571 IOPS][eta 00m:00s]
fiotest: (groupid=0, jobs=1): err= 0: pid=3403: Fri Mar 31 03:39:13 2023
   read: IOPS=4720, BW=18.4MiB/s (19.3MB/s)(6141MiB/333068msec)
   bw (  KiB/s): min=14560, max=20704, per=99.99%, avg=18878.46, stdev=446.21, samples=666
   iops        : min= 3640, max= 5176, avg=4719.60, stdev=111.56, samples=666
  write: IOPS=1576, BW=6305KiB/s (6456kB/s)(2051MiB/333068msec)
   bw (  KiB/s): min= 4840, max= 7016, per=99.99%, avg=6304.24, stdev=184.79, samples=666
   iops        : min= 1210, max= 1754, avg=1576.04, stdev=46.19, samples=666
  cpu          : usr=1.11%, sys=3.84%, ctx=139162, majf=0, minf=8
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=100.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.1%, >=64=0.0%
     issued rwt: total=1572145,525007,0, short=0,0,0, dropped=0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=64

Run status group 0 (all jobs):
   READ: bw=18.4MiB/s (19.3MB/s), 18.4MiB/s-18.4MiB/s (19.3MB/s-19.3MB/s), io=6141MiB (6440MB), run=333068-333068msec
  WRITE: bw=6305KiB/s (6456kB/s), 6305KiB/s-6305KiB/s (6456kB/s-6456kB/s), io=2051MiB (2150MB), run=333068-333068msec

Disk stats (read/write):
  sda: ios=1572691/525151, merge=439/245, ticks=15808172/5344878, in_queue=19640300, util=99.24%

```

# 5. Tự test trên AWS

Cách để tạo 1 AWS EC2 with `Instance storage`: Mình phải chọn ami từ Community AMIs thì mới ra, chứ các tab khác ko thấy:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/ec2-ami-instance-store-2023.jpg)  

Khi chọn instance type cũng ko nhiều loại mà bạn có thể chọn đâu, Chú ý lọc theo Storage type=SSD để chọn, đừng dùng HDD. Ở đây loại nhỏ nhất có thể chọn mình là `m3.medium`, 1CPU, 3.75GB RAM, 4GB Disk, OS: Ubuntu. Giá: 0.067$ / giờ:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/ec2-ami-instance-type-2023.jpg)

Mình chọn `c3.xlarge`, 4CPU, 7.5GB RAM, Disk 80GB Instance store (2volume, mỗi volume 40GB), OS: Ubuntu. Giá: 0.22$ / giờ.
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/c3xlarge-instance-store.jpg)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/c3xlarge-instance-store-review.jpg)  

```
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            3.7G     0  3.7G   0% /dev
tmpfs           746M  824K  745M   1% /run
/dev/xvda1      9.6G  1.6G  8.0G  17% /
tmpfs           3.7G     0  3.7G   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           3.7G     0  3.7G   0% /sys/fs/cgroup
/dev/xvda15     105M  5.2M  100M   5% /boot/efi
/dev/xvdb        40G  156K   38G   1% /mnt
/dev/loop0       50M   50M     0 100% /snap/snapd/18357
/dev/loop1       56M   56M     0 100% /snap/core18/2697
/dev/loop2       25M   25M     0 100% /snap/amazon-ssm-agent/6312
tmpfs           746M     0  746M   0% /run/user/1000

$ lsblk
NAME     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
loop0      7:0    0 49.9M  1 loop /snap/snapd/18357
loop1      7:1    0 55.6M  1 loop /snap/core18/2697
loop2      7:2    0 24.4M  1 loop /snap/amazon-ssm-agent/6312
xvda     202:0    0   10G  0 disk
├─xvda1  202:1    0  9.9G  0 part /
├─xvda14 202:14   0    4M  0 part
└─xvda15 202:15   0  106M  0 part /boot/efi
xvdb     202:16   0   40G  0 disk /mnt
xvdc     202:32   0   40G  0 disk
```

Ko hiểu sao lúc tạo ra chỉ có 10GB trong /dev/xvda1, nên command phải sửa --size=7G thay vì --size=8G

```
# Command sau làm nhiệm vụ: Tạo 1 file 8GB, số lượng request read/write là 75%/25%:  
$ sudo apt-get update
$ sudo apt-get upgrade -y
$ sudo apt-get install fio
$ fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=testfio --bs=4k --iodepth=64 --size=7G --readwrite=randrw --rwmixread=75

Starting 1 process
fiotest: Laying out IO file (1 file / 7168MiB)
Jobs: 1 (f=1): [m(1)][100.0%][r=26.6MiB/s,w=9165KiB/s][r=6815,w=2291 IOPS][eta 00m:00s]
fiotest: (groupid=0, jobs=1): err= 0: pid=10765: Fri Mar 31 04:03:04 2023
   read: IOPS=6022, BW=23.5MiB/s (24.7MB/s)(5374MiB/228413msec)
   bw (  KiB/s): min=  584, max=28120, per=99.98%, avg=24085.72, stdev=3726.67, samples=456
   iops        : min=  146, max= 7030, avg=6021.43, stdev=931.67, samples=456
  write: IOPS=2010, BW=8043KiB/s (8236kB/s)(1794MiB/228413msec)
   bw (  KiB/s): min=  176, max= 9864, per=99.97%, avg=8040.66, stdev=1270.20, samples=456
   iops        : min=   44, max= 2466, avg=2010.16, stdev=317.55, samples=456
  cpu          : usr=5.11%, sys=16.19%, ctx=1406698, majf=0, minf=6
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=100.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.1%, >=64=0.0%
     issued rwt: total=1375709,459299,0, short=0,0,0, dropped=0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=64

Run status group 0 (all jobs):
   READ: bw=23.5MiB/s (24.7MB/s), 23.5MiB/s-23.5MiB/s (24.7MB/s-24.7MB/s), io=5374MiB (5635MB), run=228413-228413msec
  WRITE: bw=8043KiB/s (8236kB/s), 8043KiB/s-8043KiB/s (8236kB/s-8236kB/s), io=1794MiB (1881MB), run=228413-228413msec

Disk stats (read/write):
  xvda: ios=1371152/458621, merge=3995/560, ticks=10820729/3714291, in_queue=11029568, util=100.00%
```
**Kết quả**:  
read: IOPS=6022, BW=23.5MiB/s.  
write: IOPS=2010, BW=8043KiB/s.  
-> Có thể thấy trên `xvda` có tốc độ rất bình thường, phải nói là chậm, trong khi chúng ta kỳ vọng nhiều hơn?

-> Sau lệnh `lsblk` thấy rằng ổ `xvdb và xvdc` mới là ổ Instance store cần test:  

```
/mnt$ sudo su
root@ip-172-31-89-140:/mnt# fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=testfio --bs=4k --iodepth=64 --size=8G --readwrite=randrw --rwmixread=75
fiotest: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=64
fio-3.1
Starting 1 process
fiotest: Laying out IO file (1 file / 8192MiB)
fio: native_fallocate call failed: Operation not supported
Jobs: 1 (f=1): [m(1)][100.0%][r=141MiB/s,w=47.2MiB/s][r=36.2k,w=12.1k IOPS][eta 00m:00s]
fiotest: (groupid=0, jobs=1): err= 0: pid=10836: Fri Mar 31 04:09:04 2023
   read: IOPS=27.0k, BW=106MiB/s (111MB/s)(6141MiB/58204msec)
   bw (  KiB/s): min=62120, max=151544, per=99.84%, avg=107865.14, stdev=17957.62, samples=116
   iops        : min=15532, max=37886, avg=26966.29, stdev=4489.36, samples=116
  write: IOPS=9020, BW=35.2MiB/s (36.9MB/s)(2051MiB/58204msec)
   bw (  KiB/s): min=20904, max=51664, per=99.84%, avg=36021.23, stdev=6018.15, samples=116
   iops        : min= 5226, max=12916, avg=9005.30, stdev=1504.54, samples=116
  cpu          : usr=14.48%, sys=41.01%, ctx=774515, majf=0, minf=10
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=100.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.1%, >=64=0.0%
     issued rwt: total=1572145,525007,0, short=0,0,0, dropped=0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=64

Run status group 0 (all jobs):
   READ: bw=106MiB/s (111MB/s), 106MiB/s-106MiB/s (111MB/s-111MB/s), io=6141MiB (6440MB), run=58204-58204msec
  WRITE: bw=35.2MiB/s (36.9MB/s), 35.2MiB/s-35.2MiB/s (36.9MB/s-36.9MB/s), io=2051MiB (2150MB), run=58204-58204msec

Disk stats (read/write):
  xvdb: ios=1561953/522247, merge=2756/1344, ticks=2904287/764910, in_queue=501340, util=99.89%
```

**Kết quả**:  
read: IOPS=27.0k, BW=106MiB/s.  
write: IOPS=9020, BW=35.2MiB/s.   
-> Tốc độ IOPS lớn hơn rất nhiều, gấp từ 3~4 lần so với thông thường.  

# 6. Kết luận

- Đúng là dùng AWS EC2 Instance store cho Disk IOPS performance cực kỳ khác biệt.  
- Tuy nhiên tradeoff của nó là sẽ mất data khi stop/shutdown VM. -> Cần có giải pháp backup, master-slave chẳng hạn.  
- Chú ý là Sau khi tạo VM EC2 thì cần có các step để mount các Instance store vào đúng path cần dùng. Chứ nếu chạy trên xvda sẽ ko thấy sự khác biệt về IOPS.  
- Đây có thể coi là 1 sự lựa chọn "ổn áp" về giá cho các ứng dụng mà có traffic READ/WRITE lớn như Database, yêu cầu performance IOPS cao, hoặc những app mà data ko quá quan trọng, có thể dùng những background job để move data quan trọng sang chỗ khác vào ban đêm.  

# CREDIT

https://taoquangne.com/post/how-to-resolve-io-issue-on-cloud/  
https://www.youtube.com/watch?v=tee5yJr3rTM&ab_channel=TechnologyHub  
https://www.scalebench.com/blog/index.php/2020/06/03/aws-ebs-vs-aws-instance-storelocal-disk-storage/  
https://woshub.com/check-disk-performance-iops-latency-linux/  
