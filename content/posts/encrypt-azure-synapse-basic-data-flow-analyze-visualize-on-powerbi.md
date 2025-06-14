---
title: "Azure Synapse: Analyze data with serverless SQL and visualize it on PowerBI"
date: 2022-06-24T23:36:48+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Azure,Synapse]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "This post is about a demo using Azure Synapse Analytics. Analyze data with serverless SQL, then visualize on Power BI desktop"
---

This post is about a demo using Azure Synapse Analytics. Analyze data with serverless SQL, then visualize on Power BI desktop

# Overview about Azure Synapse Analytics  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-synapse-overview.jpg)

Azure Synapse contains the same *Data Integration* engine and experiences as Azure Data Factory, allowing you to create rich at-scale ETL pipelines without leaving Azure Synapse Analytics.  
- Ingest data from 90+ data sources  
- Code-Free ETL with Data flow activities  
- Orchestrate notebooks, Spark jobs, stored procedures, SQL scripts, and more    

*Synapse SQL*: is the ability to do T-SQL based analytics in Synapse workspace. Synapse SQL has two consumption models: dedicated and serverless. For the dedicated model, use dedicated SQL pools. A workspace can have any number of these pools. To use the serverless model, use the serverless SQL pools.

*Apache Spark*: Big Data engine (used for data preparation, data engineering, ETL, and machine learning)Use Data Explorer as a data platform for building near real-time log analytics and IoT analytics solutionsPipelines are how Azure Synapse provides Data Integration - allowing you to move data between services and orchestrate activities.

# Why I write this

Có thể bạn sẽ thấy khó hiểu khi tại sao ko làm theo các Tutorial của MS document, mà phải tách ra viết như này.  
Thì bởi vì mục đích của mình muốn có 1 cái luồng từ đầu, 1-upload file data lên ADLSGen2, 2-rồi Analize data đó trên Synapse Studio, 3-rồi visualize data đó trên Power BI.  

Nhưng MS document thì chỉ hướng dẫn step 1 và 2 trên 1 file data `NYCTripSmall.parquet` 5MB (nhẹ). Còn step 3 lại làm trên 1 bộ data khác khoảng 50GB (quá nặng).  

Nên bài này giúp bạn làm cả 3 step đó trên 1 file data `NYCTripSmall.parquet` thôi.  

# 1. Place sample data in ADLS Gen2

Download this parquet file to your computer. (`https://azuresynapsestorage.blob.core.windows.net/sampledata/NYCTaxiSmall/NYCTripSmall.parquet`)

In Synapse Studio, navigate to the Data Hub.  
Select Linked.  
Under the category Azure Data Lake Storage Gen2 you'll see an item with a name like `myworkspace` ( Primary - `YOUR_ADLS_GEN2` ).  
Select the container named `YOUR_CONTAINER` (Primary).    
Select Upload and select the `NYCTripSmall.parquet` file you downloaded.  

Once the parquet file is uploaded it is available through two equivalent URIs:  

`https://YOUR_ADLS_GEN2.dfs.core.windows.net/YOUR_CONTAINER/NYCTripSmall.parquet`  
`abfss://YOUR_CONTAINER@YOUR_ADLS_GEN2.dfs.core.windows.net/NYCTripSmall.parquet`

# 2. Analyze data with serverless SQL

In Synapse Studio, go to the Develop hub

Create a new SQL script.

Paste the following code into the script.

```sh
SELECT
    TOP 100 *
FROM
    OPENROWSET(
        BULK 'https://YOUR_ADLS_GEN2.dfs.core.windows.net/YOUR_CONTAINER/NYCTripSmall.parquet',
        FORMAT='PARQUET'
    ) AS [result]
```

Click Run.

Create data exploration database

```sh
CREATE DATABASE DataExplorationDB 
                COLLATE Latin1_General_100_BIN2_UTF8
```

Switch from master to DataExplorationDB using the following command. You can also use the UI control use database to switch your current database:
```sh
USE DataExplorationDB
```

Create external data source:
```sh
CREATE EXTERNAL DATA SOURCE YOUR_EXT_DATASOURCE
WITH ( LOCATION = 'https://YOUR_ADLS_GEN2.dfs.core.windows.net')
```

query from external data source:
```sh
SELECT
    TOP 100 *
FROM
    OPENROWSET(
            BULK '/YOUR_CONTAINER/NYCTripSmall.parquet',
            DATA_SOURCE = 'YOUR_EXT_DATASOURCE',
            FORMAT='PARQUET'
    ) AS [result]
```

# 3. Visualize on Power BI desktop

## 3.1. Prepare external table

Bước này rất quan trọng, nhiều lần mình bị lỗi ở Power BI vì đã ko tạo External Table này với CREDENTIAL

Bước `--8` có thể sẽ thấy khó khi ko biết layout của file parquet là gì, thì có thể dùng cách này:

chuột phải vào file `NYCTripSmall.parquet`, chọn SQL script -> `Create external table` để xem layout table phần đó

Chú ý ta sẽ dùng lại `YOUR_EXT_DATASOURCE`, `YOUR_CONTAINER`, `YOUR_ADLS_GEN2` mà đã tạo ở trên

Bạn nên copy từng step 1 rồi run để hiểu về các step làm gì

```sh
-- 1
USE DataExplorationDB
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'qwe@##@5324aSD127123g'
GO
    
-- 2
CREATE DATABASE SCOPED CREDENTIAL WorkspaceIdentity01 WITH IDENTITY = 'Managed Identity'
GO
    
-- 3
CREATE LOGIN TestUser01 WITH PASSWORD = 'abcdef123!@#'
 GO
    
-- 4
CREATE USER Test01 FOR LOGIN TestUser01
GO
    
-- 5
GRANT REFERENCES ON DATABASE SCOPED CREDENTIAL::WorkspaceIdentity01 TO Test01
        
-- 6
IF NOT EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'YOUR_EXT_DATASOURCE') 
    CREATE EXTERNAL DATA SOURCE [YOUR_EXT_DATASOURCE] 
    WITH (
        LOCATION   = 'https://YOUR_ADLS_GEN2.dfs.core.windows.net/YOUR_CONTAINER',
        CREDENTIAL = WorkspaceIdentity01 
    )
GO
-- 7 
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name = 'SynapseParquetFormat') 
    CREATE EXTERNAL FILE FORMAT [SynapseParquetFormat] 
    WITH ( FORMAT_TYPE = PARQUET)
GO
-- 8
 CREATE EXTERNAL TABLE NYCTripSmallExTable01 (
 [DateID] int,
 [MedallionID] int,
 [HackneyLicenseID] int,
 [PickupTimeID] int,
 [DropoffTimeID] int,
 [PickupGeographyID] int,
 [DropoffGeographyID] int,
 [PickupLatitude] float,
 [PickupLongitude] float,
 [PickupLatLong] nvarchar(4000),
 [DropoffLatitude] float,
 [DropoffLongitude] float,
 [DropoffLatLong] nvarchar(4000),
 [PassengerCount] int,
 [TripDurationSeconds] int,
 [TripDistanceMiles] float,
 [PaymentType] nvarchar(4000),
 [FareAmount] numeric(19,4),
 [SurchargeAmount] numeric(19,4),
 [TaxAmount] numeric(19,4),
 [TipAmount] numeric(19,4),
 [TollsAmount] numeric(19,4),
 [TotalAmount] numeric(19,4)
    )
    WITH (
    LOCATION = 'NYCTripSmall.parquet',
    DATA_SOURCE = [YOUR_EXT_DATASOURCE],
    FILE_FORMAT = [SynapseParquetFormat]
    )
GO
-- 9
SELECT TOP 100 * FROM NYCTripSmallExTable01
GO
```
Nếu run OK hết, Bạn vào Data Hub có thể nhìn thấy được external table `NYCTripSmallExTable01` đã được tạo ra

## 3.2. Visualize on Power BI desktop

Mở Power BI desktop ra, chọn Get Data:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/synapse-power-bi-getdata.jpg)  

Điền thông tin server SQL:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/synapse-power-bi-input-sql-server.jpg)  

Điền account/password:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/synapse-power-bi-account.jpg)  

Màn hình data sẽ hiện ra bên phải:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/synapse-power-bi-navgator.jpg)  

Ấn nút `Load` data:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/synapse-power-bi-loaddata.jpg)  

Chọn các thông số dùng để visualize:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/synapse-power-bi-visualize.jpg)  

Chú ý: Nếu bạn đang ở sau 1 proxy của công ty, bạn sẽ ko thể Get Data được vì lỗi kết nối của Power BI

# Summary

Synapse cung cấp 1 chỗ làm việc tập trung cho Data Engineer

Pipeline của nó giống như NiFi vậy dùng cho mục đính ETL (extract, transform, load data) automatically

Mặc định sẽ có sẵn SQL pool Serverless, tính tiền theo khối lượng data xử lý (1 TB -5 USD)

Có Apache Spark để run code .NET, pyspark, scala cho Machine Learning. Tính tiền theo node.

Dù bạn có tạo ra các external table, external data source thì khi bạn xóa chúng đi cũng ko mất data. Vì thực chất chúng ko persist data, data nằm ở ADLS Gen2 hết.

Các tab Develop Hub, Integrate Hub có thể export ra file json,zip để sau này import lại được (điều này có thể quan trọng trong PaaS)

Azure Synapse sử dụng Synapse RBAC system (đừng nhầm lẫn với Azure RBAC system). Azure RBAC thì bạn có thể dùng ARM code để add role assignment cho 1 identity nào đó. Nhưng Synapse RBAC thì hiện tại ko được hỗ trợ để tự động add role assignment cho 1 identtiy bằng ARM. Ví dụ cho dễ hiểu:  
Bạn muốn dùng ARM code để tạo 1 VM V sẽ có identity I, I sẽ được add role assignment `Synapse Administrator`. Rồi từ đó trong VM V bạn sẽ run các command `az cli: az synapse` để tương tác với Synapse Studio 1 cách programmatically.   
Vấn đề sẽ nảy sinh ở chỗ việc assign role assignment `Synapse Administrator` cho I sẽ ko thể làm bằng ARM code. Mà bạn phải dùng tay, vào Synapse Studio -> Access Control để làm.  

Nhưng hiện chưa thấy cung cấp các Azure ARM template để import SQL script, Pipeline. Mới chỉ có `az cli` làm được thôi. 

Azure Synapse có thể integrate với Github để làm Source Control. Sau khi setup, tất cả thay đổi của Synapse sẽ được lưu lại trên 1 repo trên Github (script SQL, pipeline,,,).  

Khi bạn xóa Synapse đi tạo lại, rồi integrate nó với Github repo cũ, nó có thể khôi phục hết các SQL script, Pipeline cho bạn. (Tuy nhiên tab Data hub sẽ ko phục hồi lại được, chỉ tab Develop hub và Integrate hub mà thôi)

# CREDIT

https://docs.microsoft.com/en-us/azure/synapse-analytics/sql/tutorial-data-analyst  
https://docs.microsoft.com/en-us/azure/synapse-analytics/sql/tutorial-connect-power-bi-desktop  
https://docs.microsoft.com/en-us/azure/synapse-analytics/get-started-analyze-sql-on-demand  
https://docs.microsoft.com/en-us/azure/synapse-analytics/get-started-create-workspace#place-sample-data-into-the-primary-storage-account  
https://www.techtalkcorner.com/create-azure-synapse-anlaytics-serverless-external-table/  
