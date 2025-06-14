---
title: "Playaround with Google Apps Script"
date: 2023-12-06T23:09:57+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Notes]
tags: [GoogleAppScripts]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Đây chỉ là note lại để nhớ về sau, chú ý khi dùng Google Apps Script."
---

# Tạo 1 button trên Google Sheet để call API

Tạo 1 file Google Sheet tùy ý, 

Điền data linh tinh từ A1 đến F6.

vào `Extension -> Apps Script` như này để mở ra trang Code editor của GAS:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/gas-menu-to-gas.jpg)

paste đoạn code sau vào rồi save:

```js
function onOpen() {
  let ui = SpreadsheetApp.getUi();
  ui.createMenu('Hoangmnsd')
  .addItem('Format items', 'formatReport')
  .addItem('Call TestApi', 'callTestApi')
  .addItem('writeData Test', 'writeDataToRange')
  .addToUi();
}

function formatReport() {
  let sheet = SpreadsheetApp.getActiveSpreadsheet();
  let headers = sheet.getRange('A1:F1');
  let table = sheet.getDataRange();

  headers.setFontWeight('bold');
  headers.setFontColor('white');
  headers.setBackground('#52489C');

  table.setFontFamily('Roboto');
  table.setHorizontalAlignment('center');
  table.setBorder(true, true, true, true, false, true, '#52489C', SpreadsheetApp.BorderStyle.SOLID);
}

function callTestApi() {
  var targetUrl = 'https://ifconfig.co/json'; // Replace with your target URL

  var headers = {
    'Content-Type': 'application/json'
  };
  
  var options = {
    'method': 'GET',
    'headers': headers,
    'muteHttpExceptions': true,
    'followRedirects': true,
  };
  
  var response = UrlFetchApp.fetch(targetUrl, options);
  var responseContent = response.getContentText();
  Logger.log(responseContent);
}

function writeDataToRange() {
  //Create a two-dimensional array with the values to be written to the range.
  var dataToBeWritten = [
      ["Student", "English Grade", "Math Grade"],
      ["Erik B", "A", "C"],
      ["Lisa K", "B", "A"],
      ["Faye N", "A-", "A"],
      ["Rose A", "B", "B"],
      ["Derek P", "B-", "A-"]
  ];

  //Write the data to the range A1:C6 in Sheet1
  SpreadsheetApp.getActive().getRange("Sheet1!G1:I6").setValues(dataToBeWritten);
}

```

Bạn có thể chọn từng function để test run ở đây:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/gas-test-debug.jpg)

Bạn F5 lại GoogleSheet rồi sẽ thấy Menu `Hoangmnsd` hiện ra, ấn vào sẽ thấy các lựa chọn để call từng function khác nhau, data sẽ hiện thị lên GooGle Sheet luôn:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/gas-test-menu-button.jpg)

Nói chung là vậy, khá tiện lợi và trực quan. 

Ngoài ra bạn còn có thể xây dựng 1 trang Web có giao diện rất đẹp mắt (dùng CSS, HTML) bằng GAS nữa nhé. Refer: https://www.youtube.com/playlist?list=PLv9Pf9aNgemt82hBENyneRyHnD-zORB3l

# Suy nghĩ của mình

Ban đầu định sử dụng GAS để call API đến Binance sau đó ghi all data ra Excel cho dễ nhìn, nhưng sau khi tìm hiểu thì mới biết Binance chặn IP từ Mỹ, (hoặc là IP của Google Server). Thế nên mình nghĩ đến việc chạy function call qua 1 proxy ở VN. Nhưng sự thực thì ko thể làm thế được. 

Do GAS sử dụng hàm `UrlFetchApp` của riêng họ để call API, mà hàm đó lại ko hỗ trợ proxy, nói chung tất cả các request của GAS đều phải đi qua Server của Google bên Mỹ. Điều này thực sự hạn chế mình rất nhiều. GAS cũng ko hỗ trợ Python nên ko có cách nào để run thông qua proxy cả.

# CREDIT

Clip dễ hiểu cho người mới bắt đầu:  
https://www.youtube.com/watch?v=Nd3DV_heK2Q&ab_channel=saperis

Kênh hướng dẫn dùng GAS để build 1 web app có giao diện:  
https://www.youtube.com/playlist?list=PLv9Pf9aNgemt82hBENyneRyHnD-zORB3l

Hướng dẫn dùng python để read write data vào Google Sheet:  
https://www.youtube.com/watch?v=4ssigWmExak&ab_channel=LearnGoogleSheets%26ExcelSpreadsheets

1 tài liệu khá chi tiết về GAS:  
https://github.com/tanaikech/taking-advantage-of-Web-Apps-with-google-apps-script

1 bài nói về dùng javascript để call Binance API:  
https://javascript.plainenglish.io/using-binance-api-to-get-the-users-trading-history-e459c643878b

Ko có cách nào để query all transactions mà ko loop từng cặp symbol:  
https://www.reddit.com/r/binance/comments/khlsv9/how_to_query_api_in_order_to_get_all_transactions/

Tài liệu chính thức của Binance về REST API:  
https://github.com/binance/binance-spot-api-docs/blob/master/rest-api.md

https://stackoverflow.com/questions/47803249/urlfetchapp-with-proxy:  
UrlFetchApp sẽ đi qua Google server (thường là bên Mỹ). Nên nếu 1 trang web chặn IP Mỹ thì sẽ ko thể run Google App Script được. Mà GAS cũng ko support proxy nên sẽ ko thể run qua proxy của nước khác. 

1 ông nào đó list all symbol coin:  
https://stackoverflow.com/a/66697397/9922066

doc về phần deposit history, nếu thực sự cần thiết thì khả năng là phải truyền params cứ 3 tháng 1, từ khi mới chơi đến hiện tại, nghĩa là chia ra 4 request cho 1 năm rồi merge result lại: 
https://developers.binance.com/docs/wallet/endpoints/deposite-history