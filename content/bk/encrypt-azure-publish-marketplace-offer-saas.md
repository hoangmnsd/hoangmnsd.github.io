---
title: "Azure: Publish SaaS Offer (Software as a Service Offer)"
date: 2024-01-01T22:17:59+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Azure]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Tour 1 vòng khi tạo Azure SaaS Offer"
---

# 1. Azure SaaS Offer là gì?

Sơ đồ quyết định nên dùng Azure Marketplace Offer nào:  
https://learn.microsoft.com/en-us/partner-center/marketplace/marketplace-commercial-transaction-capabilities-and-considerations#determine-offer-type-and-pricing-plan  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-decide-offer-type.jpg)

# 2. Những điểm cần chú ý khi tạo SaaS Offer

## 2.1. SaaS Offer lifecycle

Diagram về các thành phần involve trong 1 SaaS offer:
https://learn.microsoft.com/en-us/partner-center/marketplace/azure-ad-saas#how-microsoft-entra-id-works-with-the-commercial-marketplace-for-saas-offers  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-entra-id-invlove.jpg)

Diagram về các giai đoạn cần để tạo 1 SaaS offer:  
https://youtu.be/AnZDa0Z1z8I?t=265  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-lifecycle.jpg)  

Diagram ví dụ về quá trình 1 Customer discovery SaaS offer từ Marketplace, subscribe, activate plan, rồi unsubscribe offer đó. Diagram này giả sử trường hợp Publish muốn bán SaaS offer thông qua MS. 
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-process.jpg)

Sơ đồ về workflow của các thành phần trong SaaS:   
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-workflow-youtube.jpg)

1 - Buyer vào xem saas offer và subscribe.   
2 - Buyer ấn configure account và redirect đến LandingPage.   
3 - LandingPage authen bằng SSO để Buyer ko cần login gì nữa.  
4 - LandingPage request Fulfillment API để lấy thông tin Buyer đã purchase.  
5 - LandingPage do something (create user account, database riêng, email cho các bên liên quan, tạo link để đưa cho Buyer chẳng hạn).  
https://youtu.be/0c-rzJkTV7w?list=PLmsFUfdnGr3wWUaB-QkSaQRHBNYKZj5PM&t=132

Sơ đồ chi tiết về các step vừa nói ở trên, chú ý là: Đến bước sign up new customer, có thể làm bằng tay, hoặc tự động, miễn là với user và account đó. vài ngày sau user sẽ đăng nhập được vào hệ thống của bạn.  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-landing-page-api.jpg)

Diagram về process Subscribe/Unsubscribe SaaS offer:  
https://youtu.be/mqyychm0w6E?t=1315  
https://learn.microsoft.com/en-us/partner-center/marketplace/partner-center-portal/saas-fulfillment-apis-faq#how-are-you-notified-when-a-user-subscribes-to-your-saas-offer-

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-subscribe-unsub-youtube.jpg)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-billing-flow-ms.jpg)  

## 2.2. SaaS Subscription Lifecycle

Billing sẽ bắt đầu ngay sau khi Customer activate subscription trên Landing Page.  
Nếu sau 30 ngày mà chưa Activate subscription trên Landing Page thì subscription sẽ bị xóa.  
> If no action is taken within 30 days, this SaaS subscription will be automatically deleted.​  

Nếu MS chưa nhận đc payment thì sẽ bị về trạng thái Suspended trong 30 ngày để chờ, sau 30 days thì chuyển sang Unsubscribed (cancel):  
https://learn.microsoft.com/en-us/partner-center/marketplace/partner-center-portal/pc-saas-fulfillment-life-cycle

> This state indicates that a customer's payment for the SaaS service was not received. Microsoft will notify the publisher of this change in the SaaS subscription status. The notification is done via a call to webhook with the action parameter set to Suspended. The SaaS subscription is automatically renewed by Microsoft at the end of the subscription term of a month or a year. The default for the auto-renewal setting is true for all SaaS subscriptions. Active SaaS subscriptions will continue to be renewed with a regular cadence. Microsoft provides inform-only webhook notifications for renew events. A customer can turn off automatic renewal for a SaaS subscription via the Microsoft 365 Admin Portal. In this case, the SaaS subscription will be automatically canceled at the end of the current billing term. Customers can also cancel the SaaS subscription at any time.After the publisher receives a cancellation webhook call, they should retain customer data for recovery on request for at least seven days. Only then can customer data be deleted.A SaaS subscription can be canceled at any point in its life cycle. After a subscription is canceled, it can't be reactivated.

Khi Customer change plan on Azure portal, MS sẽ send webhook 1 request để thông báo rằng "Customer đang thay đổi plan", webhook nhận được request thì phải xử lý ngay trong vòng 10s, nếu quá 10s thì Customer change plan action mặc định là success: https://learn.microsoft.com/en-us/partner-center/marketplace/partner-center-portal/pc-saas-fulfillment-life-cycle#update-initiated-from-the-commercial-marketplace
> The publisher should invoke PATCH to update the Status of Operation API with a Failure/Success response within a 10-second time window after receiving the webhook notification. If PATCH of operation status is not received within the 10 seconds, the change plan is automatically patched as Success.

Sau khi subscribed, có thể cancel trong vòng 72 tiếng ko bị charge gì. Nếu cancel khi quá 72hours, sẽ vẫn bị charge full và ko thể refund.
> If you cancel more than 72 hours after subscribing, you'll be charged until the end of the current term and won't be eligible for a refund for that term, as stated in our cancellation policy. https://learn.microsoft.com/en-us/partner-center/marketplace/partner-center-portal/pc-saas-fulfillment-subscription-api#cancel-a-subscription
> The customer won't be billed if a subscription is canceled within 72 hours from purchase.


## 2.3. Two stores (Azure Marketplace and AppSource)

Nếu bạn publish SaaS Offer thành công thì nó (có thể) sẽ được available trên cả 2 cái stores của MS là Azure Marketplace và AppSource.

- AppSource dành cho Bussiness solutions, Marketplace cho IT solutions.  
- AppSource thì phải thanh toán qua credit card, ko cần có Azure Supscription.  
- 1 số setup sẽ làm offer chỉ available trên AppSource mà ko available trên Azure Marketplace. (Khi chọn MS quản lý license hộ mình -> bắt buộc phải dùng pricing model là Per-user -> khi đó SaaS offer chỉ available trên AppSource thôi)
- AppSource thường dành cho những solution mà cần tương tác với MS Office, MS Teams, Dynamics 365, MS 365, MS Word/Excel...

https://learn.microsoft.com/en-us/partner-center/marketplace/overview#commercial-marketplace-online-stores  
https://learn.microsoft.com/en-us/partner-center/marketplace/plan-saas-offer  

## 2.4. Landing Page là rất quan trọng

Landing Page là 1 phần rất quan trọng khi bạn bán SaaS offer trên Azure Marketplace

Landing Page của bạn cần phải dùng SaaS fulfillment API integration để interact với Commercial Marketplace API:
https://learn.microsoft.com/en-us/partner-center/marketplace/partner-center-portal/pc-saas-fulfillment-apis

> Register your SaaS application in the Azure portal as explained in Register a Microsoft Entra Application. Afterwards, use the most current version of this interface for development: SaaS fulfillment Subscription APIs v2 and SaaS fulfillment Operations APIs v2.

# 3. Setup SaaS Offer on Partner Center

## 3.1. Thu tiền của Customer như thế nào?

Khi setup SaaS Offer, Bạn được chọn sẽ thu tiền của Customer theo kiểu nào? 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-setup1.jpg)

- 1 là bán thông qua MS (sell through Microsoft) gọi là transactable offer.

- 2 là bán độc lập (không thông qua MS) gọi là process transactions independently.

### 3.1.1. Bán độc lập không thông qua MS

Gọi là process transactions independently. Nếu bán không thông qua MS thì bạn sẽ phải care hết các khâu của việc mua bán phần mềm.

> Publishers are responsible for supporting all aspects of the software license transaction, including but not limited to order, fulfillment, metering, billing, invoicing, payment, and collection. Source: https://learn.microsoft.com/en-us/partner-center/marketplace/plan-saas-offer#listing-options

Khi setup Offer bạn sẽ chọn `No, I would prefer to only list my offer through the marketplace and process transactions independently`

Bạn sẽ được chọn 1 trong 3 cách listing: 
- Get it now (free)
- Free trial
- Contact me 

Nếu bạn chọn "Get it now hoặc Free trial" thì:  
- Bạn sẽ cần phải setup Landing Page.  
- Bạn sẽ không có tab "Techinal Configuration" và "Plan Overview" để setup plan, pricing model trên Partner Center. (ảnh).  
- Về phía Customer: Sau khi Offer được Customer ấn "Get it now/Free trial" nó sẽ redirect Customer về Landing Page.  
- 2 link tham khảo:  
  https://learn.microsoft.com/en-us/partner-center/marketplace/azure-ad-free-or-trial-landing-page   
  https://learn.microsoft.com/en-us/partner-center/marketplace/azure-ad-saas#before-you-begin   

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-setup1-freetrial.jpg)

Nếu bạn chọn "Contact me" thì:  
- Bạn sẽ không cần phải setup Landing Page.  
- Bạn sẽ không có tab "Techinal Configuration" và "Plan Overview" để setup plan, pricing model trên Partner Center. (ảnh).  
- Về phía Customer: Sau khi Offer được Customer ấn "Contact me" nó sẽ show màn hình info của Publisher để Customer liên hệ.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-setup1-contactme.jpg)

### 3.1.2. Bán thông qua MS (sell through Microsoft)

Gọi là transactable offer: https://learn.microsoft.com/en-us/partner-center/marketplace/azure-ad-saas

Khi setup Offer bạn sẽ chọn `Yes, I would like to sell through Microsoft and have Microsoft host transactions on my behalf` (ảnh)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-setup-yes.jpg)

MS thu tiền của Customer, rồi đưa lại cho bạn: Giả sử license của mình có giá 100$, MS sẽ lấy của Customer 100$ và giữ lại 3$ => Tức là MS ăn 3% tiền license. Ngoài ra chi phí infra cho SaaS thì mình phải chịu hết.
https://learn.microsoft.com/en-us/partner-center/marketplace/marketplace-commercial-transaction-capabilities-and-considerations#examples-of-pricing-and-store-fees

Khi Bán thông qua MS thì:  
- Bạn sẽ cần setup 1 App Registration MS Entra App. App này được dùng để làm gì (cần đọc thêm ở đây: https://learn.microsoft.com/en-us/partner-center/marketplace/azure-ad-saas).  
- Bạn sẽ cần setup 1 Landing Page cho Customer. (Customer vào đó để xem họ đã mua cái gì, activate plan họ đã mua, lấy thông tin account để sử dụng service)
- Bạn sẽ có tab "Techinal Configuration" và "Plan Overview" để setup landing page, plan, pricing model trên Partner Center. (ảnh). 
- Về phía Customer: Sau khi subscribe Offer, họ sẽ ấn tiếp vào 1 button "Configure account now" để redirect đến Landing Page.

SaaS offer mà bán thông qua MS thì họ support thanh toán các kiểu sau: 1 lần trả trước, trả theo tháng, trả theo năm, trả per user, trả per consumption.
https://learn.microsoft.com/en-us/partner-center/marketplace/plan-saas-offer#saas-billing

## 3.2. Có quản lý license thông qua MS không?

Would you like to use Microsoft license management service? 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-setup-ms-manage-lcs-yes.jpg)

phần này bạn sẽ có 2 lựa chọn: 
- `Yes, I would like Microsoft to manage customer licenses on my behalf`: Offer của bạn sẽ chỉ available trên store AppSource. Và bạn phải setup Plan theo kiểu Per-user (chứ ko thể setup kiểu flat-rate). Code của bạn cũng cần integrate với MS Graph API nữa.  
- `No, I would prefer to manage customer licenses myself`: Offer của bạn sẽ available trên cả 2 store Azure Marketplace và AppSource. App của bạn phải tự quản lý Customer license. Bạn có thể setup plan dùng Flat-rate hoặc Per-user.  

Cái này tùy vào bussiness của bạn mà chọn.

Mình thường chọn No.

## 3.3. Test drive

https://learn.microsoft.com/en-us/partner-center/marketplace/plan-saas-offer#test-drives
A test drive is different from a free trial. You can offer a test drive, free trial, or both. They both provide your customers with your solution for a fixed period-of-time. But, a test drive also includes a hands-on, self-guided tour of your product's key features and benefits being demonstrated in a real-world implementation scenario.

Mình chưa dùng thử cái này.

## 3.4. Microsoft 365 integration

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-setup-ms-integration-no.jpg)

Phần này mình chỉ hiểu sơ qua là nếu SaaS của bạn có thể tương tác trực tiếp với các sản phẩm của MS như là 1 add-in trong Excel, Word, Teams SharePoint thì bạn chọn vào.

Nếu chọn Yes (ảnh):  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-setup-ms-integration-yes.jpg)

Bạn sẽ cần cung cấp thêm là MS Entra Identity App ID

Mình toàn chọn default là "No" hết.

## 3.5. Preview Audiences

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-setup-preview-audience.jpg)

Phần này nhập email của những người có thể sử dụng Offer khi ở Preview.

## 3.6. Technical Configuration

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-tech-configure.jpg)

Phần này bạn cần config:  
- Landing Page URL: Là nơi mà Customer sẽ được redirect đến sau khi họ đã purchase Offer và ấn vào button "Configure account now".  
- Connection webhook: Là nơi mà khi Customer có action gì đối với Offer (ví dụ như Change Plan) thì MS sẽ notify Publisher thông qua Webhook.   
- `Microsoft Entra tenant ID và Microsoft Entra Identity application ID` là thông tin của App Registration ID mà bạn đã tạo ra.  

### 3.6.1. App Registration (hay Microsoft Entra Identity application ID) là gì?

https://learn.microsoft.com/en-us/partner-center/marketplace/azure-ad-saas#how-microsoft-entra-id-works-with-the-commercial-marketplace-for-saas-offers

### 3.6.2. Tạo App Registration kiểu gì?

Follow documents này để tạo: https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app#register-an-application

Chú ý: Chọn `Accounts in any organizational directory` (ảnh)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-ms-entra-id-any.jpg)

Bởi vì mình đang tạo SaaS Offer:  
> Accounts in any organizational directory: Select this option if you want users in any Microsoft Entra tenant to be able to use your application. This option is appropriate if, for example, you're building a software-as-a-service (SaaS) application that you intend to provide to multiple organizations.

### 3.6.3. App Registration quan trọng như thế nào?

App Registration dùng để Landing Page có thể authenticate đến MS endpoint authority.  
Dùng đúng App Registration chưa đủ mà còn phải dùng đúng authority endpoint nữa. 

Nếu setup sai bạn có thể sẽ gặp lỗi kiểu này: 
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-landing-page-error-login.jpg)

Về nguyên nhân và cách fix thì tham khảo bên dưới phần `Troubleshoot`

## 3.7. Plan Overview (Dùng để setup các plan)

### 3.7.1. Public Plan và Private Plan

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-plan-overview.jpg)

> Public plan will be available to everyone in the Azure Portal and Azure Marketplace.  
> Private plan will be available to the audience configured below. Private plans will only be visible in the Azure Portal or AppSource.  

Cái này khá tiện nếu như bạn muốn bán SaaS cho 1 Customer với mức giá cạnh tranh. Bạn sẽ cần nhập tenant ID của Customer vào đây. Rồi Publish lại Offer.

### 3.7.2. Pricing model

Có 2 kiểu "flat-rate" và "per-user". 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-plan-pricing.jpg)

Khi chọn flat-rate:
- Bạn sẽ có thể config các billing terms khác nhau: (1 tháng, 1 năm, 2 năm, 3 năm)
- Với mỗi billing term sẽ có các payment option khác nhau như: One time, per month, per year. 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-plan-pricing-flat-rate.jpg)

Khi chọn per-user:
- Vẫn có những option như flat-rate nhưng Bạn sẽ có thêm option để limit số lượng Customer có thể Purchase this plan.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-plan-pricing-per-user.jpg)

1 offer ko thể vừa có plan flat rate và plan per-user. 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-plan-note.jpg)

https://learn.microsoft.com/en-us/partner-center/marketplace/create-new-saas-offer-plans#define-a-pricing-model

## 3.8. Private Offer (đây là 1 phần riêng, hoạt động được sau khi Offer đã Go Live)

Private Offer giúp bạn bán 1 offer đã Go Live với mức giá "Private" cho Customer. 

Tài liệu về Private Offer API:
https://learn.microsoft.com/en-us/partner-center/marketplace/private-offers-api


# 4. Demo Landing Page từ đầu đến cuối

Landing Page bạn có thể dựng trên 1 VM, 1 Containers, hay dùng Azure App Service cũng được. Nhưng sẽ cần có HTTPS domain. 

Thế nên bài này mình chọn Azure App Service để deploy Landing Page vì sẽ có HTTPS luôn. Ngôn ngữ thì chọn Python. Framwork là Flask.

## 4.1. Tạo App Registration (MS Entra App ID)

Đầu tiên là vào Azure Portal => MS Entra ID => tạo App Registration, chú ý chọn "Accounts in any organizational directory (Any Microsoft Entra ID tenant - Multitenant)"

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-app-regis-create1.jpg)

Chú ý chỗ Authentication, chỉ được nhập link https hoặc localhost thôi. Tại thời điểm này chúng ta chưa có app run ở AppService với https, thì cứ để trống cũng được:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-app-regis-authen.jpg)

Tạo secret và save nó cẩn thận ở đâu đó:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-app-regis-cert.jpg)

Lấy `CLIENT_ID và CLIENT_SECRET`

## 4.2. Create a Landing Page project

Mình dùng 1 project sample của MS, project dùng Python Flask API để demo.

clone project này về: https://github.com/Azure-Samples/ms-identity-python-webapp

Sửa file:

Tạo file `.env`:  
```
CLIENT_ID=<client id>
CLIENT_SECRET=<client secret>
```

Run thử dưới local:

```sh
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
python3 -m flask run --debug --host=localhost --port=5000
```

Test trên http://localhost:5000 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-landingpage-local.jpg)

Thử ấn nut Sign In mà bị lỗi cũng ko sao.

## 4.3. Deploy to Azure App Service

Giờ sẽ deploy App lên Azure App Service

có thể tham khảo tài liệu này: https://learn.microsoft.com/en-us/azure/app-service/quickstart-python?tabs=flask%2Cwindows%2Cazure-cli%2Cvscode-deploy%2Cdeploy-instructions-azportal%2Cterminal-bash%2Cdeploy-instructions-zip-azcli

Vào Azure Portal => App Service => Create Web App

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-app-service.jpg)

Khi tạo sẽ cần lựa chọn các thông số kỹ thuật, cái này tùy vào nhu cầu mà lựa chọn thôi:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-app-service-config.jpg)

Sau khi tạo AppServic, trong RG sẽ thấy 2 thứ được tạo ra:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-app-service-rs.jpg)

Vào cái App Service => Deployment Center

Tại đây Azure cung cấp 1 repo để bạn push source code ở local lên. Sau khi push lên thì sẽ bạn sẽ thấy App của bạn run trên link HTTPS mà App Service cung cấp.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-app-service-deployment-center.jpg)

Vào tab Configuration, bạn sẽ cần tạo ra các biến môi trường sử dụng cho App Service:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-app-service-configure.jpg)

push code lên repo của App Service. Chờ deploy xong

Có thể tail log để check:

```sh
az webapp log config \
    --web-server-logging filesystem \
    --name $APP_SERVICE_NAME \
    --resource-group $RESOURCE_GROUP_NAME

az webapp log tail \
    --name $APP_SERVICE_NAME \
    --resource-group $RESOURCE_GROUP_NAME
```

Vào check lại link HTTPS thấy app đã lên là OK

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-landing-page-https.jpg)

Giờ sửa code để run được Demo

Clone source from this: https://gitlab.com/inmessionante/devsaaslandingpage.git

Create file `.env` and put the credential info as described in `.env.sample`.  
Read the `README.md` and run it on local first. Test it works when login ok.  
Then push it to AppService to test further functions.  

## 4.4. Publish Offer to Preview

Trên Partner center, cần publish SaaS Offer tới Preview.

Với code dã sửa, mình cần setup trên Partner Center, phần Technical configuration như sau: chú ý link Landing Page và Connection webhook 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-tech-config.jpg)

Sau đó Publish SaaS Offer đến Preview.

## 4.5. Demo User activity

Test deploy từ Marketplace, ấn vào nút subscribe

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-deploy1.jpg)

Đến màn hình chọn RG để deploy SaaS vào:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-deploy2.jpg)

Màn hình chờ:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-deploy3.jpg)

Đã deploy xong, giờ nút "Configure account now" đã hiện ra:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-deploy-ok.jpg)

Nếu vào RG sẽ nhìn thấy SaaS service được tạo ra:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-deploy-ok-rs.jpg)

Ấn vào sẽ thấy chi tiết về Plan bạn đã subscribe, nó vẫn đang ở trạng thái Pending, Billing chưa start. Sau khi bạn đã Configure account, activate plan thì mới tính là bắt đầu

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-deploy-ok-config-now.jpg)

Ấn vào Configure account now, sẽ redirect đến Landing Page

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-landing-page-https.jpg)

Sau khi Sign in thành công, Bạn sẽ thấy màn hình này, show ra các step để hướng dẫn User thực hiện activate plan, rồi lấy account sử dụng service

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-landing-page-https-logged-in.jpg)

Ấn vào Step 1 sẽ hiện ra thông tin plan:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-landing-page-show-plan.jpg)

Nếu ấn vào step 3 luôn (skip step 2) sẽ nhận message lỗi:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-landing-page-err.jpg)

Nếu ấn vào step 2, sẽ activate plan, Phải chờ 1 lúc rồi F5 lại, thì sẽ thấy Status thay đổi từ Pending sang Subscribed:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-landing-page-activated-plan.jpg)

Giờ Ấn vào step 3, sẽ show ra account sử dụng service của Publisher:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-landing-page-show-acc.jpg)

Quay lại Azure sẽ thấy, SaaS status đã chuyển sang Subscribed:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-landing-page-from-portal.jpg)

## 4.6. Demo Webhook API activity

Demo phần Connection Webhook.  
Giả sử User muốn change plan từ Azure portal.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-landing-page-change-plan-from-portal.jpg)

Ngay sau đó, App Landing Page sẽ nhận được noti trong log:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-landing-page-log.jpg)

log kiểu này:

```
Data received from Webhook is:  {'id': 'xxx', 'activityId': 'yyy', 'publisherId': 'zzz', 'offerId': 'aaaa-preview', 'planId': 'bbb', 'quantity': 1, 'subscriptionId': 'xxx', 'timeStamp': '2024-01-08T08:16:14.4208476Z', 'action': 'ChangePlan', 'status': 'InProgress', 'operationRequestSource': 'Azure', 'subscription': {'id': 'xxx', 'name': 'test1', 'publisherId': 'vvv', 'offerId': 'ccc-preview', 'planId': 'free_plan', 'quantity': None, 'beneficiary': {'emailId': 'xxx', 'objectId': 'yyy', 'tenantId': 'zzz', 'puid': 'eee'}, 'purchaser': {'emailId': 'xxx', 'objectId': 'ccc', 'tenantId': 'aaa', 'puid': 'eee'}, 'allowedCustomerOperations': ['Read'], 'sessionMode': 'None', 'isFreeTrial': False, 'isTest': False, 'sandboxType': 'None', 'saasSubscriptionStatus': 'Subscribed', 'term': {'startDate': '2024-01-08T00:00:00Z', 'endDate': '2024-02-07T00:00:00Z', 'termUnit': 'P1M', 'chargeDuration': None}, 'autoRenew': True, 'created': '2024-01-08T07:52:17.8056241Z', 'lastModified': '2024-01-08T08:04:25.8751858Z'}, 'purchaseToken': None}
```

Bạn sẽ cần code để LandingPage xử lý webhook notification đó trong vòng 10s, nếu quá 10s, Azure sẽ mặc định action "Change Plan" từ phía user là thành công.  
Cái này có nói trong 1 tài liệu: https://learn.microsoft.com/en-us/partner-center/marketplace/partner-center-portal/pc-saas-fulfillment-life-cycle#update-initiated-from-the-commercial-marketplace


## 4.7. Troubleshoot

### 4.7.1. Lỗi về authority

```
Selected user account does not exist in tenant 'XXX YYY' and cannot access the application 'zzz' in that tenant
```

Lỗi này mình gặp phải khi cố gắng purchase offer từ 1 tenant khác:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-landing-page-error-login.jpg)

Đáng nhẽ nó phải như này:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azmarketplace-saas-offer-landing-page-ok-login.jpg)

Nguyên nhân: Used the wrong endpoint. URL dùng để get `access_token` cần phải là: `https://login.microsoftonline.com/PUBLISHER_TENANT_ID/`

Giải thích:  
Landing Page sẽ dùng App Entra ID để authenticate đến các endpoint khác nhau dùng cho các mục đích khác nhau.  
- Khi User login bằng account MS của họ, Landing Page sẽ phải gửi request đến `https://login.microsoftonline.com/common/` để User có thể login.   
- Khi User đã login, Landing Page sẽ cần get thông tin từ `SaaS fulfillment Subscription APIs`. Mà để get thông tin thì Landing Page cần 1 `access_token`, token đó được lấy bằng cách request đến endpoint `https://login.microsoftonline.com/PUBLISHER_TENANT_ID/`.  
=> Thế nên trong code cần xử lý để phân biệt rõ các authority khác nhau dùng để authenticate.  

Tham khảo từ Postman collect của MS: https://github.com/microsoft/commercial-marketplace-resources/blob/main/src/postman/MCM_APIs.postman_collection.json

Tài liệu về Authority:  
https://learn.microsoft.com/en-us/entra/identity-platform/msal-client-application-configuration#authority  
https://learn.microsoft.com/en-us/troubleshoot/azure/active-directory/error-code-aadsts50020-user-account-identity-provider-does-not-exist  


# 5. Sử dụng Azure SaaS Acelerator

Sau khi tìm hiểu thì mình thấy MS có 1 cái github repo để build Landing Page luôn:

https://microsoft.github.io/Mastering-the-Marketplace/saas-accelerator/

https://github.com/Azure/Commercial-Marketplace-SaaS-Accelerator

Sử dụng repo này để build thì sẽ đảm bảo nhanh gọn, đáp ứng gần đủ các yêu cầu của LandingPage, lại còn code được verify security và update thường xuyên.

Hơn là phải tự mò để build từ đầu. 

Có điều nhược điểm là phải tìm cách để làm quen với ngôn ngữ C# .NET MVC


# REFERENCES

1 demo hình ảnh nhìn từ view người dùng của SaaS Customer:  
https://github.com/Azure/Commercial-Marketplace-SaaS-Accelerator/blob/main/docs/Customer-Experience.md

Youtube Course về Mastering Marketplace, SaaS:  
https://www.youtube.com/watch?v=9PCTioPbI8M&list=PLmsFUfdnGr3wWUaB-QkSaQRHBNYKZj5PM&ab_channel=MicrosoftReactor  
https://microsoft.github.io/Mastering-the-Marketplace/partner-center/saas/  

Hướng dẫn create saas offer:   
https://learn.microsoft.com/en-us/partner-center/marketplace/create-new-saas-offer 

Nên tạo offer dev:  
https://learn.microsoft.com/en-us/partner-center/marketplace/plan-saas-dev-test-offer  

SaaS fulfillment API integration là rất quan trọng:  
https://learn.microsoft.com/en-us/partner-center/marketplace/partner-center-portal/pc-saas-fulfillment-apis
Register your SaaS application in the Azure portal as explained in Register a Microsoft Entra Application. Afterwards, use the most current version of this interface for development: SaaS fulfillment Subscription APIs v2 and SaaS fulfillment Operations APIs v2.

Link các project demo SaaS:  
https://github.com/Ercenk/ContosoAMPBasic  
https://github.com/microsoft/Commercial-Marketplace-SaaS-Manual-On-Boarding  
https://github.com/Azure/Commercial-Marketplace-SaaS-Accelerator  
https://github.com/microsoft/commercial-marketplace-resources  

Landing page dùng python flask:  
https://github.com/Azure-Samples/ms-identity-python-webapp  

Project chứa POSTMAN collection, call đến MS Commercial API:  
https://github.com/microsoft/commercial-marketplace-resources 

Landing page dùng python fastapi:  
https://github.com/dudil/ms-identity-python-webapp

Mấy project tham khảo:  
https://github.com/dudil/fastapi_msal  
https://github.com/Azure-Samples/ms-identity-python-webapp/issues/72  

1 số link về msal (MS authentication library):  
https://learn.microsoft.com/en-us/python/api/msal/msal.application.confidentialclientapplication?view=msal-py-latest  
https://learn.microsoft.com/en-us/azure/databricks/dev-tools/app-aad-token  


