---
title: "LLM for local running"
date: 2024-08-07T21:56:40+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [LLM,Ubuntu,Windows,MachineLearning,AI]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Nhu cầu về ChatGPT ngày càng lớn, trend LLM đã bùng nổ thời gian gần đây"
---

# Story

Nhu cầu sử dụng AI trong công việc ngày càng lớn trong hiện tại và tương lai

Sau 1 thời gian tìm hiểu mình chia 2 hướng để viết bài:
- Hướng dẫn run AI model local. (**Chính là bài viết này**)
- Hướng dẫn run AI model trên serverless platform.

Mình cần test thử để confirm các use-case sau:
- Run trên local PC (Windows có GPU / ko có GPU, Ubuntu nhân arm64 / amd64)
- Có thể expose to Internet and serve request via API
- Sử dụng với Coding Assistant Agent (Mentat, Continue, Tabby, Github Copilot...)
- Sử dụng Private Documents của cá nhân để input vào AI model, rồi nó sẽ trả lời dựa trên các thông tin đó.

Sau 1 hồi lướt trên mạng thì có nhiều tool hỗ trợ run LLM local nhưng nổi bật nhất và hiện vẫn còn **sống** là:

- llamafile - https://github.com/Mozilla-Ocho/llamafile
- LMStudio - https://lmstudio.ai/
- llama.cpp - https://github.com/ggerganov/llama.cpp
- Ollama - https://github.com/ollama/ollama
- GPT4All - https://github.com/nomic-ai/gpt4all
- vLLM - https://github.com/vllm-project/vllm
- privateGPT - https://github.com/zylon-ai/private-gpt (ko phải tool run LLM mà giao diện để call đến các API LLM, có use-case khá hay)
- kotaemon - https://github.com/cinnamon/kotaemon (tương tự như privateGPT)

Mình sẽ cố gắng đi qua hết các tool này để đánh giá chung.

Server để deploy mình dùng:  
- Ubuntu 20.04 (3vCPU, 18G RAM) arm64
- WSL Ubuntu 22.04, 20.04

# 1. llamafile

## 1.1. Setup on Linux

```sh
curl -L -o llamafile https://github.com/Mozilla-Ocho/llamafile/releases/download/0.8.11/llamafile-0.8.11
curl -L -o mistral.gguf https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.1-GGUF/resolve/main/mistral-7b-instruct-v0.1.Q4_K_M.gguf

# run
./llamafile -m mistral.gguf

# Ctr+C to quit/exit
```

Nó sẽ mở trang web local ở port 8080: http://127.0.0.1:8080

Chat trực tiếp với nó ở đó.


### 1.1.1. Ví dụ summarize HTML URLs

```sh
(
  echo '[INST]Summarize the following text:'
  links -codepage utf-8 \
        -force-html \
        -width 500 \
        -dump https://www.poetryfoundation.org/poems/48860/the-raven |
    sed 's/   */ /g'
  echo '[/INST]'
) | ./llamafile -ngl 9999 \
      -m mistral.gguf \
      -f /dev/stdin \
      -c 0 \
      --temp 0 \
      -n 500 \
      --no-display-prompt 2>/dev/null
```

Máy mình mất rất lâu mới trả lời, phải sau tầm 3-4 phút mới ra log:
```
$ ll
-rw-rw-r-- 1 ubuntu ubuntu         89 Aug  7 08:56 llama.log
-rwxrwxr-x 1 ubuntu ubuntu   29678972 Aug  7 08:54 llamafile*
-rw-rw-r-- 1 ubuntu ubuntu        210 Aug  7 10:10 main.log
-rw-rw-r-- 1 ubuntu ubuntu 4368438944 Aug  7 08:55 mistral.gguf

$ (
>   echo '[INST]Summarize the following text:'
      -f /dev/stdin \
      -c 0 \
      --temp 0 \
      -n 500 \
      --no-display-prompt 2>/dev/null>   links -codepage utf-8 \
>         -force-html \
>         -width 500 \
>         -dump https://www.poetryfoundation.org/poems/48860/the-raven |
>     sed 's/   */ /g'
>   echo '[/INST]'
> ) | ./llamafile -ngl 9999 \
>       -m mistral.gguf \
>       -f /dev/stdin \
>       -c 0 \
>       --temp 0 \
>       -n 500 \
>       --no-display-prompt 2>/dev/null

 The Poetry Foundation is a nonprofit organization that promotes and supports poetry. It offers a variety of resources and programs for poets, including workshops, readings, and awards. The Poetry Foundation also publishes a magazine, Poetry, which features new and established poets, as well as essays, reviews, and interviews. The Poetry Foundation is committed to making poetry accessible and meaningful to a wide audience.
```

### 1.1.2. Ví dụ mô tả ảnh

Download 1 file ảnh về:
```sh
wget https://images.nbcolympics.com/sites/default/files/2021-07/dellaquila-thumbnail.png
```

Download 2 file model về:
```sh
wget https://huggingface.co/Mozilla/llava-v1.5-7b-llamafile/resolve/main/llava-v1.5-7b-Q4_K.gguf
wget https://huggingface.co/Mozilla/llava-v1.5-7b-llamafile/resolve/main/llava-v1.5-7b-mmproj-Q4_0.gguf
```

Mô tả file ảnh:
```sh
./llamafile -ngl 9999 --temp 0 \
  --image dellaquila-thumbnail.png \
  -m llava-v1.5-7b-Q4_K.gguf \
  --mmproj llava-v1.5-7b-mmproj-Q4_0.gguf \
  -e -p '### User: What do you see?\n### Assistant: ' \
  --no-display-prompt 2>/dev/null
```

log:
```
$ ll
-rw-rw-r-- 1 ubuntu ubuntu     846493 Sep  8  2023 dellaquila-thumbnail.png
-rw-rw-r-- 1 ubuntu ubuntu         89 Aug  7 08:56 llama.log
-rwxrwxr-x 1 ubuntu ubuntu   29678972 Aug  7 08:54 llamafile*
-rw-rw-r-- 1 ubuntu ubuntu 4081004224 Nov 20  2023 llava-v1.5-7b-Q4_K.gguf
-rw-rw-r-- 1 ubuntu ubuntu  177415936 Nov 20  2023 llava-v1.5-7b-mmproj-Q4_0.gguf
-rw-rw-r-- 1 ubuntu ubuntu 4288297357 Jul 27 11:36 llava-v1.5-7b-q4.llamafile
-rw-rw-r-- 1 ubuntu ubuntu        210 Aug  7 10:10 main.log
-rw-rw-r-- 1 ubuntu ubuntu 4368438944 Aug  7 08:55 mistral.gguf

$ ./llamafile -ngl 9999 --temp 0 \
>   --image ./dellaquila-thumbnail.png \
>   -m llava-v1.5-7b-Q4_K.gguf \
>   --mmproj llava-v1.5-7b-mmproj-Q4_0.gguf \
>   -e -p '### User: What do you see?\n### Assistant: ' \
>   --no-display-prompt 2>/dev/null
 The image features two men in a wrestling ring, both wearing red and white uniforms. One of the men is in the process of kicking the other man, who is wearing a blue and white uniform. The wrestlers are focused on their match, displaying their athletic abilities.

In the background, there are several other people present, likely spectators or fellow wrestlers. Some of them are standing close to the wrestling ring, while others are further away. The scene captures the intensity and excitement of the wrestling match.
```

Nó mô tả đúng khoảng 60% thôi, đúng là 2 võ sĩ, nhưng bộ môn ko phải wrestling (đấu vật) mà là taekwondo.

### 1.1.3. Request đến API bằng code

Link này giới thiệu cách để request đến API server bằng CURL và Python code:

https://github.com/Mozilla-Ocho/llamafile?tab=readme-ov-file#json-api-quickstart

### 1.1.4. Run như 1 service của Linux

https://github.com/Mozilla-Ocho/llamafile/issues/420

File `/etc/systemd/system/llamafile.service`:
```
[Unit]
Description=Launch llamafile terminal program
After=network.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
EnvironmentFile=/opt/devops/LLM-lab/llamafile-lab/system-service-env/llamafile.env
ExecStart=/bin/bash /opt/devops/LLM-lab/llamafile-lab/llamafile $LLAMA_ARGS
#StandardInput=tty
StandardOutput=file:/opt/devops/LLM-lab/llamafile-lab/system-service-log/llamafile.log
StandardError=file:/opt/devops/LLM-lab/llamafile-lab/system-service-log/llamafile.log
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

File `/opt/devops/LLM-lab/llamafile-lab/system-service-env/llamafile.env`:

```
LLAMA_ARGS=--server --port 8080 --nobrowser --ctx-size 0 -m /opt/devops/LLM-lab/llamafile-lab/llava-v1.5-7b-Q4_K.gguf
```

Run service:

```sh
sudo systemctl daemon-reload
sudo service llamafile start
```

Log như này là OK:

```
$ sudo service llamafile status
● llamafile.service - Launch llamafile terminal program
     Loaded: loaded (/etc/systemd/system/llamafile.service; disabled; vendor preset: enabled)
     Active: active (running) since Thu 2024-08-08 03:00:10 UTC; 2s ago
   Main PID: 280112 (.ape-1.10)
      Tasks: 11 (limit: 21387)
     Memory: 4.0G
     CGroup: /system.slice/llamafile.service
             └─280112 /home/ubuntu/.ape-1.10 /opt/devops/LLM-lab/llamafile-lab/llamafile --server --port 8080 --nobrowser --ctx-size 0 -m /opt/devops/LLM-lab/lla>

Aug 08 03:00:12 ubuntu-oc-gp03 bash[280112]: llama_new_context_with_model:        CPU compute buffer size =  2144.01 MiB
Aug 08 03:00:12 ubuntu-oc-gp03 bash[280112]: llama_new_context_with_model: graph nodes  = 1030
Aug 08 03:00:12 ubuntu-oc-gp03 bash[280112]: llama_new_context_with_model: graph splits = 1
Aug 08 03:00:12 ubuntu-oc-gp03 bash[280112]: {"function":"initialize","level":"INFO","line":489,"msg":"initializing slots","n_slots":1,"tid":"34364393952","times>
Aug 08 03:00:12 ubuntu-oc-gp03 bash[280112]: {"function":"initialize","level":"INFO","line":498,"msg":"new slot","n_ctx_slot":32768,"slot_id":0,"tid":"3436439395>
Aug 08 03:00:12 ubuntu-oc-gp03 bash[280112]: {"function":"server_cli","level":"INFO","line":3090,"msg":"model loaded","tid":"34364393952","timestamp":1723086012}
Aug 08 03:00:12 ubuntu-oc-gp03 bash[280112]: llama server listening at http://127.0.0.1:8080
Aug 08 03:00:12 ubuntu-oc-gp03 bash[280112]: In the sandboxing block!
Aug 08 03:00:12 ubuntu-oc-gp03 bash[280112]: {"function":"server_cli","hostname":"127.0.0.1","level":"INFO","line":3213,"msg":"HTTP server listening","port":"808>
Aug 08 03:00:12 ubuntu-oc-gp03 bash[280112]: {"function":"update_slots","level":"INFO","line":1659,"msg":"all slots are idle and system prompt is empty, clear th>
```

Sau này có thể xem log trong file:

```
$ tail -n 50 /opt/devops/LLM-lab/llamafile-lab/system-service-log/llamafile.log
```

#### 1.1.4.a. Troubleshoot

Check status và log lỗi:

```
$ sudo service llamafile status
● llamafile.service - Launch llamafile terminal program
     Loaded: loaded (/etc/systemd/system/llamafile.service; disabled; vendor preset: enabled)
     Active: failed (Result: exit-code) since Thu 2024-08-08 02:50:20 UTC; 1min 26s ago
    Process: 279922 ExecStart=/opt/devops/LLM-lab/llamafile-lab/llamafile $LLAMA_ARGS (code=exited, status=217/USER)
   Main PID: 279922 (code=exited, status=217/USER)

Aug 08 02:50:20 ubuntu-oc-gp03 systemd[1]: llamafile.service: Scheduled restart job, restart counter is at 5.
Aug 08 02:50:20 ubuntu-oc-gp03 systemd[1]: Stopped Launch llamafile terminal program.
Aug 08 02:50:20 ubuntu-oc-gp03 systemd[1]: llamafile.service: Start request repeated too quickly.
Aug 08 02:50:20 ubuntu-oc-gp03 systemd[1]: llamafile.service: Failed with result 'exit-code'.
Aug 08 02:50:20 ubuntu-oc-gp03 systemd[1]: Failed to start Launch llamafile terminal program.

$ tail -n 50 /var/log/syslog
Aug  8 02:50:20 ubuntu-oc-gp03 systemd[1]: Stopped Launch llamafile terminal program.
Aug  8 02:50:20 ubuntu-oc-gp03 systemd[1]: Started Launch llamafile terminal program.
Aug  8 02:50:20 ubuntu-oc-gp03 systemd[279922]: llamafile.service: Failed to determine user credentials: No such process
Aug  8 02:50:20 ubuntu-oc-gp03 systemd[279922]: llamafile.service: Failed at step USER spawning /opt/devops/LLM-lab/llamafile-lab/llamafile: No such process
Aug  8 02:50:20 ubuntu-oc-gp03 systemd[1]: llamafile.service: Main process exited, code=exited, status=217/USER
Aug  8 02:50:20 ubuntu-oc-gp03 systemd[1]: llamafile.service: Failed with result 'exit-code'.
Aug  8 02:50:20 ubuntu-oc-gp03 systemd[1]: llamafile.service: Scheduled restart job, restart counter is at 5.
Aug  8 02:50:20 ubuntu-oc-gp03 systemd[1]: Stopped Launch llamafile terminal program.
Aug  8 02:50:20 ubuntu-oc-gp03 systemd[1]: llamafile.service: Start request repeated too quickly.
Aug  8 02:50:20 ubuntu-oc-gp03 systemd[1]: llamafile.service: Failed with result 'exit-code'.
Aug  8 02:50:20 ubuntu-oc-gp03 systemd[1]: Failed to start Launch llamafile terminal program.

$ tail -n 50 /var/log/syslog
Aug  8 02:56:31 ubuntu-oc-gp03 systemd[280033]: llamafile.service: Failed to determine user credentials: No such process
Aug  8 02:56:31 ubuntu-oc-gp03 systemd[280033]: llamafile.service: Failed at step USER spawning /bin/bash: No such process
Aug  8 02:56:31 ubuntu-oc-gp03 systemd[1]: llamafile.service: Main process exited, code=exited, status=217/USER
Aug  8 02:56:31 ubuntu-oc-gp03 systemd[1]: llamafile.service: Failed with result 'exit-code'.
Aug  8 02:56:31 ubuntu-oc-gp03 systemd[1]: llamafile.service: Scheduled restart job, restart counter is at 5.
Aug  8 02:56:31 ubuntu-oc-gp03 systemd[1]: Stopped Launch llamafile terminal program.
Aug  8 02:56:31 ubuntu-oc-gp03 systemd[1]: llamafile.service: Start request repeated too quickly.
Aug  8 02:56:31 ubuntu-oc-gp03 systemd[1]: llamafile.service: Failed with result 'exit-code'.
Aug  8 02:56:31 ubuntu-oc-gp03 systemd[1]: Failed to start Launch llamafile terminal program.
```

Solution: Có thể do file đang trỏ sai các User và Group, hãy chắc chắn User và Group có tồn tại trong máy bạn

```s
User=ubuntu
Group=ubuntu
```

### 1.1.5. Expose to Internet via Swag (Nginx proxy)

[PENDING]

# 2. LMStudio

## 2.1. Setup on Windows

Setup trên Windows khá đơn giản chỉ cần download file exe về và run thôi.

Vào tab Home để search model và download về:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/lmstudio-windows-home-search.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/lmstudio-windows-home-search-download.jpg)

Chat với AI:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/lmstudio-windows-chat-screen-1.jpg)

Run Local server:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/lmstudio-windows-run-local-server.jpg)

Sau khi copy đoạn code curl chúng ta có thể test bằng cách gửi request đến server đang run ở port 8444 đó:

```
$ curl http://localhost:8444/v1/chat/completions   -H "Content-Type: application/json"   -d '{
    "model": "Qwen/CodeQwen1.5-7B-Chat-GGUF",
    "messages": [
      { "role": "system", "content": "Always answer in rhymes." },
      { "role": "user", "content": "Introduce yourself." }
    ],
    "temperature": 0.7,
    "max_tokens": -1,
    "stream": false
}'
{
  "id": "chatcmpl-gd9relb0fwsm77tm70jk3b",
  "object": "chat.completion",
  "created": 1723046344,
  "model": "Qwen/CodeQwen1.5-7B-Chat-GGUF/codeqwen-1_5-7b-chat-q2_k.gguf",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Hello! I am a language model created by Alibaba Cloud. My name is Qwen. How can I help you today?"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 27,
    "completion_tokens": 27,
    "total_tokens": 54
  }
}
```

## 2.2. Setup on Linux

LMstudio có 1 cái file binary lms-cli dùng để start stop server bằng command, nhưng nó đc release cùng với LMStudio chứ ko tách ra:

https://lmstudio.ai/blog/lms

Thử download về nhưng làm theo bài này: https://hackernoon.com/how-to-run-llms-using-lm-studio-in-linux-for-beginners

Thì khi extract file AppImage sẽ bị lỗi:
```
$ ./LM_Studio-0.2.31.AppImage --appimage-extract
-bash: ./LM_Studio-0.2.31.AppImage: cannot execute binary file: Exec format error
```

Muốn thử version 0.2.27 giống như ng ta đã extract thì ko download được, LMStudio chỉ show ra file latest thôi.

Đọc phần issue thì có vẻ như muốn run lms-cli cần phải run LMStudio GUI:

https://github.com/lmstudio-ai/lms/issues/59

https://github.com/lmstudio-ai/lms/issues/21


# 3. Ollama

## 3.1. Setup on Linux

Github chính thức: https://github.com/ollama/ollama

FAQ có nhiều câu hỏi rất hay: https://github.com/ollama/ollama/blob/main/docs/faq.md

Hiện tại thấy Ollama có support Docker install: https://github.com/ollama/ollama/blob/main/docs/docker.md

mình thấy khá chi tiết và đầy đủ, hướng dẫn cả run : Docker dùng CPU only / Docker dùng NVIDIA GPU / Docker dùng AMD GPU

Có 1 cái khá hay là document của Ollama có nhiều feature khá hay như:

- Customize a model, import from gguf file
- create a model from Modelfile (giống kiểu Dockerfile)
- Pull/Remove/Copy model
- Pass the prompt as an argument

Tuy nhiên mình thấy 1 hạn chế là Ollama hiện chưa thể đọc data từ directories: https://github.com/ollama/ollama/issues/1721. Trong issue này có nói gì đó về RAG technical - cần kết hợp code với Langchain library. Việc này làm mình thấy có 1 chút kém hơn so với GPT4All (chức năng LocalDocs with Obsidian)

Download binary file:

Mình hiện tại test dùng binary thường theo doc linux này: https://github.com/ollama/ollama/blob/main/docs/linux.md

Document mặc dù nói là chưa support kernel arm64 nhưng trong Release page đã release bản arm64 rồi: https://github.com/ollama/ollama/releases

Trong manual docs hướng dẫn đầy đủ rồi, mình sửa lại 1 chút để phù hợp với arm64:

```sh
sudo curl -L https://github.com/ollama/ollama/releases/download/v0.3.4/ollama-linux-arm64 -o /usr/bin/ollama
sudo chmod +x /usr/bin/ollama

$ ollama --version
Warning: could not connect to a running Ollama instance
Warning: client version is 0.3.4
```

Chú ý chỗ note này, có lẽ vì ollama sẽ download model về và load chúng vào RAM, nên bạn cần RAM lớn để lưu trữ:
> You should have at least 8 GB of RAM available to run the 7B models, 16 GB to run the 13B models, and 32 GB to run the 33B models.


Để run ollama thì mở 1 terminal riêng lên:

```sh
ollama serve
```

ollama support nhiều model khác nhau, cập nhật ở đây: https://ollama.com/library

Rồi bật terminal khác lên, gõ command sau để nó download model vào RAM, sau đó có thể chat với nó:

```sh
ollama run llama3.1

# log:
$ ollama run llama3.1
pulling manifest
pulling 4f6dc812262a... 100% ▕██████████████████████████████████████████████████████████▏ 4.7 GB
pulling 11ce4ee3e170... 100% ▕██████████████████████████████████████████████████████████▏ 1.7 KB
pulling 0ba8f0e314b4... 100% ▕██████████████████████████████████████████████████████████▏  12 KB
pulling 56bb8bd477a5... 100% ▕██████████████████████████████████████████████████████████▏   96 B
pulling 7a92f2c5af7a... 100% ▕██████████████████████████████████████████████████████████▏  485 B
verifying sha256 digest
writing manifest
removing any unused layers
success
>>> hi
How's it going? Is there something I can help you with, or would you just like to chat?

>>> tell me a joke about Donal Trump
Here's one:

Why did Donald Trump bring a ladder to the White House?

Because he wanted to take his presidency to a whole new level! (get it?)

Hope that made you groan or chuckle! Do you want another one?

>>>
Use Ctrl + d or /bye to exit.
```

Bạn có thể send request API đến ollama server, hướng dẫn đầy đủ ở đây (https://github.com/ollama/ollama/blob/main/docs/api.md):

```sh
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.1",
  "prompt": "what your name?",
  "stream": false
}'

# log:
$ curl http://localhost:11434/api/generate -d '{
>   "model": "llama3.1",
>   "prompt": "what your name?",
>   "stream": false
> }'
{"model":"llama3.1","created_at":"2024-08-08T07:42:04.32995524Z","response":"I don't have a personal name. I exist as a computer program designed to assist and communicate with users, so I'm often referred to as a \"chatbot\" or a \"conversational AI.\" You can think of me as a helpful tool rather than a person with a specific name.\n\nThat being said, some people refer to me as:\n\n* Assistant (a nod to my ability to provide assistance)\n* AI (short for Artificial Intelligence)\n* Bot (a colloquial term for chatbot or conversational AI)\n* Language Model (a more technical term for the software that powers our conversation)\n\nWhat would you like to call me?","done":true,"done_reason":"stop","context":[128009,128006,882,128007,271,12840,701,836,30,128009,128006,78191,128007,271,40,1541,956,617,264,4443,836,13,358,3073,439,264,6500,2068,6319,311,7945,323,19570,449,3932,11,779,358,2846,3629,14183,311,439,264,330,9884,6465,1,477,264,330,444,3078,1697,15592,1210,1472,649,1781,315,757,439,264,11190,5507,4856,1109,264,1732,449,264,3230,836,382,4897,1694,1071,11,1063,1274,8464,311,757,439,1473,9,22103,320,64,16387,311,856,5845,311,3493,13291,340,9,15592,320,8846,369,59294,22107,340,9,23869,320,64,82048,447,532,4751,369,6369,6465,477,7669,1697,15592,340,9,11688,5008,320,64,810,11156,4751,369,279,3241,430,13736,1057,10652,696,3923,1053,499,1093,311,1650,757,30],"total_duration":71881994786,"load_duration":35040208,"prompt_eval_count":15,"prompt_eval_duration":4052707000,"eval_count":132,"eval_duration":67744874000}
```

## 3.2. Setup on Docker

`docker-compose.yml` file:

```yml
version: '3.0'

services:
  ollama:
    image: ollama/ollama:0.3.4
    container_name: ollama
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Ho_Chi_Minh
    ports:
      - 11434:11434
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "10"
```

Run `docker-compose up -d` rồi check log OK là được.

Sau đó pull model về bằng command:

```
$ ollama list
NAME    ID      SIZE    MODIFIED

$ ollama pull llama3.1
pulling manifest
pulling 4f6dc812262a... 100% ▕██████████████████████████████████████████████████████████▏ 4.7 GB
pulling 11ce4ee3e170... 100% ▕██████████████████████████████████████████████████████████▏ 1.7 KB
pulling 0ba8f0e314b4... 100% ▕██████████████████████████████████████████████████████████▏  12 KB
pulling 56bb8bd477a5... 100% ▕██████████████████████████████████████████████████████████▏   96 B
pulling 7a92f2c5af7a... 100% ▕██████████████████████████████████████████████████████████▏  485 B
verifying sha256 digest
writing manifest
removing any unused layers
success
```

Thế là bạn đã có thể request đến API để hỏi:

```
$ curl http://localhost:11434/api/generate -d '{
  "model": "llama3.1",
  "prompt": "what your name?",
  "stream": false
}'
{"model":"llama3.1","created_at":"2024-08-08T08:23:07.373739394Z","response":"I don't have a personal name, but I'm an AI designed to assist and communicate with users. I'm often referred to as a \"chatbot\" or a \"conversational AI.\" If you'd like, we can use a nickname or a handle for our conversation, though!","done":true,"done_reason":"stop","context":[128009,128006,882,128007,271,12840,701,836,30,128009,128006,78191,128007,271,40,1541,956,617,264,4443,836,11,719,358,2846,459,15592,6319,311,7945,323,19570,449,3932,13,358,2846,3629,14183,311,439,264,330,9884,6465,1,477,264,330,444,3078,1697,15592,1210,1442,499,4265,1093,11,584,649,1005,264,30499,477,264,3790,369,1057,10652,11,3582,0],"total_duration":65472371410,"load_duration":27667310254,"prompt_eval_count":15,"prompt_eval_duration":6723138000,"eval_count":60,"eval_duration":31065004000}
```

Hoặc có thể exec vào container để tương tác trực tiếp ko qua API:

```sh
docker exec -it ollama ollama run llama3.1

# log
$ docker exec -it ollama ollama run llama3.1
pulling manifest
pulling 4f6dc812262a... 100% ▕██████████████████████████████████████████████████████████▏ 4.7 GB
pulling 11ce4ee3e170... 100% ▕██████████████████████████████████████████████████████████▏ 1.7 KB
pulling 0ba8f0e314b4... 100% ▕██████████████████████████████████████████████████████████▏  12 KB
pulling 56bb8bd477a5... 100% ▕██████████████████████████████████████████████████████████▏   96 B
pulling 7a92f2c5af7a... 100% ▕██████████████████████████████████████████████████████████▏  485 B
verifying sha256 digest
writing manifest
removing any unused layers
success
>>> hi
How's it going? Is there something I can help you with or would you like to chat?

>>> Send a message (/? for help)
```

Bây giờ nếu bạn muốn phát triền ứng dụng Python dựa trên Ollama, hãy xem qua repo này: https://github.com/ollama/ollama-python

Thậm chí bản thân python OpenAI Library cũng có thể dùng để call để Ollama endpoint giống như ví dụ này: https://github.com/ollama/ollama/blob/main/docs/openai.md#openai-python-library

## 3.3. Setup behind proxy server (Nginx Swag)

https://github.com/ollama/ollama/blob/main/docs/faq.md#how-do-i-use-ollama-behind-a-proxy

Mình đang dùng ollama docker. Proxy thì dùng docker-swag. Thế nên chỉ cần sửa swag thêm file sau:
`/opt/devops/swag/config/nginx/proxy-confs/ollama.subdomain.conf`:

```s
server {

    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name ollama.[YOUR_SUB_DOMAIN].duckdns.org;

    include /config/nginx/ssl.conf;

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app ollama;
        set $upstream_port 11434;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
}
```

restart `swag` rồi send request lại:  

```sh
curl https://ollama.[YOUR_SUB_DOMAIN].duckdns.org/api/generate -d '{
  "model": "llama3.1",
  "prompt": "what your name?",
  "stream": false
}'

# Chờ 1 lúc trả về KQ
```

Giờ cần set password (Basic Authen) cho url đó, đề phòng ng khác có thể dùng free. Command sau tạo file `.ollamahtpasswd` chứa user/password cho user `ollama`:  

```sh
sudo htpasswd -c /opt/devops/swag/config/nginx/.ollamahtpasswd ollama
# Enter password ko nên có ký tự đặc biệt
AaaBbbCcc
```

Sửa file `/opt/devops/swag/config/nginx/proxy-confs/ollama.subdomain.conf`:

```s
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name ollama.[YOUR_SUB_DOMAIN].duckdns.org;

    include /config/nginx/ssl.conf;

    client_max_body_size 0;

    # enable for ldap auth (requires ldap-location.conf in the location block)
    #include /config/nginx/ldap-server.conf;

    # enable for Authelia (requires authelia-location.conf in the location block)
    #include /config/nginx/authelia-server.conf;

    location / {
        # enable the next two lines for http auth
        auth_basic "Restricted";
        auth_basic_user_file /config/nginx/.ollamahtpasswd;

        # enable for ldap auth (requires ldap-server.conf in the server block)
        #include /config/nginx/ldap-location.conf;

        # enable for Authelia (requires authelia-server.conf in the server block)
        #include /config/nginx/authelia-location.conf;

        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app ollama;
        set $upstream_port 11434;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;

    }
}

```

giờ restart `swag` rồi test send request đến ollama:

```s
$ curl https://ollama:AaaBbbCcc@ollama.[YOUR_SUB_DOMAIN].duckdns.org/api/generate -d '{
del": >   "model": "llama3.1",
>   "prompt": "what your name?",
>   "stream": false
> }'
{"model":"llama3.1","created_at":"2024-08-09T02:47:18.164585651Z","response":"I don't have a personal name, but I'm an AI designed to assist and communicate with users. You can think of me as a helpful \"chatbot\" or a conversational interface. If you'd like, you can give me a nickname or a temporary name to make our conversation more personalized! What would you like to call me?","done":true,"done_reason":"stop","context":[128009,128006,882,128007,271,12840,701,836,30,128009,128006,78191,128007,271,40,1541,956,617,264,4443,836,11,719,358,2846,459,15592,6319,311,7945,323,19570,449,3932,13,1472,649,1781,315,757,439,264,11190,330,9884,6465,1,477,264,7669,1697,3834,13,1442,499,4265,1093,11,499,649,3041,757,264,30499,477,264,13643,836,311,1304,1057,10652,810,35649,0,3639,1053,499,1093,311,1650,757,30],"total_duration":46308125229,"load_duration":3824735311,"prompt_eval_count":15,"prompt_eval_duration":6724715000,"eval_count":70,"eval_duration":35752209000}
```

Nếu send request sai password sẽ báo lỗi ngay:

```s
$ curl https://ollama:123456789@ollama.[YOUR_SUB_DOMAIN].duckdns.org/api/generate -d '{
>   "model": "llama3.1",
>   "prompt": "what your name?",
>   "stream": false
> }'
<html>
<head><title>401 Authorization Required</title></head>
<body>
<center><h1>401 Authorization Required</h1></center>
<hr><center>nginx</center>
</body>
</html>
```

## 3.4. setup behind Ollama Proxy Server để có API Key (instead of Nginx Basic Authen)

1 vấn đề của các model run trong Ollama là chưa có cơ chế Authen "hợp lý" cho API request. Hiện tại mình đang dùng swag (nginx) để có basic Authen (đặt user:password ngay trong URL request của Ollama).

Nhưng chưa giống với OpenAI lắm, OpenAI hay các provider khác đều dùng API Key để authen các API request.

Để làm giống OpenAI thì có 1 giải pháp là dùng `Ollama Proxy Server` của https://github.com/ParisNeo/ollama_proxy_server

Nó sẽ làm nhiệm vụ authen bằng các API Key do ta define. Khi user request đến Ollama endpoint (họ sẽ phải gửi cả API Key theo kèm trong Header của reqeust)

Deploy `Ollama Proxy Server`:

```sh
git clone https://github.com/ParisNeo/ollama_proxy_server
cd ollama_proxy_server
```

Sửa file `ollama_proxy_server/config.ini`, vì `ollama` là container name của Ollama, run cùng network với `ollama_proxy_server`, Nếu bạn connect đến ollama ở ip khác thì nên thay đổi:
```
[DefaultServer]
url = http://ollama:11434
queue_size = 5
```

Sửa file `ollama_proxy_server/authorized_users.txt` để thêm API Key vào API dạng `user:password`

Sửa `Dockerfile` (comment 2 dòng COPY) để có thể mount 2 file `authorized_users.txt` và `config.ini` vào container:

```yml
FROM python:3.11

# Update packagtes, install necessary tools into the base image, clean up and clone git repository
RUN apt update \
    && apt install -y --no-install-recommends --no-install-suggests git apache2 \
    && apt autoremove -y --purge \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && git clone https://github.com/ParisNeo/ollama_proxy_server.git

# Change working directory to cloned git repository
WORKDIR ollama_proxy_server

# Install all needed requirements
RUN pip3 install -e .

# Copy config.ini and authorized_users.txt into project working directory
# COPY config.ini .
# COPY authorized_users.txt .

# Start the proxy server as entrypoint
ENTRYPOINT ["ollama_proxy_server"]

# Set command line parameters
CMD ["--config", "./config.ini", "--users_list", "./authorized_users.txt", "--port", "8080"]
```

build Docker images:
```sh
docker build -t ollama_proxy_server:20240817 .
```

Sửa file `docker-compose.yml`:
```yml
services:

  ollama_proxy_server:
    image: ollama_proxy_server:20240817
    container_name: ollama_proxy_server
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Ho_Chi_Minh
    ports:
      - 8080:8080
    volumes:
      - /opt/devops/ollama_proxy_server/authorized_users.txt:/ollama_proxy_server/authorized_users.txt
      - /opt/devops/ollama_proxy_server/config.ini:/ollama_proxy_server/config.ini
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "10"
```

```sh
docker-compose up -d
```

test curl command:
```sh
curl --header "Authorization: Bearer user1:0XAXAXAQX5A1F" --request POST 'http://localhost:8080/api/generate' \
--data-raw '{
"model": "llama3.1:latest",
"prompt": "Once apon a time",
"stream": false,
"temperature": 0.3,
"max_tokens": 1024
}'
```

Vậy là OK!

**Mỗi khi muốn update API Key?**

Bạn cần: 
- sửa lại file `ollama_proxy_server/authorized_users.txt`
- `docker stop container ollama_proxy_server`
- `docker rm container ollama_proxy_server`
- `docker-compose up -d` again.
- không cần build lại docker images (`docker build`).

## 3.5. Private context

Ollama cung cấp nhiều ví dụ rất trực quan và hay, ví dụ:

- Bạn đưa 1 file PDF cho Ollama đọc và nó trả lời các câu hỏi dựa trên file pdf đó: https://github.com/ollama/ollama/tree/main/examples/langchain-python-rag-document

- Tạo 1 directory `source_documents` cho document vào rồi bảo Ollama đọc và trả lời: https://github.com/ollama/ollama/tree/main/examples/langchain-python-rag-privategpt

- Bài này nói về 1 thứ khá hay cách bạn truyền cả 1 website tiểu thuyết vào và hỏi Ollama dựa trên các thông tin được truyền vào đó.
Đòi hỏi phải dùng code và split đống tiểu thuyết thành nhiều đoạn rồi mới đưa cho model đọc: https://github.com/ollama/ollama/blob/main/docs/tutorials/langchainpy.md

- Ví dụ về sumarize 1 website: https://github.com/ollama/ollama/tree/main/examples/langchain-python-rag-websummary

## 3.6. Kết hợp PrivateGPT + Ollama, setup on Linux

PrivateGPT ko phải là 1 tool giống Ollama để build LLM, mà nó kết hợp với Ollama để cung cấp các API để build các ứng dụng AI với private data và context-aware
(đại khái là các ứng dụng dùng data của riêng cá nhân và AI phải trả lời dựa trên các thông tin nó được đọc).

https://docs.privategpt.dev/installation/getting-started/installation

Ở đây mình sẽ deploy PrivateGPT, giao diện UI trên port 8001, nó kết nối đến Ollama đang chạy trên port 11434 để làm backend:

```s
# tạo folder `privategpt-lab` để run PrivateGPT rồi cd vào
~$ cd /opt/devops/LLM-lab/privategpt-lab/

# git clone source privateGPT về:
git clone https://github.com/zylon-ai/private-gpt

# Install python3.11

# install poetry bằng python3.11
$ curl -sSL https://install.python-poetry.org | python3.11 -
$ poetry --version
Poetry (version 1.8.3)

# tạo môi trường venv cho python3.11 vì default của máy mình là python3.8 sẽ ko chạy được
$ python3.11 -m venv .venv

# list .venv đã xuất hiện
/opt/devops/LLM-lab/privategpt-lab$ ll
total 16
drwxrwxr-x  4 ubuntu ubuntu 4096 Aug  9 04:06 ./
drwxrwxr-x  6 ubuntu ubuntu 4096 Aug  9 03:49 ../
drwxrwxr-x  7 ubuntu ubuntu 4096 Aug  9 04:07 .venv/
drwxrwxr-x 12 ubuntu ubuntu 4096 Aug  9 03:50 private-gpt/

# activate venv python3.11 lên
/opt/devops/LLM-lab/privategpt-lab$ source .venv/bin/activate

# check python3 version đã chuyển thành 3.11
(.venv) /opt/devops/LLM-lab/privategpt-lab$ python3 --version
Python 3.11.9

# dùng poetry để install privategpt, phải chạy đúng trong folder private-gpt, nếu ko sẽ bị lỗi này
(.venv) /opt/devops/LLM-lab/privategpt-lab$ poetry install --extras "ui llms-ollama embeddings-ollama vector-stores-qdrant"
Poetry could not find a pyproject.toml file in /opt/devops/LLM-lab/privategpt-lab or its parents

# dùng petry để install privategpt, đúng chỗ:
(.venv) /opt/devops/LLM-lab/privategpt-lab$ cd private-gpt/
(.venv) /opt/devops/LLM-lab/privategpt-lab/private-gpt$ poetry install --extras "ui llms-ollama embeddings-ollama vector-stores-qdrant"
Installing dependencies from lock file
No dependencies to install or update
Installing the current project: private-gpt (0.6.2)

# Run web UI ở port 8001:
(.venv) /opt/devops/LLM-lab/privategpt-lab/private-gpt$ PGPT_PROFILES=ollama make run
poetry run python -m private_gpt
04:13:25.998 [INFO    ] private_gpt.settings.settings_loader - Starting application with profiles=['default', 'ollama']
None of PyTorch, TensorFlow >= 2.0, or Flax have been found. Models won't be available and only tokenizers, configuration and file/data utilities can be used.
04:13:28.823 [INFO    ] private_gpt.components.llm.llm_component - Initializing the LLM in mode=ollama
04:13:28.847 [INFO    ]                     httpx - HTTP Request: GET http://localhost:11434/api/tags "HTTP/1.1 200 OK"
04:13:28.849 [INFO    ]                     httpx - HTTP Request: GET http://localhost:11434/api/tags "HTTP/1.1 200 OK"
04:13:30.023 [INFO    ] private_gpt.components.embedding.embedding_component - Initializing the embedding model in mode=ollama
04:13:30.034 [INFO    ]                     httpx - HTTP Request: GET http://localhost:11434/api/tags "HTTP/1.1 200 OK"
04:13:30.035 [INFO    ]                     httpx - HTTP Request: GET http://localhost:11434/api/tags "HTTP/1.1 200 OK"
04:13:30.036 [INFO    ] llama_index.core.indices.loading - Loading all indices.
04:13:31.096 [INFO    ]         private_gpt.ui.ui - Mounting the gradio UI, at path=/
04:13:31.151 [INFO    ]             uvicorn.error - Started server process [308271]
04:13:31.151 [INFO    ]             uvicorn.error - Waiting for application startup.
04:13:31.151 [INFO    ]             uvicorn.error - Application startup complete.
04:13:31.151 [INFO    ]             uvicorn.error - Uvicorn running on http://0.0.0.0:8001 (Press CTRL+C to quit)
```

giao diện PrivateGPT trên port 8001: 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/privategpt-ollama-llmama3.1-port8001.jpg)

Bạn có thể upload file lên và nó trả lời dựa trên data trong file đó.

**Setup on Docker Compose**:

Cách deploy để test thôi, giờ mình sẽ deploy trên docker-compose:

Trong folder `private-gpt` có sẵn 1 file `docker-compose.yaml`, nhưng mình sẽ ko dùng.

Duplicate file `docker-compose.yaml` để tạo 1 file mới tên `docker-compose-hoangmnsd.yaml`, sửa nội dung như sau:

```yml
version: '3'

networks:
  external_nw:
    external:
      name: devops_default

services:
  #-----------------------------------
  #---- Private-GPT services ---------
  #-----------------------------------

  # Private-GPT service for the Ollama CPU and GPU modes
  # This service builds from an external Dockerfile and runs the Ollama mode.
  privategpt_ollama:
    image: ${PGPT_IMAGE:-zylonai/private-gpt}${PGPT_TAG:-0.6.2}-ollama  # x-release-please-version
    container_name: privategpt_ollama
    networks:
      - external_nw
    build:
      context: .
      dockerfile: Dockerfile.ollama
    volumes:
      - ./local_data/privategpt_ollama/:/home/worker/app/local_data
    ports:
      - "8101:8001"
    environment:
      PORT: 8001
      PGPT_PROFILES: docker
      PGPT_MODE: ollama
      PGPT_EMBED_MODE: ollama
      PGPT_OLLAMA_API_BASE: http://ollama:11434
      HF_TOKEN: ${HF_TOKEN:-}
    profiles:
      - ""
      - ollama-cpu
      - ollama-cuda
      - ollama-api
```

Cần phải thêm phần networks là do:
- mình có 1 file docker-compose ở chỗ khác, đang chạy ollama.
- privategpt muốn connect đến ollama thì cần phải ở cùng 1 network với ollama.
- mình cũng đổi port sang 8101 để expose ra ngoài

```sh
cd /opt/devops/LLM-lab/privategpt-lab/private-gpt/
chmod 777 -R local_data/
docker-compose -f docker-compose-hoangmnsd.yaml up privategpt_ollama -d
```

Check log ko có lỗi gì là OK:

```
$ docker logs -f privategpt_ollama
08:38:38.383 [INFO    ] private_gpt.settings.settings_loader - Starting application with profiles=['default', 'docker']
None of PyTorch, TensorFlow >= 2.0, or Flax have been found. Models won't be available and only tokenizers, configuration and file/data utilities can be used.
08:38:45.898 [INFO    ] private_gpt.components.llm.llm_component - Initializing the LLM in mode=ollama
08:38:45.987 [INFO    ]                     httpx - HTTP Request: GET http://ollama:11434/api/tags "HTTP/1.1 200 OK"
08:38:45.988 [INFO    ]                     httpx - HTTP Request: GET http://ollama:11434/api/tags "HTTP/1.1 200 OK"
08:38:47.577 [INFO    ] private_gpt.components.embedding.embedding_component - Initializing the embedding model in mode=ollama
08:38:47.616 [INFO    ]                     httpx - HTTP Request: GET http://ollama:11434/api/tags "HTTP/1.1 200 OK"
08:38:47.617 [INFO    ]                     httpx - HTTP Request: GET http://ollama:11434/api/tags "HTTP/1.1 200 OK"
08:38:47.619 [INFO    ] llama_index.core.indices.loading - Loading all indices.
08:38:50.187 [INFO    ]   matplotlib.font_manager - generated new fontManager
08:38:51.030 [INFO    ]         private_gpt.ui.ui - Mounting the gradio UI, at path=/
08:38:51.115 [INFO    ]             uvicorn.error - Started server process [6]
08:38:51.115 [INFO    ]             uvicorn.error - Waiting for application startup.
08:38:51.115 [INFO    ]             uvicorn.error - Application startup complete.
08:38:51.116 [INFO    ]             uvicorn.error - Uvicorn running on http://0.0.0.0:8001 (Press CTRL+C to quit)
```

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/privategpt-ollama-llmama3.1.jpg)

## 3.7. Kết hợp PrivateGPT + OpenAI, setup on Docker

Add thêm file `Dockerfile.openai` vì ta sẽ build riêng 1 docker image cho openai, mình sửa chỗ `POETRY_EXTRAS` dựa trên guide trong https://docs.privategpt.dev/installation/getting-started/installation#non-private-openai-powered-test-setup:

```s
FROM python:3.11.6-slim-bookworm as base

# Install poetry
RUN pip install pipx
RUN python3 -m pipx ensurepath
RUN pipx install poetry==1.8.3
ENV PATH="/root/.local/bin:$PATH"
ENV PATH=".venv/bin/:$PATH"

# https://python-poetry.org/docs/configuration/#virtualenvsin-project
ENV POETRY_VIRTUALENVS_IN_PROJECT=true

FROM base as dependencies
WORKDIR /home/worker/app
COPY pyproject.toml poetry.lock ./

ARG POETRY_EXTRAS="ui llms-openai embeddings-openai vector-stores-qdrant"
RUN poetry install --no-root --extras "${POETRY_EXTRAS}"

FROM base as app
ENV PYTHONUNBUFFERED=1
ENV PORT=8080
ENV APP_ENV=prod
ENV PYTHONPATH="$PYTHONPATH:/home/worker/app/private_gpt/"
EXPOSE 8080

# Prepare a non-root user
# More info about how to configure UIDs and GIDs in Docker:
# https://github.com/systemd/systemd/blob/main/docs/UIDS-GIDS.md

# Define the User ID (UID) for the non-root user
# UID 100 is chosen to avoid conflicts with existing system users
ARG UID=100

# Define the Group ID (GID) for the non-root user
# GID 65534 is often used for the 'nogroup' or 'nobody' group
ARG GID=65534

RUN adduser --system --gid ${GID} --uid ${UID} --home /home/worker worker
WORKDIR /home/worker/app

RUN chown worker /home/worker/app
RUN mkdir local_data && chown worker local_data
RUN mkdir models && chown worker models
COPY --chown=worker --from=dependencies /home/worker/app/.venv/ .venv
COPY --chown=worker private_gpt/ private_gpt
COPY --chown=worker *.yaml .
COPY --chown=worker scripts/ scripts

USER worker
ENTRYPOINT python -m private_gpt
```

Sửa file `docker-compose-hoangmnsd.yaml` thêm đoạn `privategpt_openai` sau vào. Chú ý chỗ `OPENAI_API_KEY` là API key secrets:

```yaml
version: '3'

networks:
  external_nw:
    external:
      name: devops_default

services:

  ...

  # Private-GPT service for the OpenAI modes
  # This service builds from an external Dockerfile and runs the OpenAI mode.
  privategpt_openai:
    image: ${PGPT_IMAGE:-zylonai/private-gpt}${PGPT_TAG:-0.6.2}-openai  # x-release-please-version
    container_name: privategpt_openai
    networks:
      - external_nw
    build:
      context: .
      dockerfile: Dockerfile.openai
    volumes:
      - ./local_data/privategpt_openai/:/home/worker/app/local_data
    ports:
      - "8102:8001"
    environment:
      PORT: 8001
      PGPT_PROFILES: openai
      PGPT_MODE: openai
      PGPT_EMBED_MODE: openai
      OPENAI_API_KEY: sk-proj-YOUR_API_KEY
      OPENAI_MODEL: gpt-4o # gpt-4o-mini # gpt-3.5-turbo # Hoangmnsd: if change this env, you need to "remove" container before "docker-compose up".
    profiles:
      - ""
      - openai
```

Sửa file `settings-openai.yaml` để nó lấy được biến môi trường env `OPENAI_MODEL` từ file `docker-compose-hoangmnsd.yaml`:

```yml
server:
  env_name: ${APP_ENV:openai}

llm:
  mode: openai

embedding:
  mode: openai

openai:
  api_key: ${OPENAI_API_KEY:}
  model: ${OPENAI_MODEL:gpt-3.5-turbo}
```

Run:

```sh
docker-compose -f docker-compose-hoangmnsd.yaml up privategpt_openai -d
```

Check log ko có lỗi gì là OK

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/privategpt-openai-4.jpg)

Chú ý: 
Nếu file `docker-compose-hoangmnsd.yaml` bạn thay đổi model từ `gpt-4o` sang model `gpt-4o-mini` chẳng hạn, bạn cần `docker remove container  privategpt_openai` trước, sau đó mới start container mới thì nó sẽ chuyển sang model mới cho bạn.

Như vậy bằng sự kết hợp với PrivateGPT bạn có thể chỉ cần API key bạn sẽ có 1 giao diện riêng của mình (privateGPT) mà vẫn access được tính năng chat của nhiều platform khác nhau, ko cần trả phí subscription hàng tháng mà bạn dùng theo credit của API Key.

Sau khi setup swag xong thì setup basic Authen cho swag Nginx:  
```sh
htpasswd -c /opt/devops/swag/config/nginx/.pollamahtpasswd user2
xxx

htpasswd /opt/devops/swag/config/nginx/.pollamahtpasswd user1
yyy
```

```sh
htpasswd -c /opt/devops/swag/config/nginx/.popenaihtpasswd user2
zzz

htpasswd /opt/devops/swag/config/nginx/.popenaihtpasswd user1
kkk
```

## 3.8. Kết hợp PrivateGPT + Perplexity (Llama3.1 trả phí credit), setup on Docker

Mình đã thử nạp 10$ để mua credit Perplexity API để dùng thử model Llama3.1

Mà Perplexity thì cũng expose ra API theo kiểu OpenAI compartible. 
Đọc docs này của PrivateGPT thì thấy có thể setup dùng với kiểu API như vậy:  
https://docs.privategpt.dev/manual/advanced-setup/llm-backends#using-openai-compatible-api

Muốn vậy thì mình tạo profile riêng cho Perplexity, tạo file `settings-perplexity.yaml`:

```yml
server:
  env_name: ${APP_ENV:perplexity}

llm:
  mode: openailike
  max_new_tokens: 512
  temperature: 0.1

openai:
  api_base: ${OPENAI_API_BASE}
  api_key: ${OPENAI_API_KEY:}
  model: ${OPENAI_MODEL:gpt-3.5-turbo}
```

Tạo file `Dockerfile.perplexity`, mình chỉ sửa đoạn `ARG POETRY_EXTRAS="ui llms-openai-like embeddings-huggingface vector-stores-qdrant"`:

```yaml
FROM python:3.11.6-slim-bookworm as base
...
ARG POETRY_EXTRAS="ui llms-openai-like embeddings-huggingface vector-stores-qdrant"
RUN poetry install --no-root --extras "${POETRY_EXTRAS}"
...
```

Sửa file `docker-compose-hoangmnsd.yaml` thêm đoạn sau, expose service port 8103 để test, nhớ thay OPENAI_API_KEY bằng key của Perplexity:

```yml
...
  # Private-GPT service for the Perplexity
  # This service builds from an external Dockerfile and runs request to Perplexity.
  privategpt_perplexity:
    image: ${PGPT_IMAGE:-zylonai/private-gpt}${PGPT_TAG:-0.6.2}-perplexity  # x-release-please-version
    container_name: privategpt_perplexity
    networks:
      - external_nw
    build:
      context: .
      dockerfile: Dockerfile.perplexity
    volumes:
      - ./local_data/privategpt_perplexity/:/home/worker/app/local_data
    ports:
      - "8103:8001"
    environment:
      PORT: 8001
      PGPT_PROFILES: perplexity
      PGPT_MODE: openailike
      # PGPT_EMBED_MODE: openai
      OPENAI_API_BASE: https://api.perplexity.ai
      OPENAI_API_KEY: pplx-YOUR_API_KEY
      OPENAI_MODEL: llama-3.1-8b-instruct # Hoangmnsd: if change this env, you need to "remove" container before "docker-compose up".
    profiles:
      - ""
      - perplexity
```

Sau đó deploy: `docker-compose -f docker-compose-hoangmnsd.yaml up privategpt_perplexity -d`

Mình sẽ thấy Model run được như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/privategpt-perplexity-llmama3.1-port8103.jpg)

Sau khi setup swag xong thì setup basic Authen cho swag Nginx:  

```sh
htpasswd /opt/devops/swag/config/nginx/.pplexhtpasswd user1
zzz

htpasswd -c /opt/devops/swag/config/nginx/.pplexhtpasswd user2
yyy
```

# 4. GPT4All

## 4.1. Setup trên Windows

Cài đặt trên Windows khá đơn giản, tìm và download model ở đây:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/gpt4all-screen-download-model.jpg)

Chức năng hay nhất của tool này là `LocalDocs` Khi vào khung chat bạn có thể lựa chọn folder chứa các documents và đặt ra câu hỏi dựa trên các docs đó:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/gpt4all-screen-chat.jpg)

Bản thân trên docs của GPT4All cũng giới thiệu Obsidians/Googledrive/Onedrive (https://docs.gpt4all.io/gpt4all_desktop/cookbook/use-local-ai-models-to-privately-chat-with-Obsidian.html)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/gpt4all-screen-docs.jpg)

1 ý tưởng rất hay là cho AI đọc các ghi chú trong folder Obsidians và nó gợi ý đặt tag cho các note mà bạn chưa gắn tag...

## 4.2. Setup trên Linux

Chỉ có app GUI. Ko thấy có dạng server để expose ra Internet.

# 5. Open WebUi

Mình dùng luôn với OPENAI API key nên khá đơn giản,

Dùng file `docker-compose.yml` sau:

```yml
version: '3.0'

services:
  
  open_webui:
    image: ghcr.io/open-webui/open-webui:0.5.4
    restart: unless-stopped
    container_name: open_webui
    ports:
      - '47380:8080'
    volumes:
      - /opt/devops/open-webui-lab/data:/app/backend/data
    environment:
      - OPENAI_API_KEY=sk-XXX

```

Sau khi đưa qua swag(nginx) thì sẽ có HTTPS và tự setup admin account.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-dashboard.jpg)

Khi chat với AI thì có thể dùng `#` để truy xuất trang web, hoặc documents, knowledge base, ví dụ trang web:

```
#https://github.com/Cinnamon/kotaemon

tóm tắt nội dung này
```

1 cái rất hay là Knowledge base:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-knowledge-base.jpg)

Tuy nhiên điều quan trọng là, trước khi tạo Knowledge base, Bạn cần setup chỗ này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-knowledge-base-embed-setup.jpg)

Khi test, mình tạo Knowledge base mình có 2 file pdf. 1 file 44 trang, 1 file 11 trang.

Khi mình dùng embeding model là default của open web ui: `sentence-transformers/all-MiniLM-L6-v2` thì nó sẽ ko trả lời đc câu hỏi của mình. Nó bảo ko tìm thấy thông tin trong knowledge base (mặc dù có)

Nhưng nếu đổi embedding model sang: OpenAI's `text-embedding-3-small`. Thì sau khi tạo Knowledge base, đặt câu hỏi sẽ trả lời đúng.

Tuy nhiên giá của openAI cho model text-embedding-3-small là 0.02$ / 1M token.

Khi chuyển sang dùng open source model Ollama model `nomic-embed-text`, thì việc upload file 44 trang lên sẽ rất lâu, do vm của mình ko có gpu chỉ có 24gb ram và 4cpu.

Nói chung cần thay đổi embbeding model để cho kết quả tốt.

# 6. vllm [Pending]

Cái này được support khá nhiều bởi các ông lớn như Huggingface có code để run luôn...

Cái này được quảng cáo là chạy rất nhanh, nhưng thực ra nó run trên GPU (mặc dù có hướng dẫn install trên CPU nhưng yêu cầu rất khắt khe về OS), install trên mấy OS khác nhiều khả năng bạn sẽ gặp lỗi rất khó fix.

Mình thử install trên Linux Ubuntu 20 - lỗi. Thử trên WSL Ubuntu 20/22 - lỗi. Windows - lỗi.

# 7. kotaemon [Pending]

https://github.com/cinnamon/kotaemon

# 8. Bonus: Gradio - UI for API [Pending]

https://www.gradio.app/guides/quickstart

1 python package dùng để tạo giao diện cho API

# REFERENCES

Ollama linux documents:

https://github.com/ollama/ollama/blob/main/docs/linux.md

LMStudio:

https://www.youtube.com/watch?v=4fdZwKg9IbU&ab_channel=MatthewBerman

https://lmstudio.ai/docs/local-server

Bảng xếp hạng các open AI model LM để support Coding:

https://evalplus.github.io/leaderboard.html

https://vt.tiktok.com/ZSYXQ33AY/

Huggingface link file gguf của Codeqwen Alibaba Cloud:

https://huggingface.co/Qwen/CodeQwen1.5-7B-Chat-GGUF/tree/main

Mentat with local LLM model:

https://docs.mentat.ai/en/latest/user/alternative_models.html

