---
title: "Oracle Cloud: Signup and Enable MFA for Identity Cloud Account"
date: 2021-06-24T22:38:17+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [OracleCloud]
comments: false
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Oracle có tiếng đã lâu nhưng Oracle Cloud thì mới được ra không lâu. Để cạnh tranh với các đối thủ thì Oracle Cloud cung cấp nhiều tính năng cho free-tier khá hấp dẫn. "
---

Oracle có tiếng đã lâu nhưng Oracle Cloud thì mới được ra không lâu. Để cạnh tranh với các đối thủ thì Oracle Cloud cung cấp nhiều tính năng cho free-tier khá hấp dẫn.  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-free-tier1.jpg)  

So sánh với AWS chính trên trang chủ của mình luôn 🤣   

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-free-tier2.jpg)  

Khá hấp dẫn đấy chứ. Nếu bạn chưa biết thì Google GCP cũng có chế độ free-tier ở đây: https://cloud.google.com/free

# 1. Sign Up  

Quá trình đăng ký thì bạn có thể vào đây https://signup.cloud.oracle.com/

1 số điểm cần lưu ý:  

- Họ sẽ bắt bạn chọn Home Region (cái này sẽ ko thể thay đổi sau này, nên hãy chọn những region phù hợp với bạn). Khi đăng ký họ sẽ có 1 chú ý nhỏ đại khái là:
> Nhiều người chọn các region UK Lodon, Tokyo, Osaka, US quá nên số instance loại A1 của chúng tôi sẽ limited ở các region này. Bạn nên chọn region khác để có thể chọn A1 instance thoải mái hơn ... đại loại vậy 🤣

- Sẽ cần add thẻ visa, và nhiều khả năng bạn sẽ gặp lỗi này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-vs-add-error.jpg)

Mình rất lấy làm lạ ko hiểu vì sao lại gặp lỗi này trong khi cùng thẻ đó mình vẫn thanh toán quốc tế ầm ầm.  
Trong trường hợp bạn cũng dính lỗi này, mình khuyên bạn nên ấn vào đây để contact Support:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-vs-add-error-2.jpg)  
trong vòng 24h của ngày làm việc họ sẽ xử lý cho bạn ngay, mình thấy Support phản hồi khá nhanh đấy chứ (điểm cộng):  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-vs-add-error-3.jpg)

Họ bảo mình hãy sign-up lại 1 lần nữa, và mình làm lại thì ko còn lỗi add thẻ kia nữa.  
Dù sao thì cơ chế add thẻ này của Oracle vẫn là 1 điểm trừ làm họ giảm số người tiếp cận sản phẩm của họ xuống (Không phải ai cũng sẽ contact support giống như mình)  

# 2. Enable MFA (London region 2021)

Sau khi đã sign-in thành công, như 1 thói quen mình sẽ muốn enable MFA cho account của mình ngay lập tức. (Cái gì liên quan đến tiền thì đều cần phải cẩn thận hết 😁)

Nhưng giao diện của Oracle làm khó mình khi muốn bật MFA. Thật sự là khó vì khi muốn bật MFA bạn phải nhảy quá nhiều màn hình luôn. Điểm trừ cho độ thân thiện UX so với AWS. 

Nói qua 1 chút để mọi người dễ hiểu,  

Sau khi bạn log-in, hệ thống sẽ tạo cho bạn 1 tenancy và add bạn vào 1 Identity Provider tên là `oracleidentitycloudservice`.  
Oracle cũng tạo cho bạn thêm 1 username nữa bắt đầu với `oracleidentitycloudservice/username`.  
Như hình sau là màn hình list các user ban đầu của mình:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-user-1.jpg)

Trong hình trên thì cả 2 user đều là của mình.  
User dòng thứ 1 là user được federated với `oracleidentitycloudservice`, nó được tạo 1 cách tự động.  
User dòng thứ 2 là username mà mình đăng ký ban đầu.   
Chúng sẽ dùng chung 1 password mà bạn đã đăng ký ban đầu nhé. Nhưng trang login lại khác nhau.

- User dòng thứ 2 login bằng chỗ bôi vàng này (đây gọi là OCI user - Oracle Cloud Infrastructure user):  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-login-ui.jpg)

- User dòng thứ 1 thì login bằng chỗ này (đây gọi là IDCS user - Identity Cloud Service user):  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-user-2.jpg)

## 2.1. Enable MFA for OCI User (London region 2021)

Bạn có thể dễ dàng Enable MFA cho OCI user, bằng cách sau khi login vào OCI console, bạn vào `User Setting`, sẽ enable được:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-mfa-user-oci.jpg)

Nhưng điều loằng ngoằng là enable MFA cho IDCS User cơ 😥

## 2.2. Enable MFA for IDCS User (London region 2021)

Sau khi login vào bằng IDCS user, dùng màn hình này,   
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-user-2.jpg)

Để chắc chắn bạn đang ở đúng màn hình thì bạn cần xác nhận là khi ấn vào biểu tượng top-right của màn hình sẽ thấy như sau (có dòng bôi vàng):  
rồi ấn vào `Service User Console`  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-idcs-user-top-right.jpg)

Go to `Admin Console` of Identity:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-idcs-admin-console.jpg)

Go to `My profile` on top-right screen:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-idcs-admin-profile.jpg)

Go to `Security` tab and here you can enable MFA for your IDCS account:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-idcs-admin-security-tab.jpg)

Tại thời điểm này, MFA vẫn chưa được enable đâu nha, hãy quay lại `Admin console` at top-right screen:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-idcs-admin-console2.jpg)

Go to `Security` -> `MFA` at left side panel, check the box `Mobile App Passcode` then SAVE:   
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-idcs-admin-console2-mfa.jpg)

Go to `Security` -> `Sign-On Policies`, edit the `Default Policy`: 
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-idcs-admin-security-signon-policies.jpg)

Edit `Default Sign-on Rule`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-idcs-admin-security-signon-rules.jpg)

Ở đây select những gì tùy ý bạn:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-idcs-admin-security-signon-rules2.jpg)

Xong rồi, giờ hãy Sign-out and Sign-in again. Now you can use MFA to login.  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-login-ui-mfa.jpg)

Rất loằng ngoằng phải ko? 
Điểm trừ cho Oracle Cloud nhé 😂 (Hoặc có thể do mình chưa hiểu chưa quen nên mới chê nó thôi)

# 3. Enable MFA (Singapore region 2023)

Sau 1 thời gian thì mình tạo lại account mới. Lần này mình chọn Singapore.

Có vẻ như bây giờ Oracle trên region này chỉ cho 1 kiểu login thôi.

Đó là user điền tenancy vào, rồi đến màn hình login vào tenancy đó (ko còn kiểu 2 cách login như region London nữa)

Giờ Enable MFA có vẻ dễ hơn, sau đây là các step:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-profile1.jpg)

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-profile1-sec.jpg)

Các bạn add MFA Code bằng cách thông thường, quét QR code là sẽ được như này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-profile1-sec-mfa.jpg)

Sau bước này mới chỉ là các bạn đã có mã code thôi nhé.

Cần làm các bước sau nữa:

Vào đây:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-id-domain-df.jpg)

Chọn Configure MFA:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-config-mfa1.jpg)

Chọn Sign-on Policies:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-sson-policies.jpg)

Chọn Default Policy:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-default-son-policy.jpg)

Edit Rule:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-df-son-policy-edit.jpg)

Chọn các cái này nhé, những cái khác cứ để default:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/oracle-cloud-edit-rule-mfa.jpg)

Done! Giờ signout ra rồi signin lại thôi 😎

Hy vọng giúp ích được các bạn

