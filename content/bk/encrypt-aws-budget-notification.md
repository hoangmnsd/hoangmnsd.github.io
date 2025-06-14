---
title: "AWS Budget notification"
date: 2024-11-01T21:56:40+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [AWS,Budget]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "AWS Budget Alert trigger notification..."
---

# Story

Việc kiểm soát AWS Budget hết sức quan trọng, các bạn chắc hẳn ko muốn bị vượt quá hạn mức AWS Account free tier khi sử dụng.

Bài này là 1 tutorial được làm lại theo bài tutorial có sẵn. 

Manual action để create Budget cho AWS account, khi Alert reached, nó sẽ send message đến SNS topic.

1 Lambda function subscribe topic đó sẽ được trigger/invoke và sẽ làm đủ loại action mà bạn mong muốn.

# Steps

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-budget-choose-type.jpg)

Click Custom để chỉnh sửa tiếp:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-budget-choose-type-custom.jpg)

Next để đi lần lượt các step sau:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-budget-all-steps.jpg)

Cái này alert khi forcasted trigger, ko cần lắm thì remove đi:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-budget-remove-alert3.jpg)

step create budget:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-budget-review.jpg)

Tạo AWS SNS Topic, nên chọn Standard, ko nên chọn FIFO vì có thể bị lỗi format trên AWS Budget Alert setting:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-budget-sns-topic.jpg)

Tạo SNS Topic xong, quay lại AWS Budget paste ARN của SNS Topic vào, hiện màu xanh là OK:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-budget-sns-topic-input-ok.jpg)

Troubleshoot: Nếu Paste vào Chỗ Configure Alert của Budget, nếu báo lỗi thì check vào chữ Permission để xem:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-budget-sns-topic-input-err.jpg)

Xem Lỗi thiếu permission hiện như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-budget-sns-topic-input-err-notes.jpg)

Cần sửa SNS Topic Policy để add access cho Budget có quyền publish messsage:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-budget-sns-topic-access-policy.jpg)

Trên AWS Budget hiện tick xanh là OK:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-budget-sns-topic-access-policy-ok.jpg)

Tự tạo 1 Lambda function, xử lý logic send notification tới Telegram, Discord, Slack, Teams chẳng hạn. 

Chỗ này ko có ảnh

Edit SNS Topic, add subscription từ Lambda function vừa tạo đến:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-budget-sns-topic-subsciption.jpg)

Xong rồi, giờ chờ AWS Budget nó reached Alert để xem có trigger Lambda hay ko?

Khi trigger Lambda sẽ nhận được event như sau:

```json
{
    "Records": [
        {
            "EventSource": "aws:sns",
            "EventVersion": "1.0",
            "EventSubscriptionArn": "XXX",
            "Sns": {
                "Type": "Notification",
                "MessageId": "YYY",
                "TopicArn": "ZZZ",
                "Subject": "AWS Budgets: My Monthly Cost Budget has exceeded your alert threshold",
                "Message": "AWS Budget Notification November 01, 2024\nAWS Account XXX\n\nDear AWS Customer,\n\nYou requested that we alert you when the ACTUAL Cost associated with your My Monthly Cost Budget budget is greater than $0.01 for the current month. The ACTUAL Cost associated with this budget is $0.52. You can find additional details below and by accessing the AWS Budgets dashboard [1].\n\nBudget Name: My Monthly Cost Budget\nBudget Type: Cost\nBudgeted Amount: $2.00\nAlert Type: ACTUAL\nAlert Threshold: > $0.01\nACTUAL Amount: $0.52\n\n[1] https://console.aws.amazon.com/billing/home#/budgets\n",
                "Timestamp": "2024-11-01T23:37:16.504Z",
                "SignatureVersion": "1","MessageAttributes": {}
            }
        }
    ]
}
```

Từ đó bạn có thể tùy ý làm việc với Lambda function để logic bất cứ message đi đâu bạn muốn

# Chú ý

Nghe nói, Thông thường AWS Budget được update khoảng 6-8 tiếng 1 lần

# REFERENCES

https://hands-on.cloud/aws-solutions/automate-aws-budget-notifications/



