---
title: "Setting up AI coding assistant"
date: 2024-07-26T21:56:40+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Extension,AI,Agent,LLM]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Bài này giới thiệu về 1 tool AI coding assistant rất thú vị..."
---

Tương lai công việc của Developer sẽ "nhàn" đi rất nhiều.. và cũng **cạnh tranh** hơn rất nhiều với sự xuất hiện của các công cụ AI Coding assistant/agent như thế này...

Bạn hoàn toàn có thể "ra chuồng gà" nếu ko xuôi mình theo dòng chảy của thời đại.

# 1. Mentat (dừng update từ tháng 4/2024)

## 1.1. Overview

Mình được biết đến [mentat](https://github.com/AbanteAI/mentat) qua 1 repo nào đó về ChatGPT.

Mentat open source và bạn sẽ sử dụng OpenAI API key để cung cấp cho nó.

Bạn cho nó đọc 1 số file code của bạn là input đầu vào, sau đó bạn chat với nó trên terminal, nó sẽ giúp bạn code luôn 😀

## 1.2. Setup Mentat trên Windows + GitBash + VS Code

Download python3.11 (trên 3.10 là OK) về

https://www.python.org/downloads/release/python-3119/

Cài đặt (Khi cài thì nhớ tick chọn vào chỗ add/export to PATH env variable)

Verify xem `python.exe` có tồn tại trong folder này ko:

`C:\Users\<USER_NAME_CỦA_BẠN>\AppData\Local\Programs\Python\Python311\python.exe`

Mở Gitbash, chuyển version mặc định sang python3.11 mới download về:

```sh
cd ~

nano .bashrc

# Sửa file thêm dòng sau:
alias python='winpty "C:\Users\<USER_NAME_CỦA_BẠN>\AppData\Local\Programs\Python\Python311\python.exe"'
# Đóng file save lại

source .bashrc

# Check lại xem đúng chuyển sang version mới chưa
python --version
```

Trong Gitbash, install pip, ko có lỗi gì là ok:

```sh
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py

python get-pip.py
```

Trong Gitbash activate venv, install mentat:

```sh
# (optional) Bạn có thể create venv hoặc ko. Mình suggest là ko cần
# Vì khi tạo .venv, bạn cần tạo thêm gitignore để mentat ko dùng folder .venv làm input đầu vào. Như vậy sẽ tốn nhiều tiền của OpenAI key.
python -m venv .venv
source .venv/Scripts/activate

python -m pip install git+https://github.com/AbanteAI/mentat.git
```

Hiện khi sử dụng mentat mình đang bị lỗi:

```
USER_NAME_CỦA_BẠN@AAA-BBB MINGW64 C:/Users/USER_NAME_CỦA_BẠN/AppData/Local/Programs/Microsoft VS Code (master)
$ mentat
bash: mentat: command not found
```

Thì hãy thêm command sau để mentat có trong env PATH:

```s
export PATH=$PATH:/c/Users/<USER_NAME_CỦA_BẠN>/AppData/Local/Programs/Python/Python311/Scripts
```

Giờ add OpenAPI key vào để mentat sử dụng:

```sh
export OPENAI_API_KEY=<your key here>
```

Giờ gõ mentat tên các file input đầu vào cho nó đọc. Sau đó chat với nó thôi.

Bạn có thể đưa cả folder cho nó đọc cũng được. Nhưng điều đó đồng nghĩa với việc bạn ko quản lý số lượng input đầu vào cho mentat. Khiến key của bạn có thể hết tiền nhanh hơn.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/ai-coding-assist-mentat-01.jpg)

Hiện tại có 1 vấn đề nhỏ, là mentat chỉ có thể sửa code 1 file tại 1 thời điểm. Nếu bạn yêu cầu nó sửa code 2 file, nó in ra câu trả lời nhưng khi bạn ấn `Apply change` nó sẽ chỉ sửa 1 file.

Và 1 vấn đề to, là Mentat ko support/kém support các OpenAI model khác (gpt-4o-mini/gpt-4o) và Opensource Model như Ollama.

# 2. Github Copilot

Tương tự như Mentat nhưng bạn trả tiền trực tiếp cho Github. 10$ per month. Dùng thử 30 days.

Bạn viết comment trong code và ấn Ctr+I để hỏi nó trực tiếp trong file code.

{{< youtube Fi3AJZZregI >}}

https://www.youtube.com/watch?v=Fi3AJZZregI&list=PLj6YeMhvp2S5_hvBl2SE-7YCHYlLQ0bPt&ab_channel=VisualStudioCode

https://www.youtube.com/watch?v=aGbfU4GiI9s&ab_channel=Ph%E1%BA%A1mHuyHo%C3%A0ng


# 3. Amazon Q Developer

https://aws.amazon.com/q/developer/pricing/

Có tier Free giới hạn: limit 50 interactions per month

Video giới thiệu: https://www.youtube.com/watch?v=i0zQpJPfSdU&ab_channel=AWSDevelopers

{{< youtube i0zQpJPfSdU >}}


# 4. ContinueDev (Recommend)

## 4.1. Overview

So với Mentat thì mình thấy cái này tốt hơn nhiều, Link github: https://github.com/continuedev/continue

Quan trọng nhất là nó xử lý được vấn đề của Mentat là ko dùng được các OpenAI model khác như (gpt-4o, gpt-4o-mini), sau đó là có thể dùng các Ollama model nữa.

## 4.2. Setup ContinueDev với nhiều endpoint khác nhau

Sau khi đã install VS Code extension.

Sửa file `C:\Users\YOUR_USER_NAME\.continue\config.json` để kết nối với OpenAI gpt-4o-mini:
```json
{
  "models": [
    {
      "title": "GPT-4o-mini",
      "provider": "openai",
      "model": "gpt-4o-mini",
      "apiKey": "sk-proj-XXX"
    }
  ]
```

Sửa file `C:\Users\YOUR_USER_NAME\.continue\config.json` để kết nối với Ollama của cá nhân (kết hợp Ollama với https://github.com/ParisNeo/ollama_proxy_server để có apiKey):
```json
{
  "models": [
    {
      "title": "llama3.1",
      "provider": "ollama",
      "model": "llama3.1",
      "apiKey": "user1:ABC",
      "apiBase": "https://ollamaproxy.[YOUR_DOMAIN].duckdns.org/"
    }
  ],
```

Riêng Perplexity thì họ ko expose hết api nên sẽ bị lỗi. Nếu config trỏ đến Perplexity sẽ bị lỗi do perplexity chỉ mở api cho `/chat/completions` thôi:
```json
{
  "models": [
    {
      "title": "llama-3.1-8b-instruct",
      "provider": "openai",
      "model": "llama-3.1-8b-instruct",
      "apiKey": "pplx-xxx",
      "apiBase": "https://api.perplexity.ai"
    }
  ],
```

Lỗi hiện tại khi kết nối Perplexity:
```
Error streaming diff: Error: HTTP 400 Bad Request from https://api.perplexity.ai/completions {"error":{"message":"The model should only be queried with the /chat/completions endpoint.","type":"invalid_model","code":400}}
```

Có thể dùng ctrl+L để chat với Perplexity, nhưng ko dùng được Ctrl+I vì nó đang trỏ đến path khác.

Nếu sửa `apiBase=https://api.perplexity.ai/chat/` để dùng thử Ctrl+I thì vẫn lỗi:
```
Error streaming diff: Error: HTTP 400 Bad Request from https://api.perplexity.ai/chat/completions {"error":{"message":"[\"At body -> messages: Field required\"]","type":"bad_request","code":400}}
```

Túm lại, hiện tại chỉ có thể dùng ContinueDev Với OpenAI (các model) và Ollama (phải đi kèm ollama_proxy_server để có apikey)

## 4.3. Thử tabAutocompleteModel dùng model Ollama starcoder:1b

Chỗ file `C:\Users\YOUR_USER_NAME\.continue\config.json`, `tabAutocompleteModel` nên dùng theo recommend sau:
https://docs.continue.dev/features/tab-autocomplete

Hiện tại thì mình dùng ContnueDev với chức năng Ctrl+I và Ctrl+L thôi, đang disable chức năng `tabAutocomplete` này vì nghĩ nó sẽ spam OpenAI API làm tốn tiền.

Sau khi sử dụng Tabby, mình thấy chức năng rất hay của Tabby là Autocomplete rất nhanh. Mình nghĩ có thể do nó dùng model `starcoder:1b` nhẹ ~800Mb nên nhanh vậy/

Nên mình có ý tưởng là: Deploy model `starcoder:1b` trên Ollama rồi cho ContinueDev sử dụng thử. Sửa file `C:\Users\YOUR_USER_NAME\.continue\config.json`:

```json
"tabAutocompleteModel": [
    {
      "title": "starcoder:1b",
      "provider": "ollama",
      "model": "starcoder:1b",
      "apiBase": "https://YOUR_OLLAMA_SERVER.org/",
      "apiKey": "user:pass"
    }
  ],
```

Nhưng kết quả là Ollama trên server của mình phải xử lý request liên tục bị 100% CPU 🤣 tab auto rất chậm...

Như vậy là ContinueDev đành disable chức năng tabAutocomplete thôi. 😪

Đọc thêm về config: https://docs.continue.dev/setup/configuration

# 5. GPT Pilot

https://github.com/Pythagora-io/gpt-pilot

Demo có vẻ rất hay nhưng ko thấy dùng được OpenAI API key, cứ bắt Subscribe Pythgora Pro mới cho chat.

Có docs về dùng với my own OpenAI key: https://github.com/Pythagora-io/gpt-pilot/wiki/Using-Pythagora-with-your-own-OpenAI-key

Nhưng dù config đúng vẫn ko dùng được. Mình chịu bỏ qua luôn.

Ngoài ra còn bắt login account pythagora nên càng ác cảm.

# 6. ChatDev

https://github.com/OpenBMB/ChatDev

ý tưởng khá hay khi tạo 1 công ty thu nhỏ, mỗi model đảm nhiệm 1 role như CEO, CTO, programmer, tester, designer. Chúng sẽ tự nói chuyện với nhau để tạo ra sản phẩm 🤣

Cái này thực sự làm mình ấn tượng về cách họ dùng ChatGPT để tạo ra sản phẩm

## 6.1. Run on WSL Ubuntu 22.04

```s
git clone https://github.com/OpenBMB/ChatDev.git

python3.10 -m venv venv

source venv/bin/activate

cd ChatDev/
pip3 install -r requirements.txt
export OPENAI_API_KEY="your_OpenAI_API_key"

python3 run.py --task "create a flabby bird game web application runing in javascript" --name "FlabbyBirdHoangmnsd"

python3 run.py --task "using python, create a web application to chat with chatGPT using exist OPENAI API Key" --name "ChatWithGPT"
```

Chỉ cần ngắn gọn như vậy thôi, ChatDev sẽ chia thành các role như CEO, CTO, programmer, tester, blabla để tự thảo luận với nhau và đưa ra câu trả lời cho bạn.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/ai-coding-agent-chatdev-when-finished.jpg)

## 6.2 Run application tạo bởi ChatDev

Code sẽ nằm trong folder này `WareHouse`: 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/ai-coding-agent-chatdev-when-finished-product.jpg)

Giờ mình làm theo hướng dẫn trong file `WareHouse/<PROJECT_NAME>/manual.md`

Nếu gặp lỗi kiểu này:

```s
$ python3.10 main.py
 * Serving Flask app 'main' (lazy loading)
 * Environment: production
   WARNING: This is a development server. Do not use it in a production deployment.
   Use a production WSGI server instead.
 * Debug mode: on
Permission denied
```

Nguyên nhân là do Máy mình ko được phép run trên port 5000, Hãy sửa code thành Flask chạy trên port 8001 chẳng hạn:

```py
if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8001, debug=True)
```

Nếu gặp lỗi kiểu này:

```s
jinja2.exceptions.TemplateNotFound: index.html
```

Có nghĩa là Flask đang tìm html file trong folder `templates/index.html`. Hãy tạo folder và cho file vào đó.

App đang run ở port 8001:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/ai-coding-agent-chatdev-when-finished-product-run1.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/ai-coding-agent-chatdev-when-finished-product-run2.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/ai-coding-agent-chatdev-when-finished-product-run3.jpg)

Trong quá trình run app của ChatDev tạo ra, bạn có thể gặp nhiều lỗi khác nhau (2 lỗi như mình đã liệt kê bên trên). Và 1 số lỗi liên quan đến code kiểu API ko còn support nhưng ChatDev vẫn dùng. (https://stackoverflow.com/a/76027573). 

Điều này có thể thấy là do ChatDev vẫn đang dùng nhưng kiến thức cũ, chưa cập nhật lắm. 

Tuy nhiên ý tưởng là rất táo bạo. 
Trong điều kiện hoàn hảo (Ko có kiến thức nào của ChatDev dùng bị outdate, ko có lỗi môi trường từ phía bạn) Bạn hoàn toàn có thể tốn dưới 1$ cho 1 phần mềm. Rút ngắn quá trình tạo phần mềm đáng kể.

## 6.3. Review quá trình ChatDev tạo ra sản phẩm

Dùng command sau;

```py
python ChatDev/visualizer/app.py
```

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/ai-coding-agent-chatdev-when-finished-chatvisualizer.jpg)

bạn upload file .log trong foldedr của project lên là thấy:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/ai-coding-agent-chatdev-when-finished-chat-replay.jpg)

Bạn sẽ thấy các con bot chat với nhau như thế nào để tạo ra sản phẩm

CEO chat gì, CPO (Product Owner) rồi CTO chat ntn, Programmer, Code Reviewer, Counselor, Designer....

1 cuộc nói chuyện chân thực 🤣🤣

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/ai-coding-agent-chatdev-when-finished-chat-replay-2.jpg)

Code Reviewer tìm ra lỗi:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/ai-coding-agent-chatdev-when-finished-chat-replay-3.jpg)

Nếu bạn muốn đọc kỹ hơn các option thì đọc ở đây: https://github.com/OpenBMB/ChatDev/blob/main/wiki.md

```
usage: run.py [-h] [--config CONFIG] [--org ORG] [--task TASK] [--name NAME] [--model MODEL]

argparse

optional arguments:
  -h, --help       show this help message and exit
  --config CONFIG  Name of config, which is used to load configuration under CompanyConfig/; Please see CompanyConfig Section below
  --org ORG        Name of organization, your software will be generated in WareHouse/name_org_timestamp
  --task TASK      Prompt of your idea
  --name NAME      Name of software, your software will be generated in WareHouse/name_org_timestamp
  --model MODEL    GPT Model, choose from {'GPT_3_5_TURBO','GPT_4','GPT_4_32K'}
```

Hiện ChatDev chưa hỗ trợ gpt-4o gpt-4o-mini. Chọn GPT_4 sẽ khá đắt khi 1 project nhỏ cũng mất hơn 1$

Đối với ChatDev do nhu cầu sử dụng và view file nhiều nên mình nghĩ nên dùng ChatDev run bằng GitBash. Ko nên run bằng WSL. 

## 6.4. Troubleshoot

Trong quá trình install ChatDev, Hiện có thể bạn sẽ gặp lỗi kiểu này: 
```s
TypeError: init() got an unexpected keyword argument 'refusal'
```
Cách fix workaround tạm thời: https://github.com/OpenBMB/ChatDev/issues/413#issuecomment-2283267043

# 7. Localpilot

https://github.com/danielgross/localpilot/issues/12

Proxy từ Github Copilot sang các local model, Nhưng vẫn bắt login Github mình thấy hơi nguy hiểm.

# 8. Lunary

https://github.com/lunary-ai/lunary

ý tướng khá hay, monitor số lượng request token, cost, độ trễ, log, của các LLM models.

Ko hẳn là AI Coding Agent, mà giống như 1 tool để monitoring.

# 9. Swirl

https://github.com/swirlai/swirl-search

ý tưởng là Dùng để tạo 1 web ui cho search. Tài liệu sẽ là Notes/docs/code của cá nhân... giống google, ms365, openai. nhưng dùng để search tài liệu của bạn

Ko hẳn là AI Coding Agent, mà giống như 1 tool search nhỉ?

# 10. Tabby

https://tabby.tabbyml.com/docs/quick-start/installation/docker-compose/

## 10.1. Overview

cũng là kiểu AI Coding agent của VS Code, run open source model locally.

Ưu điểm:
- Phản hồi nhanh, mình cảm thấy khá bất ngờ vì tốc độ dù chỉ chạy CPU mode.
- Document khá clear.
- Có support trên nhiều platform khác nhau (AWS, SkyPilot, Huggingface Space, BentoCloud, Modal... có nói rõ).
- Có support nhiều kiểu install: Linux binary file, Docker container, Windows exe.
- Có support nhiều OS: Windows, WSL, Linux, Macos.
- Có support cả GPU và CPU.

Nhược điểm:
- Docker arm64 chưa support https://github.com/TabbyML/tabby/issues/623.
- (? not sure ?) 
  Đọc issue này thấy Tabby chỉ tự run model, ko có ý định sử dụng các external endpoint như OpenAI, Ollama: https://github.com/TabbyML/tabby/issues/795.
  nhưng lại có docs này nói về OpenAI, Ollama https://tabby.tabbyml.com/docs/references/models-http-api/openai/ (Mình làm theo thì ko đc)
- Hiện mình install vẫn đang bị lỗi bản docker WSL (CPU mode): https://github.com/TabbyML/tabby/discussions/2867

Hiện minh đang install bản binary file trên WSL Ubuntu 22.04. Chạy khá nhanh.

## 10.2. Install Tabby binary file trên Windows WSL ubuntu 22.04

theo guide https://tabby.tabbyml.com/docs/quick-start/installation/linux/#download-the-release

```sh
sudo apt-get install libgomp1
cd ~/test-tabby/
wget https://github.com/TabbyML/tabby/releases/download/nightly/tabby_x86_64-manylinux2014.zip
mkdir tabby-binary/
unzip -d tabby-binary/ tabby_x86_64-manylinux2014.zip

# direct to binary files

chmod +x tabby llama-server
# For CPU-only environments
./tabby serve --model StarCoder-1B --chat-model Qwen2-1.5B-Instruct
```

log OK:
```
  As an open source project, we collect usage statistics to inform development priorities. For more
  information, read https://tabby.tabbyml.com/docs/configuration#usage-collection

  We will not see or any code in your development process.

  Welcome to Tabby!

  If you have any questions or would like to engage with the Tabby team, please join us on Slack
  (https://links.tabbyml.com/join-slack-terminal).



████████╗ █████╗ ██████╗ ██████╗ ██╗   ██╗
╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝
   ██║   ███████║██████╔╝██████╔╝ ╚████╔╝
   ██║   ██╔══██║██╔══██╗██╔══██╗  ╚██╔╝
   ██║   ██║  ██║██████╔╝██████╔╝   ██║
   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚═════╝    ╚═╝

📄 Version 0.16.0-dev.0
🚀 Listening at http://0.0.0.0:8080



  JWT secret is not set

  Tabby server will generate a one-time (non-persisted) JWT secret for the current process.
  Please set the TABBY_WEBSERVER_JWT_TOKEN_SECRET environment variable for production usage.

```

Rồi trên Window Powershell get WSL ip: `wsl hostname -I` hoặc `wsl hostname -i` ví dụ lấy được `172.27.45.193`

Rồi mở Chrome sẽ access được tabby qua port 8080: http://172.27.45.193:8080

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-sign-up-screen.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-sign-up-screen-2.jpg)

account: user/password

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-dashboard.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-dashboard-chat.jpg)

Bạn có thể chat với nó luôn. Trả lời khá nhanh, có lẽ vì dùng model `Qwen2-1.5B-Instruct`? Chứ mình chạy Lmstudio chat với nó chậm vl.

Vào setting để xem có rất nhiều feature thú vị:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-setting-system-info.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-setting-joib-info.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-setting-report-info.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-setting-act-info.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-setting-general-info.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-setting-mem-info.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-setting-subs-info.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-setting-context-info.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-setting-sso-info.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-setting-mail-info.jpg)

Trên VS Code install Tabby extension, rồi vào đây update token và endpoint url:
`C:\Users\USER_NAME\.tabby-client\agent\config.toml`
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-setting-vs-code-config.jpg)

Dù sửa ở file `config.toml`, nhưng vào VS Code, nhìn góc dưới bên phải và Tabby vẫn báo lỗi màu vàng:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-setting-vs-code-error.jpg)

Thì phải enter token và server endpoint vào VS Code:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-setting-vs-code-config-token.jpg)

Làm sao để Chữ Tabby hiện dấu tick KHÔNG màu vàng là OK.
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-setting-vs-code-config-ok.jpg)

Vào VS Code tạo 1 file để test: viết comment, xong cứ tab theo là nó tự generate ra code. Rất Hay. Và khá nhanh, nhanh đến mức làm mình bất ngờ:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-setting-vs-code-demo.jpg)

## 10.3. Install Tabby binary file trên Linux Ubuntu 22.04 VM

Tuy nhiên binary thì vẫn sẽ bị lỗi, có lẽ bị tabby chưa support arm64 ?:

```s
$ ./tabby serve --model StarCoder-1B --chat-model Qwen2-1.5B-Instruct
-bash: ./tabby: cannot execute binary file: Exec format error
```

## 10.4. Install Tabby trên Modal.com

Để tạo account modal.com, bạn cần link nó với Github (mình tạo riêng 1 account github để link modal)

Cài đặt modal:

```s
$ python3.10 -m pip install modal
```

Kết nối máy local với Modal để deploy code lên:

```s
$ python3.10 -m modal setup
```

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-modal-setup.jpg)

Đến đây modal đưa 1 link để bạn truy cập.

Sau khi mở link trên trình duyệt đã login Github và Modal, bạn sẽ cần Authorize token API: (ảnh)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-modal-authorize.jpg)

Giao diện Modal sau khi đã Authorized:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-modal-dashboard.jpg)

Giao diện Terminal sau khi đã Authorized:

```s
$ python3 -m modal setup
The `modal` command was not found on your path!
You may need to add it to your path or use `python -m modal` as a workaround.
See more information here:

https://modal.com/docs/guide/troubleshooting#command-not-found-errors

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Was not able to launch web browser
Please go to this URL manually and complete the flow:

https://modal.com/token-flow/tf-XXX

Web authentication finished successfully!
Token is connected to the GITHUB_USERNAME workspace.
Verifying token against https://api.modal.com
Token verified successfully!
Token written to /home/USER_NAME/.modal.toml in profile GITHUB_USERNAME.
```

Làm theo guide: https://tabby.tabbyml.com/docs/quick-start/installation/modal/

Copy code trong file: https://github.com/TabbyML/tabby/blob/main/website/docs/quick-start/installation/modal/app.py

Trong WSL tạo file `~/tabby-deployment/app.py`, sửa nội dung chỗ này `allow_concurrent_inputs=200` để tránh lỗi "cứ tạo container mới" về sau:
```py
@app.function(
    gpu=GPU_CONFIG,
    allow_concurrent_inputs=200,
    container_idle_timeout=120,
    timeout=360,
)
```

### Serve app từ local lên Modal

```s
$ python3 -m modal serve app.py
✓ Initialized. View run at https://modal.com/apps/GITHUB_USERNAME/main/ap-oOhoNp6GE4ZEyLRG6nPoAj
Building image im-p2iVn8dvfr4jJHHA2vD53Q

...
Built image im-YWVKlo7mQ5FroC5LEIXGxt in 3.78s
✓ Created objects.
├── 🔨 Created mount /home/USER_NAME/test-modal/app.py
├── 🔨 Created function download_model.
├── 🔨 Created function download_model.
├── 🔨 Created function download_model.
└── 🔨 Created web function app_serve => https://GITHUB_USERNAME--tabby-server-app-serve-dev.modal.run
️️⚡️ Serving... hit Ctrl-C to stop!
└── Watching /home/USER_NAME/test-modal.
⠴ Running (6 containers finished)... View app at https://modal.com/apps/GITHUB_USERNAME/main/ap-oOhoNp6GE4ZEyLRG6nPoAj
```

Vẫn giữ terminal đang chạy, vào link https://GITHUB_USERNAME--tabby-server-app-serve-dev.modal.run

Nếu bạn Ctrl+C ở terminal thì nó cũng sẽ terminate cái app đang run trên Modal.

### Deploy app từ local lên Modal

```s
$ MODAL_FORCE_BUILD=1 python3.10 -m modal deploy app.py
Building image im-HDPO6oYXTb9cHnaVW5EgDJ
...
Image saved, took 1.55s

Built image im-M0269EbwJ9Hf0prQIHkSQP in 4.66s
✓ Created objects.
├── 🔨 Created mount /home/USERNAME/test-modal/app.py
├── 🔨 Created function download_model.
├── 🔨 Created function download_model.
├── 🔨 Created function download_model.
└── 🔨 Created web function app_serve => https://GITHUB_USERNAME--tabby-server-app-serve.modal.run
✓ App deployed in 170.844s! 🎉

View Deployment: https://modal.com/apps/GITHUB_USERNAME/main/deployed/tabby-server
```

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-modal-tabby-ui.jpg)

Giờ trên VS Code config lại các endpoint, token để Tabby trỏ đến. 

Tận hưởng feature tabAutocomplete rất thú vị mà Tabby đem lại 😘 Khá nhanh. Không khác gì chạy local.

1 số hình ảnh trên Modal dashboard:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-modal-apps.jpg)

các thông số ví dụ như mỗi container nhận Concurrent input là 200:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-modal-apps-details.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-modal-apps-files.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-modal-apps-func-calls.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-modal-logs.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-modal-secrets.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-modal-storage.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-modal-apps2.jpg)

trạng thái idle bạn sẽ ko bị tính tiền:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-modal-idle.jpg)

### Một số vấn đề mình đang gặp phải [PENDING]

Persistant data container:

Nếu bạn ko dùng VSCode 1 thời gian nó sẽ tự động đưa Modal container Tabby vào trạng thái `idle`.

Bạn quay lại VS Code rồi gõ 1 cái gì đó, sẽ trigger request đến Modal container Tabby và launch 1 container mới.

Nhưng container này Ko có data gì của bạn. Giống kiểu ko được mount volume vậy.

Bạn sẽ lại phải vào link Modal Tabby, tạo lại account admin, token. Rồi vào config của VS Code extension Tabby - insert token mới.

Để giải quyết vấn đề này thì mình cần đọc thêm tài liệu ở đây:

https://tabby.tabbyml.com/docs/administration/backup/

https://modal.com/docs/guide/cloud-bucket-mounts -> mount bucket s3

https://modal.com/docs/guide/mounting -> upload cả folder local lên

https://modal.com/docs/reference/cli/container -> command làm việc với modal container

https://modal.com/docs/guide/secrets#using-secrets -> get secret từ modal về

Nhưng vẫn chưa tìm được cách để persistent data. Đã thử các hướng đi sau:

- mount `/data/ee` vào s3 nhưng sẽ bị lỗi này:

```s
⠏     3.200 s	Starting...
The application panicked (crashed).
Message:  Must be able to initialize db: migration 35 was previously applied but is missing in the resolved migrations
Location: /root/workspace/ee/tabby-webserver/src/webserver.rs:53
```

- ko dùng mount mà upload sẵn 1 file `db.sqlite` lên s3, trong code `app.py` thì download file đó về folder `/data/ee`. Nhưng sẽ vẫn ko login được với account đã có trong `db.sqlite`. Ko hiểu vì sao.

- mình nghĩ là do file `db.sqlite` ở máy local ko tương thích với bản trên modal nên thử cách tạo riêng 1 file `upload-db.py` để sau khi app đã chạy thì exec vào container upload `db.sqlite` lên s3 như này:

    ```s
    ~/tabby-modal-deploy$ python3.10 -m modal container list
                                            Active Containers
    ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━┓
    ┃ Container ID                  ┃ App ID                    ┃ App Name     ┃ Start Time           ┃
    ┡━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━┩
    │ ta-01J5JT8BEQJSRSPVK717HJA1T9 │ ap-4GDFNbZ0vhsI8a3odHpFWb │ tabby-server │ 2024-08-18 20:21 +07 │
    └───────────────────────────────┴───────────────────────────┴──────────────┴──────────────────────┘
    ~/tabby-modal-deploy$ python3.10 -m modal container exec ta-01J5JT8BEQJSRSPVK717HJA1T9 ls /root
    tabby-modal-deploy

    ~/tabby-modal-deploy$ python3.10 -m modal container exec ta-01J5JT8BEQJSRSPVK717HJA1T9 ls /root/tabby-modal-deploy
    __pycache__  app.py  app.py-bk2  app.py.bk  upload-db.py

    ~/tabby-modal-deploy$ python3.10 -m modal container exec ta-01J5JT8BEQJSRSPVK717HJA1T9 python /root/tabby-modal-deploy/upload
    -db.py
    Uploaded /data/ee/db.sqlite to s3://S3_BUCKET_NAME/hoangmnsd/ee/db.sqlite
    ```

  Sau đó deploy lại app, trong app sẽ download file `db.sqlite` chính nó vừa upload lên s3. 
  Nhưng kết quả vẫn bị lỗi ko thể login.

Code `app.py` hiện đang như này nếu sau này mình muốn quay lại làm tiếp:

```py
"""Usage:
modal serve app.py

To force a rebuild by pulling the latest image tag, use:
MODAL_FORCE_BUILD=1 modal serve app.py
"""

import os
from modal import Image, App, asgi_app, gpu, Volume, Secret, CloudBucketMount

IMAGE_NAME = "tabbyml/tabby"
MODEL_ID = "TabbyML/StarCoder-1B"
CHAT_MODEL_ID = "TabbyML/Qwen2-1.5B-Instruct"
EMBEDDING_MODEL_ID = "TabbyML/Nomic-Embed-Text"
GPU_CONFIG = gpu.T4()

TABBY_BIN = "/opt/tabby/bin/tabby"

s3_bucket_name = "tabby-modal"  # Bucket name not ARN.
prefix_ee = 'hoangmnsd/ee/'

def download_model(model_id: str):
    import subprocess

    subprocess.run(
        [
            TABBY_BIN,
            "download",
            "--model",
            model_id,
        ]
    )

def download_file_from_s3(bucket_name: str, object_key: str, file_dir: str, file_name: str):
    import boto3
    s3 = boto3.client(
        's3',
        aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"], # these env get from Secret "tabbymodalsyncs3" on Modal
        aws_secret_access_key=os.environ["AWS_SECRET_ACCESS_KEY"], # these env get from Secret "tabbymodalsyncs3" on Modal
        region_name=os.environ["AWS_REGION"], # these env get from Secret "tabbymodalsyncs3" on Modal
    )
    local_file_path = file_dir + file_name
    s3.download_file(bucket_name, object_key, local_file_path)
    print(f"Downloaded s3://{bucket_name}/{object_key} to {local_file_path}")

def upload_file_to_s3(bucket_name: str, object_key: str, file_dir: str, file_name: str):
    import boto3
    s3 = boto3.client(
        's3',
        aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"], # these env get from Secret "tabbymodalsyncs3" on Modal
        aws_secret_access_key=os.environ["AWS_SECRET_ACCESS_KEY"], # these env get from Secret "tabbymodalsyncs3" on Modal
        region_name=os.environ["AWS_REGION"], # these env get from Secret "tabbymodalsyncs3" on Modal
    )
    local_file_path = file_dir + file_name
    s3.upload_file(local_file_path, bucket_name, object_key)
    print(f"Uploaded {local_file_path} to s3://{bucket_name}/{object_key}")

def download_s3():
    specific_file_key = 'hoangmnsd/ee/db.sqlite'
    downloaded_file_name = 'db.sqlite'
    downloaded_file_dir = '/data/ee/'
    download_file_from_s3(s3_bucket_name, specific_file_key, downloaded_file_dir, downloaded_file_name)

def upload_s3():
    specific_file_key = 'hoangmnsd/ee/db.sqlite'
    local_file_name = 'db.sqlite'
    local_file_dir = '/data/ee/'
    upload_file_to_s3(s3_bucket_name, specific_file_key, local_file_dir, local_file_name)

image = (
    Image.from_registry(
        IMAGE_NAME,
        add_python="3.11",
    )
    .dockerfile_commands("ENTRYPOINT []")
    .run_function(download_model, kwargs={"model_id": EMBEDDING_MODEL_ID})
    .run_function(download_model, kwargs={"model_id": CHAT_MODEL_ID})
    .run_function(download_model, kwargs={"model_id": MODEL_ID})
    .pip_install("asgi-proxy-lib")
    .pip_install("boto3")
)

app = App("tabby-server", image=image)

@app.function(
    gpu=GPU_CONFIG,
    allow_concurrent_inputs=200,
    container_idle_timeout=120,
    timeout=360,
    secrets=[Secret.from_name("tabbymodalsyncs3")], # you need to create Secret "tabbymodalsyncs3" on Modal first
)

@asgi_app()
def app_serve():
    import socket
    import subprocess
    import time
    from asgi_proxy import asgi_proxy

    launcher = subprocess.Popen(
        [
            TABBY_BIN,
            "serve",
            "--model",
            MODEL_ID,
            "--chat-model",
            CHAT_MODEL_ID,
            "--port",
            "8000",
            "--device",
            "cuda",
            "--parallelism",
            "1",
        ]
    )

    # Poll until webserver at 127.0.0.1:8000 accepts connections before running inputs.
    def tabby_ready():
        try:
            socket.create_connection(("127.0.0.1", 8000), timeout=1).close()
            return True
        except (socket.timeout, ConnectionRefusedError):
            # Check if launcher webserving process has exited.
            # If so, a connection can never be made.
            retcode = launcher.poll()
            if retcode is not None:
                raise RuntimeError(f"launcher exited unexpectedly with code {retcode}")
            return False

    while not tabby_ready():
        time.sleep(1.0)

    # Wait briefly to allow the "serve" command to initialize
    time.sleep(60)  # Adjust the sleep duration as necessary for your use case
    print("--debug1")
    subprocess.run(["ls", "/data/ee/"])
    # subprocess.run(["mkdir", "-p", "/data/ee"]) # prepare ee dir to prevent error https://stackoverflow.com/a/73193346/9922066
    print("--debug2")
    download_s3()
    subprocess.run(["ls", "/data/ee/"])
    # upload_s3()
    print("Tabby server ready!")
    return asgi_proxy("http://localhost:8000")
```


## 10.5. Install Tabby trên Huggingface Space

HF có nhiều loại Plan:
- Pro: account 9$/month
- Space: gần như là Serverless, set inactive time để container stop nếu ko có traffic. Free 2 cpu / 16G RAM. Pricing: https://huggingface.co/pricing#spaces
- Inference endpoints: gần như Serverless. Pricing: https://huggingface.co/pricing#endpoints

Hiện tại để dùng được HF Space cần add credit card. HuggingFace hiện vẫn chưa cho phép mua pre-paid Credit bằng thẻ. (Khoản này kém OpenAI)

Guide install Tabby:
- https://tabby.tabbyml.com/docs/quick-start/installation/hugging-face/
- https://huggingface.co/docs/hub/spaces-sdks-docker-tabby

Việc deploy đơn giản là do Tabby đã có sẵn 1 space template và ta ấn vào link là nó tự duplicate space đó luôn. Chả phải code gì

Ấn vào link: https://huggingface.co/spaces/TabbyML/tabby-template-space?duplicate=true

Ở đây mình cố tình chọn các option FREE ko tính tiền:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-hf-duplicate-space-1.jpg)

Chờ container log deploy xong:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-hf-duplicate-space-2.jpg)

Nếu thấy lỗi nhiều như này, khả năng nguyên nhân do mình chọn Hardware CPU ko có GPU:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-hf-duplicate-space-containerlog.jpg)

Thử sửa lại Dockerfile rồi commit lên main:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-hf-duplicate-space-edit-Dockerfile.jpg)

Sửa xong, commit xong thì nhớ Restart Space để run lại container:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/tabby-ai-coding-agent-hf-duplicate-space-restart.jpg)

Sau 1 hồi vẫn ko fix được lỗi này. Chịu. Có lẽ cần chờ Tabby họ release Docker images fix được hết lỗi.

Nếu muốn bạn có thể thử deploy bản dùng GPU (mất tiền) để thử (Chắc sẽ ko có lỗi như trên)

## 10.6. Install Tabby trên BentoCloud

Khi đăng ký BentoCloud họ cho trước 10$ credit. Không hào phóng như Modal cho 30$.

https://tabby.tabbyml.com/docs/quick-start/installation/bentoml/

Xem guide của Tabby thấy nhiều file hơn Modal.

Lại còn sync file từ R2 Cloudflare nữa nên phải setup nhiều thứ quá, mình nản ko muốn làm.

Dọc kỹ thì ý tưởng đối với R2 Cloudflare là để khi shutdown thì upload `.tabby` database lên R2. Khi deploy thì download về để persist database. (**Là điều mà trong Guideline Tabby với Modal chưa làm**)

# 11. Tabnine

# 12. Blackbox

# 13. Codeium

# REFERENCES

https://dev.to/lunary/7-open-source-ai-projects-to-code-faster-in-2023-2306

Tabby recommend cấu hình phần cứng (GPU) cho các model ở đây: https://tabby.tabbyml.com/docs/models/

Tabby xếp hạng các model ở đây: https://leaderboard.tabbyml.com/

1 số ví dụ để deploy các app của bạn lên Modal: https://modal.com/docs/examples/web-scraper
