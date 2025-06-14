---
title: "Streamlit with authentication via Google"
date: 2025-03-20T21:46:36+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Streamlit,Python,Google]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Streamlit with authentication via Google"
---

Project link: https://gitlab.com/inmessionante/test-streamlit-docker

# About

This project demonstrate the Streamlit use case with login page (login by Google) 

and interact with Google Sheet Private base on personal user data.

# Prepare on GCP

3 ảnh sau để cho bước setup authen bằng Google OIDC:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/google-auth-platform-audience.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/google-auth-platform-branding.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/google-auth-platform-clients.jpg)

Tạo file Google Sheet private có data như sau, cột A là unique email của mỗi user:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/google-sheet-private-data.jpg)

Enable Google Sheet API service:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/google-sheet-api-enable.jpg)

Enable Google Drive API service:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/google-drive-api-enable.jpg)

Create Service account:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/google-sheet-svc-account.jpg)

Save Credential file:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/google-sheet-api-save-cred.jpg)

file save về hãy rename thành `credentials.json` và đặt vào folder `.streamlit/credentials.json` (cái này dùng cho `gspread`)

Share file excel with service account vừa tạo:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/google-sheet-share-with-svc-account.jpg)

Update file `./.streamlit/secrets.toml` với credential đã save: (Cái này dùng cho Streamlit connection)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/google-sheet-config-streamlit-file.jpg)

# Demo 

User login bằng email có trong file Google sheet, sẽ chỉ nhìn thấy data của row tương ứng với email đó trong file Google sheet

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/streamlit-ggsheet-private-login.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/streamlit-ggsheet-private-login-2.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/streamlit-ggsheet-private-dashboard.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/streamlit-ggsheet-private-show-data.jpg)

User cũng chỉ có thể update data của họ trong file Google sheet

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/streamlit-ggsheet-private-show-data-edit.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/streamlit-ggsheet-private-show-data-edited.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/streamlit-ggsheet-private-show-data-edited-show.jpg)

# Deploy

Run local:
```sh
# activate .venv first
pip install -r requirements.txt
streamlit run app.py
```

Build Docker image:
```sh
docker build -t test-streamlit-app:0.0.3 .
```

Run Docker Compose:
```sh
docker-compose up -d
```

# Docker image version info

- test-streamlit-app:0.0.1: sample app without login page
- test-streamlit-app:0.0.2: app with login page use Google oidc
- test-streamlit-app:0.0.3: add feature to read/update Google sheet private

# References

https://docs.streamlit.io/develop/tutorials/authentication/google

https://www.youtube.com/watch?v=D0D4Pa22iG0

https://docs.streamlit.io/develop/tutorials/databases/private-gsheet
