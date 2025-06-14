---
title: "Using Azure Machine Learning Studio and Azure OpenAI service"
date: 2025-01-09T21:46:36+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Azure,MachineLearning,OpenAI]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Deploy model to Azure Machine Learning Studio"
---

# Deploy realtime endpoint to Azure Machine Learning Studio

Follow this tutorial: https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Labs/01-machine-learning.html

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-create.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-create-ws-ok.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-ws-inside.jpg)

Cần add Role assignment cho RG:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-ws-add-role.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-ws-add-role-for-user.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-ws-add-role-for-user-ok.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-launch-studio.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-studio-ui.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-task-type.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-data-set-type.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-data-set-source.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-data-set-source-des.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-data-set-source-upload.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-data-set-create.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-task-type-ok.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-task-setting.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-task-setting-add-config.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-task-setting-add-config-all.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-compute.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-review.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-running.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-completed.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-metric.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-deploy-realtime-endpoint.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-deploy-realtime-endpoint-conf.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-deploy-realtime-endpoint-err.jpg)

Solution: https://learn.microsoft.com/en-us/answers/questions/2044338/cant-run-real-time-deployment-for-best-model-in-az

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-deploy-realtime-endpoint-err-solution.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-deploy-realtime-endpoint-err-solution-2.jpg)

Deploy lại lần nữa:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-deploy-realtime-endpoint-2.jpg)

Deploy success Real-time Endpoint:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-deploy-realtime-endpoint-ok.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-deploy-realtime-endpoint-success.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-test-endpoint.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-exer01-submit-auto-ml-job-test-endpoint-code.jpg)

# Deploy and use Azure OpenAI 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-openai-create.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-openai-create-2.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-openai-create-2-failed.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-openai-create-azure-open-ai-ok.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-openai-create-azure-open-ai-service.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-openai-create-azure-open-ai-service-nw.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-openai-create-azure-open-ai-service-nw-2.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-openai-create-azure-open-ai-service-ok.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-openai-azure-foundry-portal.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-openai-azure-foundry-portal-select-catalog.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-openai-azure-foundry-portal-select-customize.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-openai-azure-foundry-portal-deploy-ok.jpg)

Chat gặp lỗi:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-openai-azure-foundry-portal-deploy-chat-error.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-openai-azure-foundry-portal-deploy-chat-error-explain.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-openai-azure-foundry-portal-deploy-chat-ok.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-openai-azure-foundry-portal-deploy-chat-ok-via-python.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ml-studio-openai-azure-foundry-portal-not-yet-deploy-chat-error.jpg)

