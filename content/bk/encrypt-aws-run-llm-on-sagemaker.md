---
title: "AWS: Run LLM on SageMaker"
date: 2024-08-09T21:56:40+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [LLM,SageMaker,AWS]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Run LLM on AWS SageMaker"
---

## Overview

SageMaker là 1 AWS service cung cấp khả năng quản lý/build/deploy/run các Machine Learning task.

Có 1 vài term mà mình chạm đến:

- Application -> Notebook instance: bạn tạo 1 VM riêng cho việc chạy jupyter code notebook, thích hợp cho việc dùng chung cả team.
- Admin -> Domain - user trong domain: chắc là để tạo group các user làm việc tập trung theo 1 domain nào đó.
- Inference -> Models: Bạn deploy các models lên đây, chưa tính tiền.
- Inference -> Endpoint Configuration: Endpoint config, chưa tính tiền. Bạn có thể dùng cái này để tạo ra Endpoints.
- Inference -> Endpoints: Các model bạn deploy sẽ tạo ra các endpoints, `InService` càng lâu càng tốn nhiều tiền.
- Có kiểu Real-time endpoint và Serverless endpoint: real-time thì ko dùng cũng tốn tiền. Serverless tính tiền kiểu pay-as-you-go.
- Nhưng deploy kiểu Serverless có nhiều hạn chế, ví dụ support 1GPU thôi, RAM chỉ max là 6GB thôi, Image max 10GB thôi. Code sample tìm khó, mình gặp lỗi liên tục và vẫn chưa deploy đc Model mình muốn lên Serverless vì lỗi.
- Có thể deploy Endpoints, dùng xong thì xóa đi, khi nào cần thì làm deploy lại từ cái Endpoint configurations.

## 1. Deploy Model to SageMaker from Jupyter Notebook instance

Mình làm theo video này: Có vẻ dễ hiểu nhất, hướng dẫn dùng JupyterNoteBook instance, deploy model lên SageMaker, rồi còn test connect từ Lambda, API Gateway luôn: https://www.youtube.com/watch?v=A9Pu4xg-Nas

Hướng làm sẽ là bạn deploy 1 Jupyter Notebook instance (ví dụ: m2.medium).
Rồi bạn lên đó code, deploy model lên 1 instance khác, type có thể phải mạnh hơn vì bạn sẽ run Model trên đó (ví dụ: ml.g4dn.xlarge - có GPU).
instance chứa model đó có endpoint và chạy liên tục `InService` để serve request real-time. (Tốn tiền)

Khi bạn chọn AWS SageMaker -> QuickSetup nó sẽ tạo 1 Domain bắt đầu = "QuickSetupDomain-xxx", tạo 1 User profile trong domain đó "default-xxx", tạo 2 S3 bucket "sagemaker-studio-xxx-6vkb4c8n3v8", "sagemaker-us-east-1-USERACCOUNTID". 
Và bạn ko thay đổi được tên các cái setup này.

Tạo notebook instance:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-create-notebook-instance1.jpg)

Chờ notebook instance được deploy, thì click "JupyterLab":
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-create-notebook-instance1-in-svc.jpg)

Chọn cái này:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-conda-pytorch-p310.jpg)

Dùng pip install 1 số lib đầu tiên: 
```python
!pip install transformers einops accelerate bitsandbytes
```
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-install-pip-1.jpg)

Chờ install xong:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-install-pip-1-ok.jpg)

gõ tiếp 1 vài command:
```python
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
from transformers import pipeline
import torch
import base64
```
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-command-2.jpg)

Bởi vì mình sẽ dùng HuggingFace model sau: Mình sẽ dùng Model này: https://huggingface.co/MBZUAI/LaMini-T5-738M/tree/main

Nên copy cái này:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-hf-model-copy.jpg)

và gõ tiếp command:
```python
checkpoint = "MBZUAI/LaMini-T5-738M"
```
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-command-3.jpg)

gõ tiếp các command, `device_map="auto"` bị lỗi nên mình chuyển thành `cpu`:
```python
tokenizer = AutoTokenizer.from_pretrained(checkpoint)
base_model = AutoModelForSeq2SeqLM.from_pretrained(checkpoint, device_map="cpu", torch_dtype=torch.float32)
```
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-command-4.jpg)

Thêm command sau để install langchain:
```python
!pip install langchain
!pip install langchain-community langchain-core
```
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-command-5.jpg)

Thêm command sau để tạo function:
```python
def llm_pipeline():
    pipe = pipeline(
        'text2text-generation',
        model=base_model,
        tokenizer=tokenizer,
        max_length=256,
        do_sample=True,
        temperature=0.3,
        top_p=0.95
    )
    local_llm = HuggingFacePipeline(pipeline=pipe)
    return local_llm
```

```python
input_prompt = "Write an article about Blockchain"
model = llm_pipeline()
generateed_text = model(input_prompt)
generateed_text
```

Bạn phải chờ 1 lúc để command trả về câu trả lời Blockchain:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-command-6.jpg)

```python
pip show sagemaker
```

Lên huggingface model url, copy đoạn code họ cung cấp:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-hf-copy-code-snipet.jpg)

Paste vào JupiterLabs, nhưng sẽ sửa lại 1 chút:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-sagemaker-paste-edited.jpg)

Nếu bị lỗi này, nghĩa là bạn nên kéo lên, upgrade version của sagemaker lib:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-err-sagemaker.jpg)
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-sagemaker.jpg)

Nếu vẫn có dấu * như hình này nghĩa là code vẫn đang Running:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-running.jpg)


Vào SageMaker dashboard chỗ này sẽ thấy Endpoint đang đc tạo:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-deploy-endpoint.jpg)
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-deploy-endpointc.jpg)
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-deploy-models.jpg)

Quay lại JupyterLab thấy code đã chạy xong:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-deploy-models-result.jpg)

Endpoint đã inservice chú tên endpoint là Global nên sẽ là unique:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-deploy-models-insvc.jpg)

Tiếp test thử 1 số payload:

```
prompt = "Write a short article about Donald Trump"
payload = {
    "inputs": prompt,
    "parameters": {
        "do_sample": True
    }
}

response = predictor.predict(payload)
print(response)
```
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-next-question.jpg)

Câu trả lời sẽ có nhanh hơn vì ta đã deploy rồi.


Giờ với 1 script python ta chỉ cần endpoint là có thể call đến SageMaker model vừa deploy xong:

```py
ENDPOINT = "huggingface-pytorch-tgi-inference-2024-08-10-11-33-33-545"
import boto3
runtime = boto3.client('runtime.sagemaker')
response = runtime.invoke_endpoint(EndpointName=ENDPOINT, ContentType="application/json", Body=json.dumps(payload))
prediction = json.loads(response['Body'].read().decode('utf-8'))
prediction
```
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-jupyterlabs-next-question-with-boto3.jpg)

Youtuber `AI Anytime` đã thử tạo Lambda function và dùng boto3 để call đến endpoint đó:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-call-fromlambda-youtube.jpg)

## 2. Pricing

Đây là billing tạm tính sau 1 ngày mình dùng, du chỉ run model được 1 lần và gửi question 2,3 câu.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-billing-temporary.jpg)

Đụng đến Machine Learning là đụng đến tiền nong tốn kém, hãy cẩn thận.

https://stackoverflow.com/questions/76212134/options-for-stopping-sagemaker-endpoint-to-avoid-charges

Nếu cứ để Endpoint `InService` mãi, Bạn sẽ tốn nhiều tiền cho nó ngay cả khi ko dùng.  
Bạn có thể delete Endpoint đi, tạo lại nó khi cần bằng `Endpoint Configurations`.  
Có cả lựa chọn Serverless endpoint, chỉ trả tiền cho số lần invoke_endpoint, nhưng nó ko support GPU instance như `ml.g4dn.xlarge`:
> Also try serverless inference (https://docs.aws.amazon.com/sagemaker/latest/dg/serverless-endpoints.html) if you're experimenting/for demos, so you're only paying per invocations rather than for the entire time the endpoint is in service.
> @durga_sury's answer is great, however, I should point out that Serverless Inference does not support GPU-enabled instances such as the ml.g4dn.xlarge

https://www.reddit.com/r/aws/comments/xfugrw/comment/iorsmnj/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button


## 3. Deploy Model to SageMaker serverless endpoint from localhost

## 3.1. Story

Hướng dẫn deploy từ NoteBook instance của AWS chỉ hợp làm team share với nhau. Còn làm cá nhân thì như vậy quá tốn kém. 

Chỉ cần code ở máy local và send request lên API để deploy model lên SageMaker là được.

Kết hợp clip này: https://www.youtube.com/watch?v=B0lFMUBnGEw

Kết hợp github này: https://github.com/siddhardhan23/llama2-deploy-aws-sagemaker

Kết hợp bài này: https://www.philschmid.de/sagemaker-llama-llm

Mình muốn làm kiểu Serverless Endpoint để ko mất tiền cho thời gian ko sử dụng. Tài liệu này: 

https://docs.aws.amazon.com/sagemaker/latest/dg/serverless-endpoints-create.html

Chú ý về size của SageMaker Serverless endpoint default chỉ có ~3GB RAM, disk 5GB. Vì thể deploy các model nặng rất khó:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-serverless-memory-size-docs.jpg)

Mình sẽ test bắt đầu với `https://huggingface.co/Qwen/CodeQwen1.5-7B-Chat/tree/main`

### 3.2. Deploy

Cần tạo 1 user để sau này có ACCESS_KEY request đến AWS API (Sau này dùng xong sẽ xóa key đi cho an toàn):

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-iam-user.jpg)

Cần tạo 1 account Hunggingface để lấy Huggingface Token và accept term của 1 số model.

```sh
python3.10 -m pip install boto3 sagemaker
```

Run file `create-sagemaker-serverless-endpoint.py`:

```sh
python create-sagemaker-serverless-endpoint.py
```

### 3.3. Troubleshoot

#### Lỗi IAM getRole

```s
  File "/home/ubuntu/.local/lib/python3.10/site-packages/botocore/client.py", line 565, in _api_call
    return self._make_api_call(operation_name, kwargs)
  File "/home/ubuntu/.local/lib/python3.10/site-packages/botocore/client.py", line 1017, in _make_api_call
    raise error_class(parsed_response, operation_name)
botocore.exceptions.ClientError: An error occurred (AccessDenied) when calling the GetRole operation: User: arn:aws:iam::USERACCOUNTID:user/sagemaker_deployment is not authorized to perform: iam:GetRole on resource: role sagemaker_execution_role because no identity-based policy allows the iam:GetRole action
```
bản thân User `sagemaker_deployment` chưa được gán đủ quyền, và cũng ko tồn tại role `sagemaker_execution_role`.
Minh cần phải add thêm policy cho user:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-user-policy.jpg)

Role ARN thì mình lấy 1 cái role được tạo từ trước khi mình Quicksetup Domain nó tự tạo cho:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-role-default.jpg)

File `config.json` cần sửa cái `ROLE_NAME` theo cái role đã có sẵn trong IAM.

#### Lỗi syntax name của model ko được có ký tự đặc biệt (như dấu chấm)

```s
    return self._make_api_call(operation_name, kwargs)
  File "/home/ubuntu/.local/lib/python3.10/site-packages/botocore/client.py", line 1017, in _make_api_call
    raise error_class(parsed_response, operation_name)
botocore.exceptions.ClientError: An error occurred (ValidationException) when calling the CreateModel operation: 1 validation error detected: Value 'codeqwen1.5-7b-chat-gguf-hoangmnsd-model' at 'modelName' failed to satisfy constraint: Member must satisfy regular expression pattern: ^[a-zA-Z0-9]([\-a-zA-Z0-9]*[a-zA-Z0-9])?
```

#### Lỗi quotas

```s
    res = self.sagemaker_client.create_endpoint(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/botocore/client.py", line 565, in _api_call
    return self._make_api_call(operation_name, kwargs)
  File "/home/ubuntu/.local/lib/python3.10/site-packages/botocore/client.py", line 1017, in _make_api_call
    raise error_class(parsed_response, operation_name)
botocore.errorfactory.ResourceLimitExceeded: An error occurred (ResourceLimitExceeded) when calling the CreateEndpoint operation: The account-level service limit 'Memory size in MB per serverless endpoint' is 3072 MBs, with current utilization of 0 MBs and a request delta of 4096 MBs. Please use AWS Service Quotas to request an increase for this quota. If AWS Service Quotas is not available, contact AWS support to request an increase for this quota.
```
Mặc định của account thì Serverless RAM chỉ có 3072MB nhưng bạn lại set `memory_size_in_mb` là 4096 chẳng hạn, cao hơn quotas. Mình chưa thử request tăng quota vì ko cần lắm, mình quyết định sửa code giảm `memory_size_in_mb` xuống 3072


#### Lỗi ko download được .safetensors

```s
Couldn't call 'get_role'' to get Role ARN from role name sagemaker_deployment to get Role path.
----------------------------------------*Traceback (most recent call last):
  File "/opt/devops/LLM-lab/sagemaker-lab/create-sagemaker-serverless-endpoint.py", line 66, in <module>
    # Deploy model to an endpoint
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/huggingface/model.py", line 319, in deploy
    return super(HuggingFaceModel, self).deploy(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/model.py", line 1749, in deploy
    self.sagemaker_session.endpoint_from_production_variants(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 5728, in endpoint_from_production_variants
    return self.create_endpoint(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 4586, in create_endpoint
    self.wait_for_endpoint(endpoint_name, live_logging=live_logging)
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 5371, in wait_for_endpoint
    raise exceptions.UnexpectedStatusException(
sagemaker.exceptions.UnexpectedStatusException: Error hosting endpoint codeqwen15-7b-chat-gguf-hoangmnsd-model-2024-08-11-07-04-51-412: Failed. Reason: Received server error (0) from model with message "An error occurred while handling request as the model process exited.". See https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#logEventViewer:group=/aws/sagemaker/Endpoints/codeqwen15-7b-chat-gguf-hoangmnsd-model-2024-08-11-07-04-51-412 in account USERACCOUNTID for more information.. Try changing the instance type or reference the troubleshooting page https://docs.aws.amazon.com/sagemaker/latest/dg/async-inference-troubleshooting.html


# Cloudwatch log:

[2m2024-08-11T07:23:37.228062Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Args { model_id: "Qwen/CodeQwen1.5-7B-Chat-GGUF", revision: None, validation_workers: 2, sharded: None, num_shard: Some(1), quantize: None, dtype: None, trust_remote_code: false, max_concurrent_requests: 128, max_best_of: 2, max_stop_sequences: 4, max_input_length: 2048, max_total_tokens: 4096, waiting_served_ratio: 1.2, max_batch_prefill_tokens: 4096, max_batch_total_tokens: 8192, max_waiting_tokens: 20, hostname: "0.0.0.0", port: 8080, shard_uds_path: "/tmp/text-generation-server", master_addr: "localhost", master_port: 29500, huggingface_hub_cache: Some("/tmp"), weights_cache_override: None, disable_custom_kernels: false, json_output: false, otlp_endpoint: None, cors_allow_origin: [], watermark_gamma: None, watermark_delta: None, ngrok: false, ngrok_authtoken: None, ngrok_domain: None, ngrok_username: None, ngrok_password: None, env: false }
[2m2024-08-11T07:23:37.228249Z[0m [32m INFO[0m [1mdownload[0m: [2mtext_generation_launcher[0m[2m:[0m Starting download process.
[2m2024-08-11T07:25:21.732515Z[0m [31mERROR[0m [1mdownload[0m: [2mtext_generation_launcher[0m[2m:[0m Download encountered an error: Traceback (most recent call last):
  File "/opt/conda/lib/python3.9/site-packages/text_generation_server/utils/hub.py", line 96, in weight_files
    filenames = weight_hub_files(model_id, revision, extension)
  File "/opt/conda/lib/python3.9/site-packages/text_generation_server/utils/hub.py", line 37, in weight_hub_files
    raise EntryNotFoundError(
huggingface_hub.utils._errors.EntryNotFoundError: No .safetensors weights found for model Qwen/CodeQwen1.5-7B-Chat-GGUF and revision None.
During handling of the above exception, another exception occurred:
Traceback (most recent call last):
  File "/opt/conda/bin/text-generation-server", line 8, in <module>
    sys.exit(app())
  File "/opt/conda/lib/python3.9/site-packages/text_generation_server/cli.py", line 109, in download_weights
    utils.weight_files(model_id, revision, extension)
  File "/opt/conda/lib/python3.9/site-packages/text_generation_server/utils/hub.py", line 101, in weight_files
    pt_filenames = weight_hub_files(model_id, revision, extension=".bin")
  File "/opt/conda/lib/python3.9/site-packages/text_generation_server/utils/hub.py", line 37, in weight_hub_files
    raise EntryNotFoundError(
huggingface_hub.utils._errors.EntryNotFoundError: No .bin weights found for model Qwen/CodeQwen1.5-7B-Chat-GGUF and revision None.
Error: DownloadError
```

Nguyên nhân là SageMaker ko support file GGUF. SageMaker chỉ support đuôi GPTQ, AWQ: https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.1-GGUF/discussions/15#655f1eb76821269b27fd8ce2


#### Lỗi insufficient memory

```s
sagemaker.config INFO - Not applying SDK defaults from location: /home/ubuntu/.config/sagemaker/config.yaml
Couldn't call 'get_role' to get Role ARN from role name sagemaker_deployment to get Role path.
--------------------------*Traceback (most recent call last):
  File "/opt/devops/LLM-lab/sagemaker-lab/create-sagemaker-serverless-endpoint.py", line 68, in <module>
    llm = llm_model.deploy(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/huggingface/model.py", line 319, in deploy
    return super(HuggingFaceModel, self).deploy(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/model.py", line 1749, in deploy
    self.sagemaker_session.endpoint_from_production_variants(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 5728, in endpoint_from_production_variants
    return self.create_endpoint(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 4586, in create_endpoint
    self.wait_for_endpoint(endpoint_name, live_logging=live_logging)
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 5371, in wait_for_endpoint
    raise exceptions.UnexpectedStatusException(
sagemaker.exceptions.UnexpectedStatusException: Error hosting endpoint codeqwen15-7b-chat-hoangmnsd-endpoint: Failed. Reason: Ping failed due to insufficient memory.. Try changing the instance type or reference the troubleshooting page https://docs.aws.amazon.com/sagemaker/latest/dg/async-inference-troubleshooting.html'


# Cloudwatch log:

[2m2024-08-11T07:47:14.768273Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Args { model_id: "Qwen/CodeQwen1.5-7B-Chat", revision: None, validation_workers: 2, sharded: None, num_shard: Some(1), quantize: None, dtype: None, trust_remote_code: false, max_concurrent_requests: 128, max_best_of: 2, max_stop_sequences: 4, max_input_length: 2048, max_total_tokens: 4096, waiting_served_ratio: 1.2, max_batch_prefill_tokens: 4096, max_batch_total_tokens: 8192, max_waiting_tokens: 20, hostname: "0.0.0.0", port: 8080, shard_uds_path: "/tmp/text-generation-server", master_addr: "localhost", master_port: 29500, huggingface_hub_cache: Some("/tmp"), weights_cache_override: None, disable_custom_kernels: false, json_output: false, otlp_endpoint: None, cors_allow_origin: [], watermark_gamma: None, watermark_delta: None, ngrok: false, ngrok_authtoken: None, ngrok_domain: None, ngrok_username: None, ngrok_password: None, env: false }
[2m2024-08-11T07:47:14.768456Z[0m [32m INFO[0m [1mdownload[0m: [2mtext_generation_launcher[0m[2m:[0m Starting download process.
[2m2024-08-11T07:48:36.572375Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Download file: model-00001-of-00004.safetensors
[2m2024-08-11T07:49:37.085851Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Downloaded /tmp/models--Qwen--CodeQwen1.5-7B-Chat/snapshots/7b0cc3380fe815e6f08fe2f80c03e05a8b1883d8/model-00001-of-00004.safetensors in 0:01:00.
[2m2024-08-11T07:49:37.085896Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Download: [1/4] -- ETA: 0:03:00
[2m2024-08-11T07:49:37.097217Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Download file: model-00002-of-00004.safetensors
```

Mình thử chuyển sang model `MBZUAI/LaMini-T5-738M` nhẹ hơn chỉ có khoảng 2.95GB.

Nhưng vẫn bị lỗi RAM DownloadError:

```s
  File "/opt/devops/LLM-lab/sagemaker-lab/create-sagemaker-serverless-endpoint.py", line 68, in <module>
    llm = llm_model.deploy(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/huggingface/model.py", line 319, in deploy
    return super(HuggingFaceModel, self).deploy(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/model.py", line 1749, in deploy
    self.sagemaker_session.endpoint_from_production_variants(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 5728, in endpoint_from_production_variants
    return self.create_endpoint(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 4586, in create_endpoint
    self.wait_for_endpoint(endpoint_name, live_logging=live_logging)
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 5371, in wait_for_endpoint
    raise exceptions.UnexpectedStatusException(
sagemaker.exceptions.UnexpectedStatusException: Error hosting endpoint laminit5-738m-hoangmnsd-endpoint: Failed. Reason: Ping failed due to insufficient memory.. Try changing the instance type or reference the troubleshooting page https://docs.aws.amazon.com/sagemaker/latest/dg/async-inference-troubleshooting.html


# Cloudwatch log:
[2m2024-08-11T08:29:55.863090Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Args { model_id: "MBZUAI/LaMini-T5-738M", revision: None, validation_workers: 2, sharded: None, num_shard: Some(1), quantize: None, dtype: None, trust_remote_code: false, max_concurrent_requests: 128, max_best_of: 2, max_stop_sequences: 4, max_input_length: 2048, max_total_tokens: 4096, waiting_served_ratio: 1.2, max_batch_prefill_tokens: 4096, max_batch_total_tokens: 8192, max_waiting_tokens: 20, hostname: "0.0.0.0", port: 8080, shard_uds_path: "/tmp/text-generation-server", master_addr: "localhost", master_port: 29500, huggingface_hub_cache: Some("/tmp"), weights_cache_override: None, disable_custom_kernels: false, json_output: false, otlp_endpoint: None, cors_allow_origin: [], watermark_gamma: None, watermark_delta: None, ngrok: false, ngrok_authtoken: None, ngrok_domain: None, ngrok_username: None, ngrok_password: None, env: false }
[2m2024-08-11T08:29:55.863282Z[0m [32m INFO[0m [1mdownload[0m: [2mtext_generation_launcher[0m[2m:[0m Starting download process.
[2m2024-08-11T08:30:04.836935Z[0m [33m WARN[0m [2mtext_generation_launcher[0m[2m:[0m No safetensors weights found for model MBZUAI/LaMini-T5-738M at revision None. Downloading PyTorch weights.
[2m2024-08-11T08:30:04.857846Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Download file: pytorch_model.bin
[2m2024-08-11T08:30:41.259152Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Downloaded /tmp/models--MBZUAI--LaMini-T5-738M/snapshots/5fc690b5cf88f188fd7b8fd19aee6c43af183d8b/pytorch_model.bin in 0:00:36.
[2m2024-08-11T08:30:41.259264Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Download: [1/1] -- ETA: 0
[2m2024-08-11T08:30:41.259366Z[0m [33m WARN[0m [2mtext_generation_launcher[0m[2m:[0m No safetensors weights found for model MBZUAI/LaMini-T5-738M at revision None. Converting PyTorch weights to safetensors.
[2m2024-08-11T08:31:20.364603Z[0m [31mERROR[0m [1mdownload[0m: [2mtext_generation_launcher[0m[2m:[0m Download process was signaled to shutdown with signal 9: 
Error: DownloadError
```

Check log thấy đã down về được, nhưng ko hiểu sao bị shutdown with signal 9.

Thử chuyển sang `ml.g4dn.xlarge` vẫn bị lỗi tương tự:
```s
    return super(HuggingFaceModel, self).deploy(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/model.py", line 1749, in deploy
    self.sagemaker_session.endpoint_from_production_variants(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 5728, in endpoint_from_production_variants
    return self.create_endpoint(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 4586, in create_endpoint
    self.wait_for_endpoint(endpoint_name, live_logging=live_logging)
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 5371, in wait_for_endpoint
    raise exceptions.UnexpectedStatusException(
sagemaker.exceptions.UnexpectedStatusException: Error hosting endpoint laminit5-738m-hoangmnsd-endpoint: Failed. Reason: Ping failed due to insufficient memory.. Try changing the instance type or reference the troubleshooting page https://docs.aws.amazon.com/sagemaker/latest/dg/async-inference-troubleshooting.html

# Cloudwatch log:

[2m2024-08-11T08:58:29.461460Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Args { model_id: "MBZUAI/LaMini-T5-738M", revision: None, validation_workers: 2, sharded: None, num_shard: Some(1), quantize: None, dtype: None, trust_remote_code: false, max_concurrent_requests: 128, max_best_of: 2, max_stop_sequences: 4, max_input_length: 2048, max_total_tokens: 4096, waiting_served_ratio: 1.2, max_batch_prefill_tokens: 4096, max_batch_total_tokens: 8192, max_waiting_tokens: 20, hostname: "0.0.0.0", port: 8080, shard_uds_path: "/tmp/text-generation-server", master_addr: "localhost", master_port: 29500, huggingface_hub_cache: Some("/tmp"), weights_cache_override: None, disable_custom_kernels: false, json_output: false, otlp_endpoint: None, cors_allow_origin: [], watermark_gamma: None, watermark_delta: None, ngrok: false, ngrok_authtoken: None, ngrok_domain: None, ngrok_username: None, ngrok_password: None, env: false }
[2m2024-08-11T08:58:29.461647Z[0m [32m INFO[0m [1mdownload[0m: [2mtext_generation_launcher[0m[2m:[0m Starting download process.
[2m2024-08-11T08:59:51.736949Z[0m [33m WARN[0m [2mtext_generation_launcher[0m[2m:[0m No safetensors weights found for model MBZUAI/LaMini-T5-738M at revision None. Downloading PyTorch weights.
[2m2024-08-11T08:59:51.781071Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Download file: pytorch_model.bin
[2m2024-08-11T09:00:29.564279Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Downloaded /tmp/models--MBZUAI--LaMini-T5-738M/snapshots/5fc690b5cf88f188fd7b8fd19aee6c43af183d8b/pytorch_model.bin in 0:00:37.
[2m2024-08-11T09:00:29.564374Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Download: [1/1] -- ETA: 0
[2m2024-08-11T09:00:29.564452Z[0m [33m WARN[0m [2mtext_generation_launcher[0m[2m:[0m No safetensors weights found for model MBZUAI/LaMini-T5-738M at revision None. Converting PyTorch weights to safetensors.
Error: DownloadError
[2m2024-08-11T09:01:08.181942Z[0m [31mERROR[0m [1mdownload[0m: [2mtext_generation_launcher[0m[2m:[0m Download process was signaled to shutdown with signal 9: 
```

Đọc 1 comment:
> Your container got sigkill because it didn't have anough RAM to do the weights conversion. (https://github.com/huggingface/text-generation-inference/issues/451#issuecomment-1590887778)

Có vẻ như nguyên nhân là 3GB RAM của Serverless endpoint mặc dù donwload được model 3GB về nhưng còn cần phải weights conversion nữa. Và như thế thì 3GB là ko đủ.
Chuyển sang `TheBloke/TinyLlama-1.1B-python-v0.1-AWQ` 700MB thì ko bị lỗi đó nữa

#### Lỗi Could not import Flash Attention enabled models: CUDA is not available

```s
    self.sagemaker_session.endpoint_from_production_variants(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 5728, in endpoint_from_production_variants
    return self.create_endpoint(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 4586, in create_endpoint
    self.wait_for_endpoint(endpoint_name, live_logging=live_logging)
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 5371, in wait_for_endpoint
    raise exceptions.UnexpectedStatusException(
sagemaker.exceptions.UnexpectedStatusException: Error hosting endpoint tinyllama1-1b-python-v01-hoangmnsd-endpoint: Failed. Reason: Ping failed due to insufficient memory.. Try changing the instance type or reference the troubleshooting page https://docs.aws.amazon.com/sagemaker/latest/dg/async-inference-troubleshooting.html

# Cloudwatch Log:

[2m2024-08-11T09:34:57.275284Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Args { model_id: "TheBloke/TinyLlama-1.1B-python-v0.1-AWQ", revision: None, validation_workers: 2, sharded: None, num_shard: Some(1), quantize: None, dtype: None, trust_remote_code: false, max_concurrent_requests: 128, max_best_of: 2, max_stop_sequences: 4, max_input_length: 2048, max_total_tokens: 4096, waiting_served_ratio: 1.2, max_batch_prefill_tokens: 4096, max_batch_total_tokens: 8192, max_waiting_tokens: 20, hostname: "0.0.0.0", port: 8080, shard_uds_path: "/tmp/text-generation-server", master_addr: "localhost", master_port: 29500, huggingface_hub_cache: Some("/tmp"), weights_cache_override: None, disable_custom_kernels: false, json_output: false, otlp_endpoint: None, cors_allow_origin: [], watermark_gamma: None, watermark_delta: None, ngrok: false, ngrok_authtoken: None, ngrok_domain: None, ngrok_username: None, ngrok_password: None, env: false }
[2m2024-08-11T09:34:57.275430Z[0m [32m INFO[0m [1mdownload[0m: [2mtext_generation_launcher[0m[2m:[0m Starting download process.
[2m2024-08-11T09:35:02.448288Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Download file: model.safetensors
[2m2024-08-11T09:35:17.274389Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Downloaded /tmp/models--TheBloke--TinyLlama-1.1B-python-v0.1-AWQ/snapshots/a41947ea2b361cc12892f005aaeb8a55151e2015/model.safetensors in 0:00:14.
[2m2024-08-11T09:35:17.274454Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Download: [1/1] -- ETA: 0
[2m2024-08-11T09:35:37.348319Z[0m [32m INFO[0m [1mdownload[0m: [2mtext_generation_launcher[0m[2m:[0m Successfully downloaded weights.
[2m2024-08-11T09:35:37.348556Z[0m [32m INFO[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Starting shard 0 [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T09:35:47.360285Z[0m [32m INFO[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Waiting for shard 0 to be ready... [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T09:35:57.374189Z[0m [32m INFO[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Waiting for shard 0 to be ready... [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T09:36:07.387239Z[0m [32m INFO[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Waiting for shard 0 to be ready... [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T09:36:17.169618Z[0m [33m WARN[0m [2mtext_generation_launcher[0m[2m:[0m Could not import Flash Attention enabled models: CUDA is not available
[2m2024-08-11T09:36:17.400726Z[0m [32m INFO[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Waiting for shard 0 to be ready... [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T09:36:27.413939Z[0m [32m INFO[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Waiting for shard 0 to be ready... [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T09:36:31.932515Z[0m [31mERROR[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Shard complete standard error output:
/opt/conda/lib/python3.9/site-packages/bitsandbytes/cextension.py:33: UserWarning: The installed version of bitsandbytes was compiled without GPU support. 8-bit optimizers, 8-bit multiplication, and GPU quantization are unavailable.
  warn("The installed version of bitsandbytes was compiled without GPU support. " [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T09:36:31.932556Z[0m [31mERROR[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Shard process was signaled to shutdown with signal 9 [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T09:36:32.029976Z[0m [31mERROR[0m [2mtext_generation_launcher[0m[2m:[0m Shard 0 failed to start
[2m2024-08-11T09:36:32.030017Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Shutting down shards
Error: ShardCannotStart
```

Thử chuyển sang instance type ko có GPU: `ml.m5.xlarge` vẫn lỗi:

```s
# Cloudwatch Log:

[2m2024-08-11T10:04:22.959345Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Args { model_id: "TheBloke/TinyLlama-1.1B-python-v0.1-AWQ", revision: None, validation_workers: 2, sharded: None, num_shard: Some(1), quantize: None, dtype: None, trust_remote_code: false, max_concurrent_requests: 128, max_best_of: 2, max_stop_sequences: 4, max_input_length: 2048, max_total_tokens: 4096, waiting_served_ratio: 1.2, max_batch_prefill_tokens: 4096, max_batch_total_tokens: 8192, max_waiting_tokens: 20, hostname: "0.0.0.0", port: 8080, shard_uds_path: "/tmp/text-generation-server", master_addr: "localhost", master_port: 29500, huggingface_hub_cache: Some("/tmp"), weights_cache_override: None, disable_custom_kernels: false, json_output: false, otlp_endpoint: None, cors_allow_origin: [], watermark_gamma: None, watermark_delta: None, ngrok: false, ngrok_authtoken: None, ngrok_domain: None, ngrok_username: None, ngrok_password: None, env: false }
[2m2024-08-11T10:04:22.959526Z[0m [32m INFO[0m [1mdownload[0m: [2mtext_generation_launcher[0m[2m:[0m Starting download process.
[2m2024-08-11T10:04:28.587578Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Download file: model.safetensors
[2m2024-08-11T10:04:35.676244Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Downloaded /tmp/models--TheBloke--TinyLlama-1.1B-python-v0.1-AWQ/snapshots/a41947ea2b361cc12892f005aaeb8a55151e2015/model.safetensors in 0:00:07.
[2m2024-08-11T10:04:35.676297Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Download: [1/1] -- ETA: 0
[2m2024-08-11T10:04:37.113071Z[0m [32m INFO[0m [1mdownload[0m: [2mtext_generation_launcher[0m[2m:[0m Successfully downloaded weights.
[2m2024-08-11T10:04:37.113278Z[0m [32m INFO[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Starting shard 0 [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T10:04:41.508273Z[0m [33m WARN[0m [2mtext_generation_launcher[0m[2m:[0m Could not import Flash Attention enabled models: CUDA is not available
[2m2024-08-11T10:04:47.151309Z[0m [32m INFO[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Waiting for shard 0 to be ready... [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T10:04:52.602876Z[0m [31mERROR[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Shard complete standard error output:
/opt/conda/lib/python3.9/site-packages/bitsandbytes/cextension.py:33: UserWarning: The installed version of bitsandbytes was compiled without GPU support. 8-bit optimizers, 8-bit multiplication, and GPU quantization are unavailable.
  warn("The installed version of bitsandbytes was compiled without GPU support. " [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T10:04:52.603008Z[0m [31mERROR[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Shard process was signaled to shutdown with signal 9 [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T10:04:52.699716Z[0m [31mERROR[0m [2mtext_generation_launcher[0m[2m:[0m Shard 0 failed to start
[2m2024-08-11T10:04:52.699760Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Shutting down shards
Error: ShardCannotStart
```

#### Lỗi ValueError: quantization is not available on CPU

Thử Sửa code bỏ 2 dòng này:
```py
'SM_NUM_GPUS': json.dumps(1),
'HF_MODEL_QUANTIZE': "bitsandbytes",
```
Và sửa `health_check_timeout = 1200` (20min)

Thì lại bị lỗi:
```s
[2m2024-08-11T10:36:18.314852Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Args { model_id: "TheBloke/TinyLlama-1.1B-python-v0.1-AWQ", revision: None, validation_workers: 2, sharded: None, num_shard: None, quantize: Some(Bitsandbytes), dtype: None, trust_remote_code: false, max_concurrent_requests: 128, max_best_of: 2, max_stop_sequences: 4, max_input_length: 2048, max_total_tokens: 4096, waiting_served_ratio: 1.2, max_batch_prefill_tokens: 4096, max_batch_total_tokens: 8192, max_waiting_tokens: 20, hostname: "0.0.0.0", port: 8080, shard_uds_path: "/tmp/text-generation-server", master_addr: "localhost", master_port: 29500, huggingface_hub_cache: Some("/tmp"), weights_cache_override: None, disable_custom_kernels: false, json_output: false, otlp_endpoint: None, cors_allow_origin: [], watermark_gamma: None, watermark_delta: None, ngrok: false, ngrok_authtoken: None, ngrok_domain: None, ngrok_username: None, ngrok_password: None, env: false }
[2m2024-08-11T10:36:18.315055Z[0m [32m INFO[0m [1mdownload[0m: [2mtext_generation_launcher[0m[2m:[0m Starting download process.
[2m2024-08-11T10:37:43.378840Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Download file: model.safetensors
[2m2024-08-11T10:37:51.742956Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Downloaded /tmp/models--TheBloke--TinyLlama-1.1B-python-v0.1-AWQ/snapshots/a41947ea2b361cc12892f005aaeb8a55151e2015/model.safetensors in 0:00:08.
[2m2024-08-11T10:37:51.743918Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Download: [1/1] -- ETA: 0
[2m2024-08-11T10:38:11.654111Z[0m [32m INFO[0m [1mdownload[0m: [2mtext_generation_launcher[0m[2m:[0m Successfully downloaded weights.
[2m2024-08-11T10:38:11.654344Z[0m [32m INFO[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Starting shard 0 [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T10:38:21.666273Z[0m [32m INFO[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Waiting for shard 0 to be ready... [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T10:38:31.678217Z[0m [32m INFO[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Waiting for shard 0 to be ready... [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T10:38:41.706131Z[0m [32m INFO[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Waiting for shard 0 to be ready... [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T10:38:51.724629Z[0m [32m INFO[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Waiting for shard 0 to be ready... [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T10:39:01.747657Z[0m [32m INFO[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Waiting for shard 0 to be ready... [2m[3mrank[0m[2m=[0m0[0m
[2m2024-08-11T10:39:01.796340Z[0m [33m WARN[0m [2mtext_generation_launcher[0m[2m:[0m Could not import Flash Attention enabled models: CUDA is not available
[2m2024-08-11T10:39:02.458703Z[0m [31mERROR[0m [2mtext_generation_launcher[0m[2m:[0m Error when initializing model
Traceback (most recent call last):
  File "/opt/conda/bin/text-generation-server", line 8, in <module>
    sys.exit(app())
  File "/opt/conda/lib/python3.9/site-packages/typer/main.py", line 311, in __call__
    return get_command(self)(*args, **kwargs)
  File "/opt/conda/lib/python3.9/site-packages/click/core.py", line 1130, in __call__
    return self.main(*args, **kwargs)
  File "/opt/conda/lib/python3.9/site-packages/typer/core.py", line 778, in main
    return _main(
  File "/opt/conda/lib/python3.9/site-packages/typer/core.py", line 216, in _main
    rv = self.invoke(ctx)
  File "/opt/conda/lib/python3.9/site-packages/click/core.py", line 1657, in invoke
    return _process_result(sub_ctx.command.invoke(sub_ctx))
  File "/opt/conda/lib/python3.9/site-packages/click/core.py", line 1404, in invoke
    return ctx.invoke(self.callback, **ctx.params)
  File "/opt/conda/lib/python3.9/site-packages/click/core.py", line 760, in invoke
    return __callback(*args, **kwargs)
  File "/opt/conda/lib/python3.9/site-packages/typer/main.py", line 683, in wrapper
    return callback(**use_params)  # type: ignore
  File "/opt/conda/lib/python3.9/site-packages/text_generation_server/cli.py", line 78, in serve
    server.serve(
  File "/opt/conda/lib/python3.9/site-packages/text_generation_server/server.py", line 175, in serve
    asyncio.run(
  File "/opt/conda/lib/python3.9/asyncio/runners.py", line 44, in run
    return loop.run_until_complete(main)
  File "/opt/conda/lib/python3.9/asyncio/base_events.py", line 634, in run_until_complete
    self.run_forever()
  File "/opt/conda/lib/python3.9/asyncio/base_events.py", line 601, in run_forever
    self._run_once()
  File "/opt/conda/lib/python3.9/asyncio/base_events.py", line 1905, in _run_once
    handle._run()
  File "/opt/conda/lib/python3.9/asyncio/events.py", line 80, in _run
    self._context.run(self._callback, *self._args)
> File "/opt/conda/lib/python3.9/site-packages/text_generation_server/server.py", line 142, in serve_inner
    model = get_model(
  File "/opt/conda/lib/python3.9/site-packages/text_generation_server/models/__init__.py", line 195, in get_model
    return CausalLM(
  File "/opt/conda/lib/python3.9/site-packages/text_generation_server/models/causal_lm.py", line 465, in __init__
    raise ValueError("quantization is not available on CPU")
ValueError: quantization is not available on CPU
[2m2024-08-11T10:39:03.149677Z[0m [31mERROR[0m [1mshard-manager[0m: [2mtext_generation_launcher[0m[2m:[0m Shard complete standard error output:
/opt/conda/lib/python3.9/site-packages/bitsandbytes/cextension.py:33: UserWarning: The installed version of bitsandbytes was compiled without GPU support. 8-bit optimizers, 8-bit multiplication, and GPU quantization are unavailable.
  warn("The installed version of bitsandbytes was compiled without GPU support. "
Traceback (most recent call last):
  File "/opt/conda/bin/text-generation-server", line 8, in <module>
    sys.exit(app())
  File "/opt/conda/lib/python3.9/site-packages/text_generation_server/cli.py", line 78, in serve
    server.serve(
  File "/opt/conda/lib/python3.9/site-packages/text_generation_server/server.py", line 175, in serve
    asyncio.run(
  File "/opt/conda/lib/python3.9/asyncio/runners.py", line 44, in run
    return loop.run_until_complete(main)
  File "/opt/conda/lib/python3.9/asyncio/base_events.py", line 647, in run_until_complete
    return future.result()
  File "/opt/conda/lib/python3.9/site-packages/text_generation_server/server.py", line 142, in serve_inner
    model = get_model(
  File "/opt/conda/lib/python3.9/site-packages/text_generation_server/models/__init__.py", line 195, in get_model
    return CausalLM(
  File "/opt/conda/lib/python3.9/site-packages/text_generation_server/models/causal_lm.py", line 465, in __init__
    raise ValueError("quantization is not available on CPU")
ValueError: quantization is not available on CPU
 [2m[3mrank[0m[2m=[0m0[0m
Error: ShardCannotStart
[2m2024-08-11T10:39:03.222448Z[0m [31mERROR[0m [2mtext_generation_launcher[0m[2m:[0m Shard 0 failed to start
[2m2024-08-11T10:39:03.222492Z[0m [32m INFO[0m [2mtext_generation_launcher[0m[2m:[0m Shutting down shards
```

#### Lỗi Image size 11464101106 is greater than supported size 10737418240

Nếu dùng `get_huggingface_llm_image_uri("huggingface",version="2.2.0")` thì sẽ bị lỗi:
```s
    self.sagemaker_session.endpoint_from_production_variants(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 5728, in endpoint_from_production_variants
    return self.create_endpoint(
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 4586, in create_endpoint
    self.wait_for_endpoint(endpoint_name, live_logging=live_logging)
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/session.py", line 5371, in wait_for_endpoint
    raise exceptions.UnexpectedStatusException(
sagemaker.exceptions.UnexpectedStatusException: Error hosting endpoint tinyllama1-1b-python-v01-hoangmnsd-endpoint: Failed. Reason: Image size 11464101106 is greater than supported size 10737418240. Try changing the instance type or reference the troubleshooting page https://docs.aws.amazon.com/sagemaker/latest/dg/async-inference-troubleshooting.html

```

Tới đây Chịu, Chuyển sang làm theo tutorial này thì lại OK:
https://www.philschmid.de/sagemaker-serverless-huggingface-distilbert

và làm theo y nguyên tutorial này cũng OK: https://github.com/huggingface/notebooks/blob/main/sagemaker/19_serverless_inference/sagemaker-notebook.ipynb

Log OK:
```s
$ python3.10 create-sagemaker-serverless-endpoint.py 
sagemaker.config INFO - Not applying SDK defaults from location: /etc/xdg/sagemaker/config.yaml
sagemaker.config INFO - Not applying SDK defaults from location: /home/ubuntu/.config/sagemaker/config.yaml
Couldn't call 'get_role' to get Role ARN from role name sagemaker_deployment to get Role path.
---!
model deployed to Sagemaker
```

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-endpoint-serverless-1.jpg)
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-endpoint-serverless.jpg)
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-endpoint-serverless-config.jpg)
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-sagemaker-endpoint-serverless-model.jpg)

model trên nhẹ/đơn giản quá, invoke_endpoint ko có lỗi gì.

Mình sẽ sửa model thành cái `TheBloke/TinyLlama-1.1B-python-v0.1-AWQ`

#### Deploy OK nhưng lỗi khi invoke_endpoint

Thử sừa file trên chỗ HD_MODEL_ID thôi thành `'HF_MODEL_ID':'TheBloke/TinyLlama-1.1B-python-v0.1-AWQ'`

Deploy model đc nhưng invoke_endpoint lại bị lỗi:
```s
$ python3.10 create-sagemaker-serverless-endpoint.py 
sagemaker.config INFO - Not applying SDK defaults from location: /etc/xdg/sagemaker/config.yaml
sagemaker.config INFO - Not applying SDK defaults from location: /home/ubuntu/.config/sagemaker/config.yaml
Couldn't call 'get_role' to get Role ARN from role name sagemaker_deployment to get Role path.
---!
model deployed to Sagemaker
Traceback (most recent call last):
  File "/opt/devops/LLM-lab/sagemaker-lab/create-sagemaker-serverless-endpoint.py", line 67, in <module>
    res = predictor.predict(data=data)
  File "/home/ubuntu/.local/lib/python3.10/site-packages/sagemaker/base_predictor.py", line 212, in predict
    response = self.sagemaker_session.sagemaker_runtime_client.invoke_endpoint(**request_args)
  File "/home/ubuntu/.local/lib/python3.10/site-packages/botocore/client.py", line 565, in _api_call
    return self._make_api_call(operation_name, kwargs)
  File "/home/ubuntu/.local/lib/python3.10/site-packages/botocore/client.py", line 1017, in _make_api_call
    raise error_class(parsed_response, operation_name)
botocore.errorfactory.ModelError: An error occurred (ModelError) when calling the InvokeEndpoint operation: Received client error (400) from model with message "{
  "code": 400,
  "type": "InternalServerException",
  "message": "\u0027llama\u0027"
}
". See https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#logEventViewer:group=/aws/sagemaker/Endpoints/tinyllama1-1b-python-v01-hoangmnsd-endpoint in account 856233045188 for more information.


# Cloudwatch log:
https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/$252Faws$252Fsagemaker$252FEndpoints$252Ftinyllama1-1b-python-v01-hoangmnsd-endpoint/log-events/AllTraffic$252F1c17ee2437692fb56aea43a82351435b-67eb496d28b24fd9a659037bcb81baf5

python: can't open file '/usr/local/bin/deep_learning_container.py': [Errno 13] Permission denied
KeyError: 'llama'
```

Thử deploy lại, sửa code đoạn này:
```py
# create Hugging Face Model Class
huggingface_model = HuggingFaceModel(
  name=model_name,
  env=hub,                        # configuration for loading model from Hub
  role=role,                      # iam role with permissions to create an Endpoint
  transformers_version="4.27",    # transformers version used
  pytorch_version="1.13",         # pytorch version used
  py_version='py39',              # python version used
)
```

Thì lại vẫn deploy OK nhưng invoke_endpoint có lỗi:
```s
KeyError: 'llama'
```

Link này nói lỗi trên có thể do version của transformers_version < 4.28: https://github.com/huggingface/transformers/issues/23129

Thử deploy lại, sửa code đoạn này:
```py
# create Hugging Face Model Class
huggingface_model = HuggingFaceModel(
  name=model_name,
  env=hub,                        # configuration for loading model from Hub
  role=role,                      # iam role with permissions to create an Endpoint
  transformers_version="4.28.1",  # transformers version used
  pytorch_version="2.0.0",        # pytorch version used
  py_version='py310',             # python version used
)
```

Thì lại bị lỗi:
```s
    predictor = huggingface_model.deploy(
  File "/home/ubuntu/.local/lib/python3.9/site-packages/sagemaker/huggingface/model.py", line 319, in deploy
    return super(HuggingFaceModel, self).deploy(
  File "/home/ubuntu/.local/lib/python3.9/site-packages/sagemaker/model.py", line 1749, in deploy
    self.sagemaker_session.endpoint_from_production_variants(
  File "/home/ubuntu/.local/lib/python3.9/site-packages/sagemaker/session.py", line 5728, in endpoint_from_production_variants
    return self.create_endpoint(
  File "/home/ubuntu/.local/lib/python3.9/site-packages/sagemaker/session.py", line 4586, in create_endpoint
    self.wait_for_endpoint(endpoint_name, live_logging=live_logging)
  File "/home/ubuntu/.local/lib/python3.9/site-packages/sagemaker/session.py", line 5371, in wait_for_endpoint
    raise exceptions.UnexpectedStatusException(
sagemaker.exceptions.UnexpectedStatusException: Error hosting endpoint tinyllama1-1b-python-v01-hoangmnsd-endpoint: Failed. Reason: Image size 13605595695 is greater than supported size 10737418240. Try changing the instance type or reference the troubleshooting page https://docs.aws.amazon.com/sagemaker/latest/dg/async-inference-troubleshooting.html
```

#### Kết luận tạm thời

Như vậy là vấn đề ở chỗ khi deploy OK thì invoke_endpoint bị lỗi `KeyError: 'llama'`, muốn fix thì phải upgrade version của `huggingface_model` (các `py_version, pytorch_version, transformers_version`).

Nhưng upgrade version của chúng thì làm Image to ra và size image lớn hơn mức support của SageMaker serverless endpoint (10GB)

# REFERENCES

Docs về Serverless endpoint: https://docs.aws.amazon.com/sagemaker/latest/dg/serverless-endpoints-create.html

https://aws.amazon.com/blogs/machine-learning/call-an-amazon-sagemaker-model-endpoint-using-amazon-api-gateway-and-aws-lambda/

https://www.philschmid.de/sagemaker-llama-llm

https://medium.com/@michael.leigh.stewart/self-hosting-large-language-models-using-aws-sagemaker-2568965159f1

https://github.com/aws/deep-learning-containers/tree/master

Create a web UI to interact with LLMs using Amazon SageMaker JumpStart:  
https://aws.amazon.com/blogs/machine-learning/create-a-web-ui-to-interact-with-llms-using-amazon-sagemaker-jumpstart/

Có vẻ dễ hiểu nhất, hướng dẫn dùng JupyterNoteBook instance, deploy model lên SageMaker, rồi còn test connect từ Lambda, API Gateway luôn: 
https://www.youtube.com/watch?v=A9Pu4xg-Nas

Repo của Youtuber mình xem, có nhiều repo rất hay:  
https://github.com/AIAnytime/Search-Your-PDF-App

https://www.youtube.com/watch?v=U72q95dHpRo

Notebook hướng dẫn deploy Stable Diffusion lên SageMaker: 
https://github.com/Stability-AI/aws-jumpstart-examples/blob/main/sdxl-v1-0/sdxl-1-0-jumpstart.ipynb
> This sample notebook shows you how to deploy Stable Diffusion SDXL 1.0 from Stability AI as an endpoint on Amazon SageMaker.

Deploy model trên SageMaker UI: https://www.youtube.com/watch?v=3y_TcDNC0HE

Let's run Llama 3.1 8B Model (Different Ways) using Transformers, Unsloth Chat Studio, and Ollama locally: https://www.youtube.com/watch?v=QpGVF_kElQY

Tutorial chính thức của huggingface: https://github.com/huggingface/notebooks/blob/main/sagemaker/19_serverless_inference/sagemaker-notebook.ipynb