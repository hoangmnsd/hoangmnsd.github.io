---
title: "AI Model for serverless running"
date: 2024-08-09T21:56:40+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Serverless,MachineLearning,AI,Stable-Diffusion]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Nhu cầu về dùng AI để chỉnh sửa ảnh, video đang tăng lên, tương lai của Designer và Photoshop bị đe dọa nếu ko cập nhật"
---

# Story

Nhu cầu sử dụng AI trong công việc ngày càng lớn trong hiện tại và tương lai

Sau 1 thời gian tìm hiểu mình chia 2 hướng để viết bài:
- Hướng dẫn run AI model local.
- Hướng dẫn run AI model trên serverless platform. (**Chính là bài viết này**)

Trong bài này mình sẽ lướt qua các platform sau là nơi để run các AI model 1 cách Serverless:
- HuggingFace Serverless / Huggingface Space
- Google Colab
- Amazon SageMaker
- Runpod.io
- Monster.ai
- Openrouter.ai (giống 1 nơi tổng hợp các API trả phí hơn là cho deploy serverless)
- Modal.com
- BentoCloud
- Skypilot

# 1. AWS SageMaker

Đã có 1 bài riêng ([link](../../posts/encrypt-aws-run-llm-on-sagemaker/)).

Khá đắt, và ngay cả Serverless Endpoint thì cũng quá khó deploy vì có nhiều hạn chế như RAM chỉ có max 6GB. Trong khi Model toàn nặng vl.

# 2. Modal.com

Đã có 1 bài đề cập ([10.4. Install Tabby trên Modal.com](../../posts/encrypt-ai-coding-assistant/)).

Ngoài ra Modal có rất nhiều ví dụ thú vị khác ở đây:
- https://modal.com/docs/examples/
- https://github.com/modal-labs/modal-examples

Source code cá nhân chi tiết đề cập mình để trong repo này: https://gitlab.com/inmessionante/hmnsd-test-modal.git

## 2.1. Run ControlNet

Hôm nay mình sẽ làm example Controlnet này: https://modal.com/docs/examples/controlnet_gradio_demos

Nguồn gốc của Controlnet là ở đây https://github.com/lllyasviel/ControlNet

Code mẫu deploy Controlnet on Modal: https://github.com/modal-labs/modal-examples/blob/main/06_gpu_and_ml/controlnet/controlnet_gradio_demos.py

Link huggingface của controlnet: https://huggingface.co/lllyasviel/sd-controlnet-hed/tree/main

Ví dụ này cung cấp 10 demo về các model mà Controlnet làm cho bạn xem. Chi tiết nên chọn model nào và ví dụ tương ứng thì xem ở link này:
https://github.com/lllyasviel/ControlNet


### 2.1.1. Quick serve

Ví dụ để chạy demo model "scribble" mình sẽ copy y nguyên file này: https://github.com/USERNAME/modal-examples/blob/main/06_gpu_and_ml/controlnet/controlnet_gradio_demos.py

sửa tên file thành `controlnet_gradio_demos_scribble.py`

sửa đoạn này để tên app trên Modal cho dễ nhìn là biết đang run demo nào:
```py
app = modal.App(name="controlnet-" + DEMO_NAME, image=image)
```

Rồi trên WSL run:

```sh
python3.10 -m modal serve ./controlnet_gradio_demos_scribble.py
```

Truy cập vào endpoint hiện ra và enjoy chỉnh sửa ảnh thôi 😁


### 2.1.2. Troubleshoot

1 số demo "canny, depth, hough, pose, scribble, scribble_interactive, seg" chạy OK.

1 số demo "fakescribble, hed, normal" đang bị lỗi này:

```s
/usr/local/lib/python3.10/site-packages/pytorch_lightning/plugins/training_type/ddp.py:68: DeprecationWarning: `TorchScript` support for functional optimizers is deprecated and will be removed in a future PyTorch release. Consider using the `torch.compile` optimizer instead.
  from torch.distributed.optim import DistributedOptimizer
Traceback (most recent call last):
  File "/pkg/modal/_container_io_manager.py", line 594, in handle_user_exception
    yield
  File "/pkg/modal/_container_entrypoint.py", line 807, in main
    finalized_functions = service.get_finalized_functions(function_def, container_io_manager)
  File "/pkg/modal/_container_entrypoint.py", line 153, in get_finalized_functions
    web_callable = construct_webhook_callable(
  File "/pkg/modal/_container_entrypoint.py", line 77, in construct_webhook_callable
    return asgi_app_wrapper(user_defined_callable(), container_io_manager)
  File "/root/controlnet_gradio_demos_fakescribble.py", line 300, in run
    blocks=import_gradio_app_blocks(demo=selected_demo),
  File "/root/controlnet_gradio_demos_fakescribble.py", line 270, in import_gradio_app_blocks
    mod = importlib.import_module(module_name)
  File "/usr/local/lib/python3.10/importlib/__init__.py", line 126, in import_module
    return _bootstrap._gcd_import(name[level:], package, level)
  File "<frozen importlib._bootstrap>", line 1050, in _gcd_import
  File "<frozen importlib._bootstrap>", line 1027, in _find_and_load
  File "<frozen importlib._bootstrap>", line 1006, in _find_and_load_unlocked
  File "<frozen importlib._bootstrap>", line 688, in _load_unlocked
  File "<frozen importlib._bootstrap_external>", line 883, in exec_module
  File "<frozen importlib._bootstrap>", line 241, in _call_with_frames_removed
  File "/root/gradio_fake_scribble2image.py", line 18, in <module>
    apply_hed = HEDdetector()
  File "/root/annotator/hed/__init__.py", line 61, in __init__
    from basicsr.utils.download_util import load_file_from_url
  File "/usr/local/lib/python3.10/site-packages/basicsr/__init__.py", line 4, in <module>
    from .data import *
  File "/usr/local/lib/python3.10/site-packages/basicsr/data/__init__.py", line 22, in <module>
    _dataset_modules = [importlib.import_module(f'basicsr.data.{file_name}') for file_name in dataset_filenames]
  File "/usr/local/lib/python3.10/site-packages/basicsr/data/__init__.py", line 22, in <listcomp>
    _dataset_modules = [importlib.import_module(f'basicsr.data.{file_name}') for file_name in dataset_filenames]
  File "/usr/local/lib/python3.10/importlib/__init__.py", line 126, in import_module
    return _bootstrap._gcd_import(name[level:], package, level)
  File "/usr/local/lib/python3.10/site-packages/basicsr/data/realesrgan_dataset.py", line 11, in <module>
    from basicsr.data.degradations import circular_lowpass_kernel, random_mixed_kernels
  File "/usr/local/lib/python3.10/site-packages/basicsr/data/degradations.py", line 8, in <module>
    from torchvision.transforms.functional_tensor import rgb_to_grayscale
ModuleNotFoundError: No module named 'torchvision.transforms.functional_tensor'
Runner failed with exception: ModuleNotFoundError("No module named 'torchvision.transforms.functional_tensor'")
```

Để fix lỗi như phần "hed" có nhể sửa cái này, add thêm vào function `pip_install` 2 pip package sau `torch và torchvision`:

```py
image = (
    modal.Image.debian_slim(python_version="3.10")
    .pip_install(
        "gradio==3.16.2",
        ...
        "torch==1.13.0",
        "torchvision==0.14.0"
```

Sau đó run lại thì mình thấy ko còn lỗi model "hed" nữa.
Chưa thử fix các model "fakescribble, normal"...

## 2.2. Run ComfyUI

Để hiểu ComfyUI là gì và có thể làm gì, xem clip này: https://www.youtube.com/watch?v=KTPLOqAMR0s

Có hướng dẫn ở đây:
- https://modal.com/docs/examples/comfyapp
- https://modal.com/blog/comfyui-prototype-to-production

ComfyUI github: https://github.com/comfyanonymous/ComfyUI

ComfyUI có support CPU only nhưng chưa thử.

Bản thân ComfyUI cũng có example repo: https://github.com/comfyanonymous/ComfyUI_examples

### 2.2.1. Quick serve

Làm theo 2 bước trong này: https://modal.com/docs/examples/comfyapp.

lấy file ở đây: https://github.com/modal-labs/modal-examples/blob/main/06_gpu_and_ml/comfyui/comfyapp.py

Chú ý 2 file sau đặt cùng folder `comfyapp.py`, `yosemite_inpaint_example.png`, `workflow_api.json` để code run ko bị lỗi.

Sửa nội dung `comfyapp.py`, mình bỏ hết comment đi và sửa lại để có thể nhận call API với argument `inputimageurl`:

```py
import json
import subprocess
import uuid
from pathlib import Path
from typing import Dict

import modal

image = (  # build up a Modal Image to run ComfyUI, step by step
    modal.Image.debian_slim(  # start from basic Linux with Python
        python_version="3.11"
    )
    .apt_install("git")  # install git to clone ComfyUI
    .pip_install("comfy-cli==1.0.33")  # install comfy-cli
    .run_commands(  # use comfy-cli to install the ComfyUI repo and its dependencies
        "comfy --skip-prompt install --nvidia",
    )
    .run_commands(  # download the inpainting model
        "comfy --skip-prompt model download --url https://huggingface.co/stabilityai/stable-diffusion-2-inpainting/resolve/main/512-inpainting-ema.safetensors --relative-path models/checkpoints"
    )
    .run_commands(  # download a custom node
        "comfy node install image-resize-comfyui"
    )
    # can layer additional models and custom node downloads as needed
)

app = modal.App(name="example-comfyui", image=image)

def download_image(image_url, save_path):
    import requests
    # Send a GET request to the image URL
    response = requests.get(image_url)

    # Check if the request was successful
    if response.status_code == 200:
        # Open a local file with the same name as in the URL
        with open(save_path, 'wb') as file:
            file.write(response.content)
        print(f"Image downloaded: {image_url.split('/')[-1]}")
    else:
        print(f"Failed to download image. Status code: {response.status_code}")

@app.function(
    allow_concurrent_inputs=10,
    concurrency_limit=1,
    container_idle_timeout=30,
    timeout=1800,
    gpu="any",
)
@modal.web_server(8000, startup_timeout=60)
def ui():
    subprocess.Popen("comfy launch -- --listen 0.0.0.0 --port 8000", shell=True)

@app.cls(
    allow_concurrent_inputs=10,
    concurrency_limit=1,
    container_idle_timeout=300,
    gpu="any",
    mounts=[
        modal.Mount.from_local_file(
            Path(__file__).parent / "workflow_api.json",
            "/root/workflow_api.json",
        ),
        # mount input images
        modal.Mount.from_local_file(
            Path(__file__).parent / "yosemite_inpaint_example.png",
            "/root/comfy/ComfyUI/input/yosemite_inpaint_example.png",
        ),
    ],
)
class ComfyUI:
    @modal.enter()
    def launch_comfy_background(self):
        cmd = "comfy launch --background"
        subprocess.run(cmd, shell=True, check=True)

    @modal.method()
    def infer(self, workflow_path: str = "/root/workflow_api.json"):
        # runs the comfy run --workflow command as a subprocess
        cmd = f"comfy run --workflow {workflow_path} --wait"
        subprocess.run(cmd, shell=True, check=True)

        # completed workflows write output images to this directory
        output_dir = "/root/comfy/ComfyUI/output"
        # looks up the name of the output image file based on the workflow
        workflow = json.loads(Path(workflow_path).read_text())
        file_prefix = [
            node.get("inputs")
            for node in workflow.values()
            if node.get("class_type") == "SaveImage"
        ][0]["filename_prefix"]

        # returns the image as bytes
        for f in Path(output_dir).iterdir():
            if f.name.startswith(file_prefix):
                return f.read_bytes()

    @modal.web_endpoint(method="POST")
    def api(self, item: Dict):
        from fastapi import Response

        workflow_data = json.loads(
            (Path(__file__).parent / "workflow_api.json").read_text()
        )

        input_image_url = item["input_image_url"]
        print("input_image_url: %s" % input_image_url)
        input_image_name = input_image_url.split("/")[-1]
        image_save_path = "/root/comfy/ComfyUI/input/" + input_image_name
        download_image(input_image_url, image_save_path)

        # insert the image name
        workflow_data["1"]["inputs"]["image"] = input_image_name

        # insert the prompt
        workflow_data["3"]["inputs"]["text"] = item["prompt"]

        # give the output image a unique id per client request
        client_id = uuid.uuid4().hex
        workflow_data["11"]["inputs"]["filename_prefix"] = client_id

        # save this updated workflow to a new file
        new_workflow_file = f"{client_id}.json"
        json.dump(workflow_data, Path(new_workflow_file).open("w"))

        # run inference on the currently running container
        img_bytes = self.infer.local(new_workflow_file)

        return Response(img_bytes, media_type="image/jpeg")
```

Rồi mới run `modal serve comfyapp.py`.

```s
$ modal serve comfyapp.py
✓ Initialized. View run at https://modal.com/apps/MODAL_WORKSPACE/main/ap-mmKamTC3C3yzmuGx5FYUzo
✓ Created objects.
├── 🔨 Created mount /home/USERNAME/test-comfyui-modal/comfyapp.py
├── 🔨 Created mount /home/USERNAME/test-comfyui-modal/workflow_api.json
├── 🔨 Created mount /home/USERNAME/test-comfyui-modal/yosemite_inpaint_example.png
├── 🔨 Created web function ui => https://MODAL_WORKSPACE--example-comfyui-ui-dev.modal.run
├── 🔨 Created function ComfyUI.*.
├── 🔨 Created function ComfyUI.infer.
└── 🔨 Created web function ComfyUI.api => https://MODAL_WORKSPACE--example-comfyui-comfyui-api-dev.modal.run
⚡️ Serving... hit Ctrl-C to stop!
└── Watching /home/USERNAME/test-comfyui-modal.
```

Nó expose ra 2 link,

1 là UI: https://MODAL_WORKSPACE--example-comfyui-ui-dev.modal.run => vào đây để tương tác với ComfyUI.

2 là API: https://MODAL_WORKSPACE--example-comfyui-comfyui-api-dev.modal.run => dùng để nhận các POST request.

UI:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal.jpg)

API:
Để call API, phải bật thêm 1 terminal nữa để call đến endpoint trên với prompt. Chúng ta sẽ call bằng run file python: https://github.com/modal-labs/modal-examples/blob/main/06_gpu_and_ml/comfyui/comfyclient.py

Sửa lại file `comfyclient.py`, mình bỏ comment và sửa lại 1 chút:

```py
import argparse
import pathlib
import sys
import time

import requests

OUTPUT_DIR = pathlib.Path("/tmp/comfyui")
OUTPUT_DIR.mkdir(exist_ok=True, parents=True)


def main(args: argparse.Namespace):
    url = f"{args.apiUrl}"
    data = {
        "prompt": args.prompt,
        "input_image_url": args.inputImageUrl,
    }
    print(f"Sending request to {url} with prompt: {data['prompt']}")
    print("Waiting for response...")
    start_time = time.time()
    res = requests.post(url, json=data)
    if res.status_code == 200:
        end_time = time.time()
        print(
            f"Image finished generating in {round(end_time - start_time, 1)} seconds!"
        )
        filename = OUTPUT_DIR / f"{slugify(args.prompt)}.png"
        filename.write_bytes(res.content)
        print(f"saved to '{filename}'")
    else:
        if res.status_code == 404:
            print(f"Workflow API not found at {url}")
        res.raise_for_status()


def parse_args(arglist: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()

    parser.add_argument(
       "--apiUrl",
        type=str,
        required=True,
        help="Name of the Modal workspace with the deployed app. Run `modal profile current` to check.",
    )
    parser.add_argument(
        "--prompt",
        type=str,
        required=True,
        help="what to draw in the blank part of the image",
    )
    parser.add_argument(
        "--dev",
        action="store_true",
        help="use this flag when running the ComfyUI server in development mode with `modal serve`",
    )
    parser.add_argument(
        "--inputImageUrl",
        default="https://raw.githubusercontent.com/<REPO_DEFAULT>/test-public-image/main/dog-masked.png",
        type=str,
        help="URL of the image to inpaint",
    )
    return parser.parse_args(arglist[1:])

def slugify(s: str) -> str:
    return s.lower().replace(" ", "-").replace(".", "-").replace("/", "-")[:32]

if __name__ == "__main__":
    args = parse_args(sys.argv)
    main(args)

```

Trước khi call API, bạn cần chuẩn bị trước 1 file image đã được xóa 1 phần nào đó transparent giống file `https://github.com/comfyanonymous/ComfyUI_examples/blob/abcc12912ca11f2f7a36b3a36a4b7651db907459/inpaint/yosemite_inpaint_example.png`

Mình đã từng gặp lỗi do có vẻ ảnh dùng cho prompt ko được xóa transparent nên đưa vào ComfyUI nó trả lại y nguyên.

Vì vậy bạn có thể dùng tool [sau](https://pixlr.com/) để xóa 1 phần nào đó của ảnh thành transparent:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-remove-image-pixel-transparent-pxlr-com.jpg)

Sau đó upload ảnh đó lên 1 github public public chẳng hạn: https://raw.githubusercontent.com/[REPO_NAME]/test-public-image/main/multiple-people-stand-from-bridge-masked.png

Rồi run command sau, đưa vào `--prompt và --inputImageUrl` của bạn:

```s
$ python comfyclient.py --dev --apiUrl "https://MODAL_WORKSPACE--example-comfyui-comfyui-api-dev.modal.run" --prompt "dog wearing red glasses" --inputImageUrl "https://raw.githubusercontent.com/[REPO_NAME]/test-public-image/main/multiple-people-stand-from-bridge-masked.png"

Sending request to https://MODAL_WORKSPACE--example-comfyui-comfyui-api-dev.modal.run/ with prompt: dog wearing red glasses
Waiting for response...
Image finished generating in 55.6 seconds!
saved to '/tmp/comfyui/dog-wearing-red-glasses.png'
```

mở file `/tmp/comfyui/dog-wearing-red-glasses.png` ra để xem kết quả.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-dog-red-glasses.jpg)

Done!

P/s: Bài này đã outdated: https://modal.com/blog/comfyui-prototype-to-production (Giờ ko cần làm nữa vì tut bên trên đã ok với việc `--inputimageurl và --prompt` rồi)

### 2.2.2. Deploy ComfyUI

```s
$ modal deploy comfyapp.py
✓ Created objects.
├── 🔨 Created mount /home/USERNAME/comfyui-modal/comfyapp.py
├── 🔨 Created mount /home/USERNAME/comfyui-modal/yosemite_inpaint_example.png
├── 🔨 Created mount /home/USERNAME/comfyui-modal/workflow_api.json
├── 🔨 Created web function ui => https://MODAL_WORKSPACE--example-comfyui-ui.modal.run
├── 🔨 Created function ComfyUI.*.
├── 🔨 Created function ComfyUI.infer.
└── 🔨 Created web function ComfyUI.api => https://MODAL_WORKSPACE--example-comfyui-comfyui-api.modal.run
✓ App deployed in 6.044s! 🎉

View Deployment: https://modal.com/apps/MODAL_WORKSPACE/main/deployed/example-comfyui
```

Call API đến link API mà câu lệnh trên vừa trả về:

```s
$ python3.10 comfyclient.py --apiUrl "https://MODAL_WORKSPACE--example-comfyui-comfyui-api.modal.run" --prompt "dog wearing red glasses" --inputImageUrl "https://raw.githubusercontent.com/MODAL_WORKSPACE/test-public-image/main/yosemite_inpaint_example-testhlh.png"

Sending request to https://MODAL_WORKSPACE--example-comfyui-comfyui-api.modal.run with prompt: dog wearing red glasses
Waiting for response...
Image finished generating in 27.1 seconds!
saved to '/tmp/comfyui/dog-wearing-red-glasses.png'
```

Kết quả:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-dog-red-glasses.jpg)

## 2.3. Run Dreambooth

Các ví dụ về dreambooth ở đây: https://dreambooth.github.io/ (kéo xuống xem họ input như nào và output như nào)

Làm theo docs: https://modal.com/docs/examples/dreambooth_app

Hướng làm là đầu tiên sẽ cần chuẩn bị ảnh input đầu vào cho model đã. Ta upload ảnh lên public và sửa link trong file `instance_example_urls.txt`.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/dreambooth-modal-serve-ui-input.jpg)

Rồi sẽ cần chờ `modal run` để training xong model đã.

Sau đó bạn có thể test bằng cách `modal serve`.

Deploy bằng cách `modal deploy`.

### 2.3.1. Train model

Trước tiên cần accept Huggingface term:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/dreambooth-modal-accept-hf-model.jpg)

Tạo HF token:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/dreambooth-modal-accept-hf-model-token.jpg)

Add HF token vào Modal Secret:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/dreambooth-modal-accept-hf-modal-token.jpg)

Sửa code để đưa thông tin về input của bạn vào chỗ này `instance_name, class_name` (Stacy là tên của nhân vật trong ảnh, còn Woman là class mà nhân vật đó thuộc về):

```py
...
@dataclass
class SharedConfig:
    """Configuration information shared across project components."""

    # The instance name is the "proper noun" we're teaching the model
    instance_name: str = "Stacy"
    # That proper noun is usually a member of some class (person, bird),
    # and sharing that information with the model helps it generalize better.
    class_name: str = "Woman"
    # identifier for pretrained models on Hugging Face
    model_name: str = "black-forest-labs/FLUX.1-dev"
...
```

Tiến hành train model bằng command sau (Chú ý quá trình này mình tốn tầm 6min cho 3 ảnh, khoảng 0.6$):

```s
modal run dreambooth_app.py

# Wait for "✓ App completed. View run at https://modal.com/apps/USERNAME/main/ap-X"
```

```s
$ modal run dreambooth_app.py
✓ Initialized. View run at https://modal.com/apps/USERNAME/main/ap-XXX
Building image im-pzG5D3jQsXbg

=> Step 0: FROM base

...

Saving image...
Image saved, took 57.70s
Finished image build for im-msiMiltKCwdG
✓ Created objects.
├── 🔨 Created mount /home/USERNAME/dreambooth-modal/dreambooth_app.py
├── 🔨 Created mount /home/USERNAME/dreambooth-modal/assets
├── 🔨 Created function download_models.
├── 🔨 Created function train.
├── 🔨 Created function Model.*.
├── 🔨 Created web function fastapi_app => https://USERNAME--example-dreambooth-flux-fastapi-app-dev.modal.run
└── 🔨 Created function Model.inference.

...

08/23/2024 02:05:33 - INFO - __main__ - ***** Running training *****
08/23/2024 02:05:33 - INFO - __main__ -   Num examples = 3
08/23/2024 02:05:33 - INFO - __main__ -   Num batches each epoch = 1
08/23/2024 02:05:33 - INFO - __main__ -   Num Epochs = 250
08/23/2024 02:05:33 - INFO - __main__ -   Instantaneous batch size per device = 3
08/23/2024 02:05:33 - INFO - __main__ -   Total train batch size (w. parallel, distributed & accumulation) = 3
08/23/2024 02:05:33 - INFO - __main__ -   Gradient Accumulation steps = 1
08/23/2024 02:05:33 - INFO - __main__ -   Total optimization steps = 250

...

Steps:  96%|█████████▋| 241/250 [04:53<00:10,  1.22s/it, loss=0.577, lr=0.0004]Steps:  96%|█████████▋| 241/250 [04:53<00:10,  1.22s/it, loss=0.622, lr=0.0004]Steps:  97%|█████████▋| 242/250 [04:54<00:09,  1.22s/it, loss=0.622, lr=0.0004]Steps:  97%|█████████▋| 242/250 [04:54<00:09,  1.22s/it, loss=0.728, lr=0.0004]Steps:  97%|█████████▋| 243/250 [04:55<00:08,  1.22s/it, loss=0.728, lr=0.0004]Steps:  97%|█████████▋| 243/250 [04:55<00:08,  1.22s/it, loss=0.772, lr=0.0004]Steps:  98%|█████████▊| 244/250 [04:56<00:07,  1.22s/it, loss=0.772, lr=0.0004]Steps:  98%|█████████▊| 244/250 [04:56<00:07,  1.22s/it, loss=0.471, lr=0.0004]Steps:  98%|█████████▊| 245/250 [04:57<00:06,  1.22s/it, loss=0.471, lr=0.0004]Steps:  98%|█████████▊| 245/250 [04:57<00:06,  1.22s/it, loss=0.52, lr=0.0004] Steps:  98%|█████████▊| 246/250 [04:59<00:04,  1.22s/it, loss=0.52, lr=0.0004]Steps:  98%|█████████▊| 246/250 [04:59<00:04,  1.22s/it, loss=0.611, lr=0.0004]Steps:  99%|█████████▉| 247/250 [05:00<00:03,  1.22s/it, loss=0.611, lr=0.0004]Steps:  99%|█████████▉| 247/250 [05:00<00:03,  1.22s/it, loss=0.429, lr=0.0004]Steps:  99%|█████████▉| 248/250 [05:01<00:02,  1.22s/it, loss=0.429, lr=0.0004]Steps:  99%|█████████▉| 248/250 [05:01<00:02,  1.22s/it, loss=0.804, lr=0.0004]Steps: 100%|█████████▉| 249/250 [05:02<00:01,  1.22s/it, loss=0.804, lr=0.0004]Steps: 100%|█████████▉| 249/250 [05:02<00:01,  1.22s/it, loss=0.566, lr=0.0004]SSteps: 100%|██████████| 250/250 [05:04<00:00,  1.22s/it, loss=0.647, lr=0.0004]Model weights saved in /model/pytorch_lora_weights.safetensors
                                                                     Loaded text_encoder as CLIPTextModel from `text_encoder` subfolder of black-forest-labs/FLUX.1-dev.peline components...:   0%|          | 0/7 [00:00<?, ?it/s]
                                                                        Loading checkpoint shards: 100%|██████████| 2/2 [00:01<00:00,  1.33it/s]
Loaded text_encoder_2 as T5EncoderModel from `text_encoder_2` subfolder of black-forest-labs/FLUX.1-dev.
                                                                             {'axes_dims_rope'} was not found in config. Values will be initialized to default values.pipeline components...:  29%|██▊       | 2/7 [00:01<00:05,  1.01s/it]
Loaded transformer as FluxTransformer2DModel from `transformer` subfolder of black-forest-labs/FLUX.1-dev.
                                                                             Loaded vae as AutoencoderKL from `vae` subfolder of black-forest-labs/FLUX.1-dev.
Loaded tokenizer as CLIPTokenizer from `tokenizer` subfolder of black-forest-labs/FLUX.1-dev.
                                                                             Loaded tokenizer_2 as T5TokenizerFast from `tokenizer_2` subfolder of black-forest-labs/FLUX.1-dev.omponents...:  71%|███████▏  | 5/7 [00:02<00:00,  2.09it/s]
                                                                             Loaded scheduler as FlowMatchEulerDiscreteScheduler from `scheduler` subfolder of black-forest-labs/FLUX.1-dev.:  86%|████████▌ | 6/7 [00:03<00:00,  2.44it/s]
Loading pipeline components...: 100%|██████████| 7/7 [00:03<00:00,  2.22it/s]
Steps: 100%|██████████| 250/250 [05:08<00:00,  1.23s/it, loss=0.647, lr=0.0004]
Stopping app - local entrypoint completed.
Runner terminated.
✓ App completed. View run at https://modal.com/apps/USERNAME/main/ap-X
```

### 2.3.2. Quick serve

```s
$ modal serve dreambooth_app.py

✓ Initialized. View run at https://modal.com/apps/USERNAME/main/ap-5QD7ZSzkXskF0JPfidjewr
✓ Created objects.
├── 🔨 Created mount /home/USERNAME/dreambooth-modal/dreambooth_app.py
├── 🔨 Created mount /home/USERNAME/dreambooth-modal/assets
├── 🔨 Created function download_models.
├── 🔨 Created function train.
├── 🔨 Created function Model.*.
├── 🔨 Created web function fastapi_app => https://USERNAME--example-dreambooth-flux-fastapi-app-dev.modal.run
└── 🔨 Created function Model.inference.
️️⚡️ Serving... hit Ctrl-C to stop!
├── Watching /home/USERNAME/dreambooth-modal/assets.
└── Watching /home/USERNAME/dreambooth-modal.
⠋ Running app...
```

Truy cập link được tạo ra bởi `modal serve`

Test thôi! 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/dreambooth-modal-serve-ui-input-empty.jpg)

Quá trình generate ảnh sẽ mất khoảng 50-100s.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/dreambooth-modal-serve-ui.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/dreambooth-modal-serve-ui-2.jpg)

Do cái ứng dụng này nếu có deploy thì dùng API cũng ko tối ưu lắm vì nó run lâu, nên mình ko làm phần deploy nữa.

### 2.3.3. Troubleshoot

Khi bạn ĐANG run `modal run dreambooth.py`, Nó sẽ trả ra 1 endpoint để mình truy cập:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/dreambooth-modal-ui-command.jpg)

Bạn lúc này ra dc giao diện Dreambooth:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/dreambooth-modal-ui.jpg)

nhưng khi prompt thì lại có lỗi như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/dreambooth-modal-ui-error.jpg)
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/dreambooth-modal-ui-error-cmd.jpg)

```s
3 images loaded
launching dreambooth training script
/usr/local/lib/python3.10/site-packages/accelerate/accelerator.py:399: UserWarning: `log_with=tensorboard` was passed but no supported trackers are currently installed.
  warnings.warn(f"`log_with={log_with}` was passed but no supported trackers are currently installed.")
Detected kernel version 4.4.0, which is below the recommended minimum of 5.5.0; this can cause the process to hang. It is recommended to upgrade the kernel to the minimum version or higher.
08/22/2024 15:31:50 - INFO - __main__ - Distributed environment: NO
Num processes: 1
Process index: 0
Local process index: 0
Device: cuda

Mixed precision type: bf16

You set `add_prefix_space`. The tokenizer needs to be converted from the slow tokenizers
/usr/local/lib/python3.10/site-packages/huggingface_hub/file_download.py:1150: FutureWarning: `resume_download` is deprecated and will be removed in version 1.0.0. Downloads always resume when possible. If you want to force a new download, use `force_download=True`.
  warnings.warn(
You are using a model of type clip_text_model to instantiate a model of type . This is not supported for all configurations of models and can yield errors.
You are using a model of type t5 to instantiate a model of type . This is not supported for all configurations of models and can yield errors.
Downloading shards:   0%|          | 0/2 [00:00<?, ?it/s]Downloading shards: 100%|██████████| 2/2 [00:00<00:00, 2525.93it/s]
Loading checkpoint shards:   0%|          | 0/2 [00:00<?, ?it/s]Loading checkpoint shards:  50%|█████     | 1/2 [00:04<00:04,  4.34s/it]Loading checkpoint shards: 100%|██████████| 2/2 [00:07<00:00,  3.57s/it]Loading checkpoint shards: 100%|██████████| 2/2 [00:07<00:00,  3.69s/it]
Fetching 3 files:   0%|          | 0/3 [00:00<?, ?it/s]Fetching 3 files: 100%|██████████| 3/3 [00:00<00:00, 49344.75it/s]
{'axes_dims_rope'} was not found in config. Values will be initialized to default values.
08/22/2024 15:32:27 - INFO - __main__ - ***** Running training *****
08/22/2024 15:32:27 - INFO - __main__ -   Num examples = 3
08/22/2024 15:32:27 - INFO - __main__ -   Num batches each epoch = 1
08/22/2024 15:32:27 - INFO - __main__ -   Num Epochs = 250
08/22/2024 15:32:27 - INFO - __main__ -   Instantaneous batch size per device = 3
08/22/2024 15:32:27 - INFO - __main__ -   Total train batch size (w. parallel, distributed & accumulation) = 3
08/22/2024 15:32:27 - INFO - __main__ -   Gradient Accumulation steps = 1
08/22/2024 15:32:27 - INFO - __main__ -   Total optimization steps = 250
Loading pipeline components...:  14%|█▍        | 1/7 [00:01<00:10,  1.79s/it]You set `add_prefix_space`. The tokenizer needs to be converted from the slow tokenizers
Loading checkpoint shards: 100%|██████████| 2/2 [00:06<00:00,  3.06s/it]s/it]
Loading pipeline components...: 100%|██████████| 7/7 [00:30<00:00,  4.39s/it]
Traceback (most recent call last):
Runner failed with exception: OSError('Error no file named pytorch_lora_weights.bin found in directory /model.')
  File "/pkg/modal/_container_io_manager.py", line 594, in handle_user_exception
    yield
  File "/pkg/modal/_container_entrypoint.py", line 668, in call_lifecycle_functions
    res = func(*args)
  File "/root/dreambooth_app.py", line 371, in load_model
    pipe.load_lora_weights(MODEL_DIR)
  File "/root/src/diffusers/loaders/lora_pipeline.py", line 1614, in load_lora_weights
    state_dict = self.lora_state_dict(pretrained_model_name_or_path_or_dict, **kwargs)
  File "/usr/local/lib/python3.10/site-packages/huggingface_hub/utils/_validators.py", line 114, in _inner_fn
    return fn(*args, **kwargs)
  File "/root/src/diffusers/loaders/lora_pipeline.py", line 1565, in lora_state_dict
    state_dict = cls._fetch_state_dict(
  File "/root/src/diffusers/loaders/lora_base.py", line 295, in _fetch_state_dict
    model_file = _get_model_file(
  File "/usr/local/lib/python3.10/site-packages/huggingface_hub/utils/_validators.py", line 114, in _inner_fn
    return fn(*args, **kwargs)
  File "/root/src/diffusers/utils/hub_utils.py", line 310, in _get_model_file
    raise EnvironmentError(
OSError: Error no file named pytorch_lora_weights.bin found in directory /model.
```

Nguyên nhân: command `modal run` vẫn chưa xong, bạn cần phải chờ nó xong hoàn toàn nhé.

## 2.4. Run Stable Diffusion XL Turbo Image-to-image

Link docs: https://modal.com/docs/examples/stable_diffusion_xl_turbo

### 2.4.1. Quick run

Sửa file `https://github.com/modal-labs/modal-examples/blob/main/06_gpu_and_ml/stable_diffusion/stable_diffusion_xl_turbo.py` thành:

```py
# ## Basic setup
import argparse
from io import BytesIO
from pathlib import Path
import modal

# ## Define a container image
image = modal.Image.debian_slim().pip_install(
    "Pillow~=10.1.0",
    "diffusers~=0.24.0",
    "transformers~=4.35.2",  # This is needed for `import torch`
    "accelerate~=0.25.0",  # Allows `device_map="auto"``, which allows computation of optimized device_map
    "safetensors~=0.4.1",  # Enables safetensor format as opposed to using unsafe pickle format
)

app = modal.App("stable-diffusion-xl-turbo", image=image)

with image.imports():
    import torch
    from diffusers import AutoPipelineForImage2Image
    from diffusers.utils import load_image
    from huggingface_hub import snapshot_download
    from PIL import Image

@app.cls(gpu=modal.gpu.A10G(), container_idle_timeout=240)
class Model:
    @modal.build()
    def download_models(self):
        # Ignore files that we don't need to speed up download time.
        ignore = [
            "*.bin",
            "*.onnx_data",
            "*/diffusion_pytorch_model.safetensors",
        ]
        snapshot_download("stabilityai/sdxl-turbo", ignore_patterns=ignore)

    @modal.enter()
    def enter(self):
        self.pipe = AutoPipelineForImage2Image.from_pretrained(
            "stabilityai/sdxl-turbo",
            torch_dtype=torch.float16,
            variant="fp16",
            device_map="auto",
        )

    @modal.method()
    def inference(self, image_bytes, prompt):
        init_image = load_image(Image.open(BytesIO(image_bytes))).resize(
            (512, 512)
        )
        num_inference_steps = 4
        strength = 0.9
        # "When using SDXL-Turbo for image-to-image generation, make sure that num_inference_steps * strength is larger or equal to 1"
        # See: https://huggingface.co/stabilityai/sdxl-turbo
        assert num_inference_steps * strength >= 1

        image = self.pipe(
            prompt,
            image=init_image,
            num_inference_steps=num_inference_steps,
            strength=strength,
            guidance_scale=0.0,
        ).images[0]

        byte_stream = BytesIO()
        image.save(byte_stream, format="PNG")
        image_bytes = byte_stream.getvalue()

        return image_bytes

def slugify(s: str) -> str:
    return s.lower().replace(" ", "-").replace(".", "-").replace("/", "-")[:32]

@app.local_entrypoint()
def main(image_path, prompt):
    with open(image_path, "rb") as image_file:
        input_image_bytes = image_file.read()
        output_image_bytes = Model().inference.remote(input_image_bytes, prompt)

    dir = Path("/tmp/stable-diffusion-xl-turbo")
    if not dir.exists():
        dir.mkdir(exist_ok=True, parents=True)

    output_path = dir / f"output-sdxlturbo-{slugify(prompt)}.png"
    print(f"Saving it to {output_path}")
    with open(output_path, "wb") as f:
        f.write(output_image_bytes)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process an image with a given prompt.")
    parser.add_argument("--image-path", type=str, required=True, help="Path to the input image")
    parser.add_argument("--prompt", type=str, required=True, help="Describe what you want in output")

    args = parser.parse_args()

    main(image_path=args.image_path, prompt=args.prompt)
    
# ## Running the model
#
# We can run the model with different parameters using the following command,
# ```
# modal run stable_diffusion_xl_turbo.py --prompt="cute rooster" --image-path="input-images/ga-trong-1.jpg"
# modal run stable_diffusion_xl_turbo.py --prompt="girl with a yeallow glasses" --image-path="input-images/taylor-swift-singer-1.jpg"
# modal run stable_diffusion_xl_turbo.py --prompt="dog with a yeallow glasses" --image-path="input-images/dog-masked.png"
# modal run stable_diffusion_xl_turbo.py --prompt="cat with a red glasses" --image-path="input-images/a-cat-sitting.png"
# modal run stable_diffusion_xl_turbo.py --prompt="man with red glasses" --image-path="input-images/man-input.jpg"
# modal run stable_diffusion_xl_turbo.py --prompt="woman with black hat" --image-path="input-images/5-mona-lisa-leonardo-da-vinci-1892551085.jpg"
# ```
```

Test:

```s
$ modal run stable_diffusion_xl_turbo.py --prompt="woman with black hat" --image-path="input-images/monalisa-1.jpg"
✓ Initialized. View run at https://modal.com/apps/USERNAME/main/ap-HiTv6BH1C8YmqRATPd1byO
✓ Created objects.
├── 🔨 Created mount /home/USERNAME/test-stablediffusion-modal/stable_diffusion_xl_turbo.py
├── 🔨 Created function Model.download_models.
├── 🔨 Created function Model.*.
└── 🔨 Created function Model.inference.
/usr/local/lib/python3.10/site-packages/transformers/utils/generic.py:441: FutureWarning: `torch.utils._pytree._register_pytree_node` is deprecated. Please use `torch.utils._pytree.register_pytree_node` instead.
  _torch_pytree._register_pytree_node(
/usr/local/lib/python3.10/site-packages/transformers/utils/generic.py:309: FutureWarning: `torch.utils._pytree._register_pytree_node` is deprecated. Please use `torch.utils._pytree.register_pytree_node` instead.
  _torch_pytree._register_pytree_node(
/usr/local/lib/python3.10/site-packages/transformers/utils/generic.py:309: FutureWarning: `torch.utils._pytree._register_pytree_node` is deprecated. Please use `torch.utils._pytree.register_pytree_node` instead.
  _torch_pytree._register_pytree_node(
/usr/local/lib/python3.10/site-packages/diffusers/utils/outputs.py:63: FutureWarning: `torch.utils._pytree._register_pytree_node` is deprecated. Please use `torch.utils._pytree.register_pytree_node` instead.
  torch.utils._pytree._register_pytree_node(
/usr/local/lib/python3.10/site-packages/huggingface_hub/file_download.py:1150: FutureWarning: `resume_download` is deprecated and will be removed in version 1.0.0. Downloads always resume when possible. If you want to force a new download, use `force_download=True`.
  warnings.warn(
Loading pipeline components...: 100%|██████████| 7/7 [00:06<00:00,  1.07it/s]
100%|██████████| 3/3 [00:00<00:00, 10.29it/s]
Saving it to /tmp/stable-diffusion-xl-turbo/output-sdxlturbo-woman-with-black-hat.png
Stopping app - local entrypoint completed.
✓ App completed. View run at https://modal.com/apps/USERNAME/main/ap-HiTv6BH1C8YmqRATPd1byO
```

mở file `/tmp/stable-diffusion-xl-turbo/output-sdxlturbo-woman-with-black-hat.png` ra và xem.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/stable-diffusion-img2img-output.jpg)


## 2.5. Run Stable video diffusion 

Link code: https://github.com/modal-labs/modal-examples/blob/main/06_gpu_and_ml/stable_diffusion/stable_video_diffusion.py

Trước khi run cần sửa code lại: Cụ thể sửa thế nào thì tham khảo các lỗi phần Troubleshoot bên dưới

### 2.5.1. Quick serve

```s
$ modal serve stable_video_diffusion.py
✓ Initialized. View run at https://modal.com/apps/USERNAME/main/ap-X
✓ Created objects.
├── 🔨 Created mount /home/USERNAME/stable-video-diffusion-modal/stable_video_diffusion.py
├── 🔨 Created web function share => https://USERNAME--svd-dev.modal.run
├── 🔨 Created function download_model.
└── 🔨 Created function run_streamlit.
️️⚡️ Serving... hit Ctrl-C to stop!
└── Watching /home/USERNAME/stable-video-diffusion-modal.
```

Truy cập web UI nó đã tạo ra:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/stable-diffusion-video-ui-load.jpg)

Chờ 1 lúc cho nó load xong model

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/stable-diffusion-video-ui-load-setting.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/stable-diffusion-video-ui-load-vid.jpg)


### 2.5.2. Troubleshoot

Lỗi `TypeError: randn_like(): argument 'input' (position 1) must be Tensor, not NoneType`:
```s
 49%|███████████████████▏                   | 437M/890M [00:09<00:10, 45.3MiB/s]⠼ Running (0/1 containers active)... View app at https://modal.com/apps/USERNAMEa100%|███████████████████████████████████████| 890M/890M [00:19<00:00, 47.4MiB/s]
2024-08-23 09:24:09.493 Uncaught app exception
Traceback (most recent call last):
  File "/usr/local/lib/python3.10/site-packages/streamlit/runtime/scriptrunner/exec_code.py", line 85, in exec_func_with_error_handling
    result = func()
  File "/usr/local/lib/python3.10/site-packages/streamlit/runtime/scriptrunner/script_runner.py", line 576, in code_to_exec
    exec(code, module.__dict__)
  File "/sgm/scripts/demo/video_sampling.py", line 190, in <module>
    value_dict["cond_frames"] = img + cond_aug * torch.randn_like(img)
TypeError: randn_like(): argument 'input' (position 1) must be Tensor, not NoneType
```
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/stable-diffusion-video-ui-load-error-01.jpg)

Lỗi này có thể bỏ qua.

Lỗi `OutOfMemoryError: CUDA out of memory.`:

```s
OutOfMemoryError: CUDA out of memory. Tried to allocate 5.62 GiB (GPU 0; 39.56 GiB total capacity; 28.81 GiB already allocated; 2.53 GiB free; 36.51 GiB reserved in total by PyTorch) If reserved memory is >> allocated memory try setting max_split_size_mb to avoid fragmentation. See documentation for Memory Management and PYTORCH_CUDA_ALLOC_CONF
Traceback:
File "/usr/local/lib/python3.10/site-packages/streamlit/runtime/scriptrunner/exec_code.py", line 85, in exec_func_with_error_handling
    result = func()
File "/usr/local/lib/python3.10/site-packages/streamlit/runtime/scriptrunner/script_runner.py", line 576, in code_to_exec
    exec(code, module.__dict__)
File "/sgm/scripts/demo/video_sampling.py", line 254, in <module>
    out = do_sample(
File "/sgm/scripts/demo/streamlit_helpers.py", line 610, in do_sample
    samples_x = model.decode_first_stage(samples_z)
File "/usr/local/lib/python3.10/site-packages/torch/utils/_contextlib.py", line 115, in decorate_context
    return func(*args, **kwargs)
File "/sgm/sgm/models/diffusion.py", line 130, in decode_first_stage
    out = self.first_stage_model.decode(
File "/sgm/sgm/models/autoencoder.py", line 211, in decode
    x = self.decoder(z, **kwargs)
File "/usr/local/lib/python3.10/site-packages/torch/nn/modules/module.py", line 1501, in _call_impl
    return forward_call(*args, **kwargs)
File "/sgm/sgm/modules/diffusionmodules/model.py", line 733, in forward
    h = self.up[i_level].block[i_block](h, temb, **kwargs)
File "/usr/local/lib/python3.10/site-packages/torch/nn/modules/module.py", line 1501, in _call_impl
    return forward_call(*args, **kwargs)
File "/sgm/sgm/modules/autoencoding/temporal_ae.py", line 68, in forward
    x = super().forward(x, temb)
File "/sgm/sgm/modules/diffusionmodules/model.py", line 134, in forward
    h = nonlinearity(h)
File "/sgm/sgm/modules/diffusionmodules/model.py", line 49, in nonlinearity
    return x * torch.sigmoid(x)
```

Nếu sửa theo kiểu cho thêm RAM như này thì tạm thời fix dc lỗi trên:
```py
...
@app.function(image=svd_image, timeout=session_timeout, gpu=modal.gpu.A100(size="80GB"))
def run_streamlit(publish_url: bool = False):
...
```

Lỗi `TypeError: TiffWriter.write() got an unexpected keyword argument 'fps'`:
```s
 65%|█████████████████████████▍             | 579M/890M [00:13<00:07, 42.2MiB/s]⠏ Running (0/2 containers active)... View app at https://modal.com/apps/USERNAMEa100%|███████████████████████████████████████| 890M/890M [00:21<00:00, 43.1MiB/s]
2024-08-23 09:09:14.965 Uncaught app exception
Traceback (most recent call last):
  File "/usr/local/lib/python3.10/site-packages/streamlit/runtime/scriptrunner/exec_code.py", line 85, in exec_func_with_error_handling
    result = func()
  File "/usr/local/lib/python3.10/site-packages/streamlit/runtime/scriptrunner/script_runner.py", line 576, in code_to_exec
    exec(code, module.__dict__)
  File "/sgm/scripts/demo/video_sampling.py", line 190, in <module>
    value_dict["cond_frames"] = img + cond_aug * torch.randn_like(img)
TypeError: randn_like(): argument 'input' (position 1) must be Tensor, not NoneType
Global seed set to 23
Global seed set to 23
##############################  Sampling setting  ##############################
Sampler: EulerEDMSampler
Discretization: EDMDiscretization
Guider: LinearPredictionGuider
Sampling with EulerEDMSampler for 26 steps:   0%|          | 0/26 [00:00<?, ?it/s]/usr/local/lib/python3.10/site-packages/torch/utils/checkpoint.py:31: UserWarning: None of the inputs have requires_grad=True. Gradients will be None
  warnings.warn("None of the inputs have requires_grad=True. Gradients will be None")
Sampling with EulerEDMSampler for 26 steps:  73%|███████▎  | 19/26 [00:20<00:07,  1.01s/it]⠋ Running (0/2 containers active)... View app at https://modal.com/Sampling with EulerEDMSampler for 26 steps:  96%|█████████▌| 25/26 [00:26<00:01,  1.01s/it]Sampling with EulerEDMSampler for 26 steps:  96%|█████████▌| 25/26 [00:26<00:01,  1.05s/it]
2024-08-23 09:10:08.524 Uncaught app exception
Traceback (most recent call last):
  File "/usr/local/lib/python3.10/site-packages/streamlit/runtime/scriptrunner/exec_code.py", line 85, in exec_func_with_error_handling
    result = func()
  File "/usr/local/lib/python3.10/site-packages/streamlit/runtime/scriptrunner/script_runner.py", line 576, in code_to_exec
    exec(code, module.__dict__)
  File "/sgm/scripts/demo/video_sampling.py", line 280, in <module>
    save_video_as_grid_and_mp4(samples, save_path, T, fps=saving_fps)
  File "/sgm/scripts/demo/streamlit_helpers.py", line 912, in save_video_as_grid_and_mp4
    imageio.mimwrite(video_path, vid, fps=fps)
  File "/usr/local/lib/python3.10/site-packages/imageio/v2.py", line 495, in mimwrite
    return file.write(ims, is_batch=True, **kwargs)
  File "/usr/local/lib/python3.10/site-packages/imageio/plugins/tifffile_v3.py", line 224, in write
    self._fh.write(image, **kwargs)
TypeError: TiffWriter.write() got an unexpected keyword argument 'fps'
```

Nếu thêm bước `.pip_install("imageio-ffmpeg")` này sẽ fix được lỗi trên:
```py
...
.run_commands("pip install -r requirements/pt2.txt")
.apt_install("ffmpeg", "libsm6", "libxext6")  # for CV2
.pip_install("safetensors")
.pip_install("imageio-ffmpeg")
.run_function(download_model, gpu="any")
...
```

## 2.6. Run Stable Diffusion CLI

Link docs: https://modal.com/docs/examples/stable_diffusion_cli

Link Code: https://github.com/modal-labs/modal-examples/blob/main/06_gpu_and_ml/stable_diffusion/stable_diffusion_cli.py

Sửa 1 chút để output ra image có tên ý nghĩa:

```py
from __future__ import annotations

import io
import time
from pathlib import Path

import modal

app = modal.App("stable-diffusion-cli")

model_id = "runwayml/stable-diffusion-v1-5"

image = modal.Image.debian_slim(python_version="3.10").pip_install(
    "accelerate==0.29.2",
    "diffusers==0.15.1",
    "ftfy==6.2.0",
    "safetensors==0.4.2",
    "torch==2.2.2",
    "torchvision",
    "transformers~=4.25.1",
    "triton~=2.2.0",
    "xformers==0.0.25post1",
)

with image.imports():
    import diffusers
    import torch

@app.cls(image=image, gpu="A10G")
class StableDiffusion:
    @modal.build()
    @modal.enter()
    def initialize(self):
        scheduler = diffusers.DPMSolverMultistepScheduler.from_pretrained(
            model_id,
            subfolder="scheduler",
            solver_order=2,
            prediction_type="epsilon",
            thresholding=False,
            algorithm_type="dpmsolver++",
            solver_type="midpoint",
            denoise_final=True,  # important if steps are <= 10
            low_cpu_mem_usage=True,
            device_map="auto",
        )
        self.pipe = diffusers.StableDiffusionPipeline.from_pretrained(
            model_id,
            scheduler=scheduler,
            low_cpu_mem_usage=True,
            device_map="auto",
        )
        self.pipe.enable_xformers_memory_efficient_attention()

    @modal.method()
    def run_inference(
        self, prompt: str, steps: int = 20, batch_size: int = 4
    ) -> list[bytes]:
        with torch.inference_mode():
            with torch.autocast("cuda"):
                images = self.pipe(
                    [prompt] * batch_size,
                    num_inference_steps=steps,
                    guidance_scale=7.0,
                ).images

        # Convert to PNG bytes
        image_output = []
        for image in images:
            with io.BytesIO() as buf:
                image.save(buf, format="PNG")
                image_output.append(buf.getvalue())
        return image_output

def slugify(s: str) -> str:
    return s.lower().replace(" ", "-").replace(".", "-").replace("/", "-")[:32]

@app.local_entrypoint()
def entrypoint(
    prompt: str = "A 1600s oil painting of the New York City skyline",
    samples: int = 5,
    steps: int = 10,
    batch_size: int = 1,
):
    print(
        f"prompt => {prompt}, steps => {steps}, samples => {samples}, batch_size => {batch_size}"
    )

    dir = Path("/tmp/stable-diffusion")
    if not dir.exists():
        dir.mkdir(exist_ok=True, parents=True)

    sd = StableDiffusion()
    for i in range(samples):
        t0 = time.time()
        images = sd.run_inference.remote(prompt, steps, batch_size)
        total_time = time.time() - t0
        print(
            f"Sample {i} took {total_time:.3f}s ({(total_time)/len(images):.3f}s / image)."
        )
        for j, image_bytes in enumerate(images):
            output_path = dir / f"output-sd15cli-{j}{i}-{slugify(prompt)}.png"
            print(f"Saving it to {output_path}")
            with open(output_path, "wb") as f:
                f.write(image_bytes)

# And this is our entrypoint; where the CLI is invoked. Explore CLI options
# with: `modal run stable_diffusion_cli.py --help`

```

Run:

```s
l$ modal run stable_diffusion_cli.py --prompt "Vietnam street and road is flooded"
✓ Initialized. View run at https://modal.com/apps/USERNAME/main/ap-7R58dZ1fBlgdqdpgfTXGfF
✓ Created objects.
├── 🔨 Created mount /home/USERNAME/test-stablediffusion-modal/stable_diffusion_cli.py
├── 🔨 Created function StableDiffusion.initialize.
├── 🔨 Created function StableDiffusion.*.
└── 🔨 Created function StableDiffusion.run_inference.
prompt => Vietnam street and road is flooded, steps => 10, samples => 5, batch_size => 1
/usr/local/lib/python3.10/site-packages/huggingface_hub/file_download.py:1150: FutureWarning: `resume_download` is deprecated and will be removed in version 1.0.0. Downloads always resume when possible. If you want to force a new download, use `force_download=True`.
  warnings.warn(
100%|██████████| 10/10 [00:00<00:00, 10.24it/s]
Sample 0 took 18.563s (18.563s / image).
Saving it to /tmp/stable-diffusion/output-sd15cli-00-vietnam-street-and-road-is-flood.png
100%|██████████| 10/10 [00:00<00:00, 16.32it/s]
Sample 1 took 2.221s (2.221s / image).
Saving it to /tmp/stable-diffusion/output-sd15cli-01-vietnam-street-and-road-is-flood.png
100%|██████████| 10/10 [00:00<00:00, 16.32it/s]
Sample 2 took 2.126s (2.126s / image).
Saving it to /tmp/stable-diffusion/output-sd15cli-02-vietnam-street-and-road-is-flood.png
100%|██████████| 10/10 [00:00<00:00, 16.18it/s]
Sample 3 took 2.239s (2.239s / image).
Saving it to /tmp/stable-diffusion/output-sd15cli-03-vietnam-street-and-road-is-flood.png
100%|██████████| 10/10 [00:00<00:00, 16.27it/s]
Sample 4 took 2.245s (2.245s / image).
Saving it to /tmp/stable-diffusion/output-sd15cli-04-vietnam-street-and-road-is-flood.png
Stopping app - local entrypoint completed.
✓ App completed. View run at https://modal.com/apps/USERNAME/main/ap-X
```

Giờ mở các file ảnh đã generate ra xem:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/stable-diffusion-cli-output-vietnam-flooded.jpg)

## 2.7. Run Stable Diffusion WebUI A1111

https://github.com/modal-labs/modal-examples/blob/main/06_gpu_and_ml/stable_diffusion/a1111_webui.py

### 2.7.1. Quick serve

Ko cần sửa code:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/stable-diffusion-webui-1.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/stable-diffusion-webui-2.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/stable-diffusion-webui-3.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/stable-diffusion-webui-4.jpg)

Tuy nhiên bạn có thể nên nâng cấp SD từ 1.5 lên các version mới hơn. KO chắc có lỗi hay ko?

Và tab Extras có model GFPGAN nhưng mình ko biết dùng thế nào để Fixface?

## 2.8. Run Flux via command line

https://github.com/modal-labs/modal-examples/blob/main/06_gpu_and_ml/stable_diffusion/flux.py

Sửa code 1 chút:
```py
# ---
# output-directory: "/tmp/flux"
# ---
# example originally contributed by [@Arro](https://github.com/Arro)
from io import BytesIO
from pathlib import Path

import modal

VARIANT = "schnell"  # or "dev", but note [dev] requires you to accept terms and conditions on HF

diffusers_commit_sha = "1fcb811a8e6351be60304b1d4a4a749c36541651"

flux_image = (
    modal.Image.debian_slim(python_version="3.12")
    .apt_install(
        "git",
        "libglib2.0-0",
        "libsm6",
        "libxrender1",
        "libxext6",
        "ffmpeg",
        "libgl1",
    )
    .run_commands(
        f"pip install git+https://github.com/huggingface/diffusers.git@{diffusers_commit_sha} 'numpy<2'"
    )
    .pip_install(
        "invisible_watermark==0.2.0",
        "transformers==4.44.0",
        "accelerate==0.33.0",
        "safetensors==0.4.4",
        "sentencepiece==0.2.0",
    )
)

app = modal.App("example-flux")

with flux_image.imports():
    import torch
    from diffusers import FluxPipeline


@app.cls(
    gpu=modal.gpu.A100(size="40GB"),
    container_idle_timeout=100,
    image=flux_image,
)
class Model:
    @modal.build()
    @modal.enter()
    def enter(self):
        from huggingface_hub import snapshot_download
        from transformers.utils import move_cache

        snapshot_download(f"black-forest-labs/FLUX.1-{VARIANT}")

        self.pipe = FluxPipeline.from_pretrained(
            f"black-forest-labs/FLUX.1-{VARIANT}", torch_dtype=torch.bfloat16
        )
        self.pipe.to("cuda")
        move_cache()

    @modal.method()
    def inference(self, prompt):
        print("Generating image...")
        out = self.pipe(
            prompt,
            output_type="pil",
            num_inference_steps=4,  # use a larger number if you are using [dev], smaller for [schnell]
        ).images[0]
        print("Generated.")

        byte_stream = BytesIO()
        out.save(byte_stream, format="JPEG")
        return byte_stream.getvalue()

def slugify(s: str) -> str:
    return s.lower().replace(" ", "-").replace(".", "-").replace("/", "-")[:32]

@app.local_entrypoint()
def main(
    prompt: str,
):
    image_bytes = Model().inference.remote(prompt)

    dir = Path("/tmp/flux")
    if not dir.exists():
        dir.mkdir(exist_ok=True, parents=True)

    output_path = dir / f"output-sdflux-{slugify(prompt)}.jpg"
    print(f"Saving it to {output_path}")
    with open(output_path, "wb") as f:
        f.write(image_bytes)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate an image with a given prompt.")
    parser.add_argument("--prompt", type=str, required=True, help="Describe what you want in output")

    args = parser.parse_args()

    main(prompt=args.prompt)
```

Run:

```s
$ modal run flux.py --prompt "a girl is walking on Vietnam street"
✓ Initialized. View run at https://modal.com/apps/USERNAME/main/ap-S8s7WIq6PEQEIYXt34A4b3
✓ Created objects.
├── 🔨 Created mount /home/USERNAME/stable-diffusion-flux-modal/flux.py
├── 🔨 Created function Model.enter.
├── 🔨 Created function Model.*.
└── 🔨 Created function Model.inference.
Fetching 28 files: 100%|██████████| 28/28 [00:00<00:00, 27757.15it/s]
Loading pipeline components...:   0%|          | 0/7 [00:00<?, ?it/s]You set `add_prefix_space`. The tokenizer needs to be converted from the slow tokenizers
Loading checkpoint shards: 100%|██████████| 2/2 [00:01<00:00,  1.47it/s]it/s]
Loading pipeline components...: 100%|██████████| 7/7 [00:05<00:00,  1.32it/s]
0it [00:00, ?it/s]
Generating image...
100%|██████████| 4/4 [00:01<00:00,  2.19it/s]
Generated.
Saving it to /tmp/flux/output-sdflux-a-girl-is-walking-on-vietnam-str.jpg
Stopping app - local entrypoint completed.
Runner terminated.
✓ App completed. View run at https://modal.com/apps/USERNAME/main/ap-S8s7WIq6PEQEIYXt34A4b3
```

MỞ file `/tmp/flux/output-sdflux-a-girl-is-walking-on-vietnam-str.jpg` ra xem

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/stable-diffusion-flux-schnell.jpg)

## 2.9. Run Flux + ComfyUI

Link code: https://gist.github.com/kning/97c3ef37cdfea87489768872dbe2d25d

File `flux_on_comfyui_modal.py` Sửa lại chút:

```py
import json
import subprocess
import uuid
from pathlib import Path
from typing import Dict

import modal

image = (  # build up a Modal Image to run ComfyUI, step by step
    modal.Image.debian_slim(  # start from basic Linux with Python
        python_version="3.11"
    )
    .apt_install("git")  # install git to clone ComfyUI
    .pip_install("comfy-cli==1.0.33")  # install comfy-cli
    .run_commands(  # use comfy-cli to install the ComfyUI repo and its dependencies
        "comfy --skip-prompt install --nvidia"
    )
    .run_commands(  # download the flux models
        "comfy --skip-prompt model download --url https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn.safetensors --relative-path models/clip",
        "comfy --skip-prompt model download --url https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors --relative-path models/clip",
        "comfy --skip-prompt model download --url https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors --relative-path models/vae",
        "comfy --skip-prompt model download --url https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell.safetensors --relative-path models/unet",
    )
)

app = modal.App(name="example-flux-comfyui", image=image)

@app.function(
    allow_concurrent_inputs=10,
    concurrency_limit=1,
    container_idle_timeout=30,
    timeout=1800,
    gpu="A10G",
)
@modal.web_server(8000, startup_timeout=60)
def ui():
    subprocess.Popen("comfy launch -- --listen 0.0.0.0 --port 8000", shell=True)
```

Run UI:

```s
modal serve flux_on_comfyui_modal.py
```

Vào xem giao diện:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/stable-diffusion-flux-comfyui.jpg)

Do mình chưa biết dùng ComfyUI nên chưa test

## 2.10. Run ComfyUI workflow (Style change)

Xem dc Youtube này hay quá nên cố thử:
https://www.youtube.com/watch?v=Abkm4VYh9VI

1 số tài liệu tìm được để làm:
- https://civitai.com/models/330313/ttplanetsdxlcontrolnettilerealistic
- https://openart.ai/workflows/gJQkI6ttORrWCPAiTaVO
- https://huggingface.co/TTPlanet/TTPLanet_SDXL_Controlnet_Tile_Realistic/

Làm theo thì thấy nó ko phải là workflow dùng để upscale mà là để style change 1 nhân vật hoạt hình nào đó

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-stylechange-realestic.jpg)

ví dụ prompt là woman yeallow, background is shopping mall:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-stylechange-realestic2.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-stylechange-realestic3.jpg)

Dù có prompt thế nào thì nó cũng sẽ thay đổi khuôn mặt nhân vật lạ hoắc. Ko biết là chỉnh trong A1111 có khá hơn ko?

## 2.11. Run ComfyUI workflow (Upscale)

Thế là mình chuyển sang tìm cách làm theo workflow này:
https://civitai.com/models/333060/simplified-workflow-for-ultimate-sd-upscale

Kết quả sau khi ảnh được upscale, mờ thì vẫn mờ nhưng size ảnh to hẳn lên 😂

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-upscale-1.jpg)

Ảnh nhỏ minh up lên:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-upscale-1-small.jpg)

Ảnh đã xử lý:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-upscale-1-upscaled.jpg)

Log:
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-upscale-1-log.jpg)

## 2.12. Run ComfyUI workflow (Text to image dùng Controlnet)

Tìm cách làm theo workflow này:
https://civitai.com/models/426501/60sec-process-for-4k-resolution-t2i-with-rtx4090-and-tile-model

Kết quả là có thể gen từ text ra image chất lượng ảnh 4K:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-text2image-4k.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-text2image-4k-2.jpg)

Kết quả khi đưa vào ChatBot Telegram:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-controlnet-text2image-tele.jpg)


## 2.13. Run ComfyUI workflow (Upscale theo Youtube ScottDetweiler)

Làm theo Youtube này: https://www.youtube.com/watch?v=CxB47DMEyYQ

Kết quả là như này, khá ổn:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-ultimate-sd-upscale-1.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-ultimate-sd-upscale-2.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-ultimate-sd-upscale-3.jpg)


## 2.14. Run ComfyUI workflow (Faceswap)

workflow: https://civitai.com/models/143018/comfyui-face-swap-workflow

Example call API:
```s
$ python3.10 comfyclient-with-token.py --dev \
--apiToken "TOKEN" \
--apiUrl "https://USERNAME--USERNAME-comfyui-faceswap-comfyapi-api-dev.modal.run" \
--inputImageUrl "https://raw.githubusercontent.com/USERNAME/test-public-image/main/test-facesw-1.jpg" \
--sourceImageUrl "https://raw.githubusercontent.com/USERNAME/test-public-image/main/Edinson-Cavani-Gala-1-3372705103.jpg"

Sending request to https://USERNAME--USERNAME-comfyui-faceswap-comfyapi-api-dev.modal.run
Waiting for response...
Image finished generating in 136.0 seconds!
saved to '/tmp/comfyui/processed_test-facesw-1.jpg'
```

Kết quả:

text to image, chỉ cần input text như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-faceswap-telegram-1.jpg)


## 2.15. Run ComfyUI workflow (Fixface)

workflow này nhưng mình remove bớt đi: https://civitai.com/models/143018/comfyui-face-swap-workflow

Kết quả:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-fixface-telegram-1.jpg)

## 2.16. Run ComfyUI workflow (tenofas-flux)

workflow link: https://civitai.com/models/642589/tenofas-flux-workflow-txt2img-img2img-and-llm-prompt-loras-face-detailer-and-ultimate-sd-upscaler

workflow guide: https://civitai.com/articles/6848

Workflow này cung cấp 4 chức năng quan trọng: txt2img, img2img (nhưng tạo ra ảnh mới dựa trên form của ảnh cũ, chứ ko giữ nguyên ảnh gốc), face-detailer, upscale.

Tất nhiên mình cần phải sửa workflow 1 chút để dùng được

Kết quả:

Method txt2img:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-tenofasflux-1.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-tenofasflux-setting-flux-step.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-tenofasflux-text2image-tele.jpg)

Method img2img:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-tenofasflux-setting-img2img.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-tenofasflux-setting-img2img-1.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-tenofasflux-img2img-kq.jpg)

Method img2img và enable FaceDetailer:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-tenofasflux-setting-img2img-enable-facedetailer.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-tenofasflux-setting-img2img-facedetailer-grp.jpg)

Kết quả:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-tenofasflux-img2img-kq-facedetailer.jpg)

Method img2img và enable Upscaler:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-tenofasflux-setting-img2img-upscale.jpg)

Cần phải download model `4x_NMKD-Siax_200k.pth` ở `https://huggingface.co/uwg/upscaler/blob/main/ESRGAN/4x_NMKD-Siax_200k.pth`. Nếu ko sẽ bị lỗi này: 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-tenofasflux-setting-img2img-upscale-model.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-tenofasflux-setting-img2img-upscale-model-pause.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-tenofasflux-setting-img2img-upscale-model-start.jpg)

Ảnh trước upscale 1024x1024:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-tenofasflux-setting-img2img-upscale-model-start-1024.jpg)

Chờ khá lâu mới upscale lên 2048x2048:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-tenofasflux-setting-img2img-upscale-model-end.jpg)

Compare sẽ thấy có chút nét thay đổi giữa 2 ảnh ở khuôn mặt trước và sau Upscale:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-tenofasflux-setting-img2img-upscale-compare.jpg)

Chức năng img2img trên Telegram cho chất lượng ảnh khá tốt, có lẽ là do nó đọc ảnh và tự tạo prompt nên được như vậy:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-tenofasflux-image2image-tele.jpg)

## Troubleshoot

---

```s
[ERROR] An error occurred while retrieving information for the 'Florence2ModelLoader' node.
Traceback (most recent call last):
  File "/root/comfy/ComfyUI/server.py", line 468, in get_object_info
    out[x] = node_info(x)
             ^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/server.py", line 436, in node_info
    info['input'] = obj_class.INPUT_TYPES()
                    ^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Florence2/nodes.py", line 142, in INPUT_TYPES
    "model": ([item.name for item in Path(folder_paths.models_dir, "LLM").iterdir() if item.is_dir()],),
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Florence2/nodes.py", line 142, in <listcomp>
    "model": ([item.name for item in Path(folder_paths.models_dir, "LLM").iterdir() if item.is_dir()],),
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.11/pathlib.py", line 931, in iterdir
    for name in os.listdir(self):
                ^^^^^^^^^^^^^^^^
FileNotFoundError: [Errno 2] No such file or directory: '/root/comfy/ComfyUI/models/LLM'
```
Fix bằng cách tạo trước folder '/root/comfy/ComfyUI/models/LLM'

```s
!!! Exception during processing !!! Text input (prompt) is only supported for 'referring_expression_segmentation', 'caption_to_phrase_grounding', and 'docvqa'
Traceback (most recent call last):
  File "/root/comfy/ComfyUI/execution.py", line 317, in execute
    output_data, output_ui, has_subgraph = get_output_data(obj, input_data_all, execution_block_cb=execution_block_cb, pre_execute_cb=pre_execute_cb)
                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/execution.py", line 192, in get_output_data
    return_values = _map_node_over_list(obj, input_data_all, obj.FUNCTION, allow_interrupt=True, execution_block_cb=execution_block_cb, pre_execute_cb=pre_execute_cb)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/execution.py", line 169, in _map_node_over_list
    process_inputs(input_dict, i)
  File "/root/comfy/ComfyUI/execution.py", line 158, in process_inputs
    results.append(getattr(obj, func)(**inputs))
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Florence2/nodes.py", line 270, in encode
    raise ValueError("Text input (prompt) is only supported for 'referring_expression_segmentation', 'caption_to_phrase_grounding', and 'docvqa'")
ValueError: Text input (prompt) is only supported for 'referring_expression_segmentation', 'caption_to_phrase_grounding', and 'docvqa'

Prompt executed in 47.58 seconds
```
Nếu sửa linh tinh trong Node `Florence2Run` sẽ bị lỗi trên.

---

```s
!!! Exception during processing !!! invalid load key, '<'.
Traceback (most recent call last):
  File "/root/comfy/ComfyUI/execution.py", line 317, in execute
    output_data, output_ui, has_subgraph = get_output_data(obj, input_data_all, execution_block_cb=execution_block_cb, pre_execute_cb=pre_execute_cb)
                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/execution.py", line 192, in get_output_data
    return_values = _map_node_over_list(obj, input_data_all, obj.FUNCTION, allow_interrupt=True, execution_block_cb=execution_block_cb, pre_execute_cb=pre_execute_cb)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/execution.py", line 169, in _map_node_over_list
    process_inputs(input_dict, i)
  File "/root/comfy/ComfyUI/execution.py", line 158, in process_inputs
    results.append(getattr(obj, func)(**inputs))
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Impact-Pack/impact_subpack/impact/subpack_nodes.py", line 30, in doit
    model = subcore.load_yolo(model_path)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Impact-Pack/impact_subpack/impact/subcore.py", line 20, in load_yolo
    return YOLO(model_path)
           ^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.11/site-packages/ultralytics/models/yolo/model.py", line 23, in __init__
    super().__init__(model=model, task=task, verbose=verbose)
  File "/usr/local/lib/python3.11/site-packages/ultralytics/engine/model.py", line 143, in __init__
    self._load(model, task=task)
  File "/usr/local/lib/python3.11/site-packages/ultralytics/engine/model.py", line 295, in _load
    self.model, self.ckpt = attempt_load_one_weight(weights)
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.11/site-packages/ultralytics/nn/tasks.py", line 857, in attempt_load_one_weight
    ckpt, weight = torch_safe_load(weight)  # load ckpt
                   ^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.11/site-packages/ultralytics/nn/tasks.py", line 784, in torch_safe_load
    ckpt = torch.load(file, map_location="cpu")
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.11/site-packages/ultralytics/utils/patches.py", line 86, in torch_load
    return _torch_load(*args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.11/site-packages/torch/serialization.py", line 1114, in load
    return _legacy_load(
           ^^^^^^^^^^^^^
  File "/usr/local/lib/python3.11/site-packages/torch/serialization.py", line 1338, in _legacy_load
    magic_number = pickle_module.load(f, **pickle_load_args)
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
_pickle.UnpicklingError: invalid load key, '<'.
```
Nếu chọn `Enable Face detailer group` default của workflow là `bbox/face_yolov8n_v2.pt` sẽ bị lỗi như trên.
Cách fix: Node `UltralysticsDetectorProvider` chọn `bbox/face_yolov8m.pt`.

---

Lỗi `ImportError: libgthread-2.0.so.0`:
```s
****** User settings have been changed to be stored on the server instead of browser storage. ******
****** For multi-user setups add the --multi-user CLI argument to enable multiple user profiles. ******
[Prompt Server] web root: /root/comfy/ComfyUI/web
/usr/local/lib/python3.11/site-packages/kornia/feature/lightglue.py:44: FutureWarning: `torch.cuda.amp.custom_fwd(args...)` is deprecated. Please use `torch.amp.custom_fwd(args..., device_type='cuda')` instead.
  @torch.cuda.amp.custom_fwd(cast_inputs=torch.float32)
Traceback (most recent call last):
  File "/root/comfy/ComfyUI/nodes.py", line 1993, in load_custom_node
    module_spec.loader.exec_module(module)
  File "<frozen importlib._bootstrap_external>", line 940, in exec_module
  File "<frozen importlib._bootstrap>", line 241, in _call_with_frames_removed
  File "/root/comfy/ComfyUI/custom_nodes/facerestore_cf/__init__.py", line 6, in <module>
    import cv2
  File "/usr/local/lib/python3.11/site-packages/cv2/__init__.py", line 181, in <module>
    bootstrap()
  File "/usr/local/lib/python3.11/site-packages/cv2/__init__.py", line 153, in bootstrap
    native_module = importlib.import_module("cv2")
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.11/importlib/__init__.py", line 126, in import_module
    return _bootstrap._gcd_import(name[level:], package, level)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
ImportError: libgthread-2.0.so.0: cannot open shared object file: No such file or directory

Cannot import /root/comfy/ComfyUI/custom_nodes/facerestore_cf module for custom nodes: libgthread-2.0.so.0: cannot open shared object file: No such file or directory
Traceback (most recent call last):
  File "/root/comfy/ComfyUI/nodes.py", line 1993, in load_custom_node
    module_spec.loader.exec_module(module)
  File "<frozen importlib._bootstrap_external>", line 940, in exec_module
  File "<frozen importlib._bootstrap>", line 241, in _call_with_frames_removed
  File "/root/comfy/ComfyUI/custom_nodes/comfyui-reactor-node/__init__.py", line 23, in <module>
    from .nodes import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS
  File "/root/comfy/ComfyUI/custom_nodes/comfyui-reactor-node/nodes.py", line 10, in <module>
    import cv2
ImportError: libgthread-2.0.so.0: cannot open shared object file: No such file or directory

Cannot import /root/comfy/ComfyUI/custom_nodes/comfyui-reactor-node module for custom nodes: libgthread-2.0.so.0: cannot open shared object file: No such file or directory
```

Fix bằng cách add `.apt_install("libglib2.0-0")`

---

Lỗi `No module named 'Cython'` trong khi install Windows portable ComfyUI:
```s
cd ComfyUI_windows_portable/python_embeded/
./python.exe -m pip install cython
```

---

Lỗi `ModuleNotFoundError: No module named 'insightface'`:
```s
Traceback (most recent call last):
  File "D:\WSLData\ComfyUI_windows_portable_nvidia\ComfyUI_windows_portable\ComfyUI\nodes.py", line 1993, in load_custom_node
    module_spec.loader.exec_module(module)
  File "<frozen importlib._bootstrap_external>", line 940, in exec_module
  File "<frozen importlib._bootstrap>", line 241, in _call_with_frames_removed
  File "D:\WSLData\ComfyUI_windows_portable_nvidia\ComfyUI_windows_portable\ComfyUI\custom_nodes\comfyui-reactor-node\__init__.py", line 23, in <module>
    from .nodes import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS
  File "D:\WSLData\ComfyUI_windows_portable_nvidia\ComfyUI_windows_portable\ComfyUI\custom_nodes\comfyui-reactor-node\nodes.py", line 15, in <module>
    from insightface.app.common import Face
ModuleNotFoundError: No module named 'insightface'
```
Fix theo hướng dẫn đây: https://github.com/Gourieff/comfyui-reactor-node#insightfacebuild
Download file wheel cho insightface trước lấy ở đây: https://github.com/Gourieff/Assets/raw/main/Insightface/insightface-0.7.3-cp311-cp311-win_amd64.whl
Đặt file whl vào folder `ComfyUI_windows_portable/python_embeded/`
cd vào `ComfyUI_windows_portable/python_embeded/`. Run `./python.exe -m pip install insightface-0.7.3-cp311-cp311-win_amd64.whl`

---

Nếu bị lỗi này: `Error while deserializing header: HeaderTooLarge`:
```s
Error occurred when executing VAELoader:

Error while deserializing header: HeaderTooLarge

File "/root/comfy/ComfyUI/execution.py", line 317, in execute
output_data, output_ui, has_subgraph = get_output_data(obj, input_data_all, execution_block_cb=execution_block_cb, pre_execute_cb=pre_execute_cb)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
File "/root/comfy/ComfyUI/execution.py", line 192, in get_output_data
return_values = _map_node_over_list(obj, input_data_all, obj.FUNCTION, allow_interrupt=True, execution_block_cb=execution_block_cb, pre_execute_cb=pre_execute_cb)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
File "/root/comfy/ComfyUI/execution.py", line 169, in _map_node_over_list
process_inputs(input_dict, i)
File "/root/comfy/ComfyUI/execution.py", line 158, in process_inputs
results.append(getattr(obj, func)(**inputs))
^^^^^^^^^^^^^^^^^^^^^^^^^^^^
File "/root/comfy/ComfyUI/nodes.py", line 742, in load_vae
sd = comfy.utils.load_torch_file(vae_path)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
File "/root/comfy/ComfyUI/comfy/utils.py", line 34, in load_torch_file
sd = safetensors.torch.load_file(ckpt, device=device.type)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
File "/usr/local/lib/python3.11/site-packages/safetensors/torch.py", line 313, in load_file
with safe_open(filename, framework="pt", device=device) as f:
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```
Nguyên nhân là do các file safetensor hoặc checkpoints, vae bạn down về bị lỗi. Hãy chắc chắn download bằng url kiểu như này (có chữ resolve, main):

`https://huggingface.co/<NAME>/<NAME>/resolve/main/<FILE_NAME>`

Lấy link đó bằng cách sau: 
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/comfyui-modal-download-url-correct.jpg)

---

Lỗi `ImportError: libGL.so.1: cannot open shared object file: No such file or directory` dẫn đến ko thể import custom node:

```s
  File "<frozen importlib._bootstrap>", line 690, in _load_unlocked
  File "<frozen importlib._bootstrap_external>", line 940, in exec_module
  File "<frozen importlib._bootstrap>", line 241, in _call_with_frames_removed
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Easy-Use/py/easyNodes.py", line 18, in <module>
    from .layer_diffuse import LayerDiffuse, LayerMethod
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Easy-Use/py/layer_diffuse/__init__.py", line 11, in <module>
    from .model import ModelPatcher, TransparentVAEDecoder, calculate_weight_adjust_channel
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Easy-Use/py/layer_diffuse/model.py", line 3, in <module>
    import cv2
  File "/usr/local/lib/python3.11/site-packages/cv2/__init__.py", line 181, in <module>
    bootstrap()
  File "/usr/local/lib/python3.11/site-packages/cv2/__init__.py", line 153, in bootstrap
    native_module = importlib.import_module("cv2")
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.11/importlib/__init__.py", line 126, in import_module
    return _bootstrap._gcd_import(name[level:], package, level)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
ImportError: libGL.so.1: cannot open shared object file: No such file or directory

Import times for custom nodes:
   0.0 seconds: /root/comfy/ComfyUI/custom_nodes/websocket_image_save.py
   0.0 seconds: /root/comfy/ComfyUI/custom_nodes/image-resize-comfyui
   0.0 seconds: /root/comfy/ComfyUI/custom_nodes/sdxl_prompt_styler
   0.0 seconds: /root/comfy/ComfyUI/custom_nodes/ComfyUI-Eagle-PNGInfo
   0.0 seconds: /root/comfy/ComfyUI/custom_nodes/comfyui-various
   0.1 seconds: /root/comfy/ComfyUI/custom_nodes/ComfyUI-Advanced-ControlNet
   0.1 seconds: /root/comfy/ComfyUI/custom_nodes/ComfyUI-Manager
   0.1 seconds (IMPORT FAILED): /root/comfy/ComfyUI/custom_nodes/comfyui-art-venture
   0.2 seconds (IMPORT FAILED): /root/comfy/ComfyUI/custom_nodes/ComfyUI-Easy-Use
```

Fix bằng cách thêm `.apt_install("libgl1")`:
```s
image = (  # build up a Modal Image to run ComfyUI, step by step
    modal.Image.debian_slim(  # start from basic Linux with Python
        python_version="3.11"
    )
    .apt_install("git")  # install git to clone ComfyUI
    .pip_install("comfy-cli==1.0.33")  # install comfy-cli
    .run_commands(  # use comfy-cli to install the ComfyUI repo and its dependencies
        "comfy --skip-prompt install --nvidia",
    )
...
    .apt_install("libgl1")
```

---

Lỗi `ModuleNotFoundError: No module named 'cv2'`:
```s
Traceback (most recent call last):
  File "/root/comfy/ComfyUI/nodes.py", line 1993, in load_custom_node
    module_spec.loader.exec_module(module)
  File "<frozen importlib._bootstrap_external>", line 940, in exec_module
  File "<frozen importlib._bootstrap>", line 241, in _call_with_frames_removed
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Easy-Use/__init__.py", line 21, in <module>
    imported_module = importlib.import_module(".py.{}".format(module_name), __name__)
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.11/importlib/__init__.py", line 126, in import_module
    return _bootstrap._gcd_import(name[level:], package, level)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "<frozen importlib._bootstrap>", line 1206, in _gcd_import
  File "<frozen importlib._bootstrap>", line 1178, in _find_and_load
  File "<frozen importlib._bootstrap>", line 1149, in _find_and_load_unlocked
  File "<frozen importlib._bootstrap>", line 690, in _load_unlocked
  File "<frozen importlib._bootstrap_external>", line 940, in exec_module
  File "<frozen importlib._bootstrap>", line 241, in _call_with_frames_removed
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Easy-Use/py/easyNodes.py", line 18, in <module>
    from .layer_diffuse import LayerDiffuse, LayerMethod
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Easy-Use/py/layer_diffuse/__init__.py", line 11, in <module>
    from .model import ModelPatcher, TransparentVAEDecoder, calculate_weight_adjust_channel
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Easy-Use/py/layer_diffuse/model.py", line 3, in <module>
    import cv2
ModuleNotFoundError: No module named 'cv2'

Cannot import /root/comfy/ComfyUI/custom_nodes/ComfyUI-Easy-Use module for custom nodes: No module named 'cv2'
Adding /root/comfy/ComfyUI/custom_nodes to sys.path
Could not find efficiency nodes
Traceback (most recent call last):
  File "/root/comfy/ComfyUI/nodes.py", line 1993, in load_custom_node
    module_spec.loader.exec_module(module)
  File "<frozen importlib._bootstrap_external>", line 940, in exec_module
  File "<frozen importlib._bootstrap>", line 241, in _call_with_frames_removed
  File "/root/comfy/ComfyUI/custom_nodes/comfyui-art-venture/__init__.py", line 13, in <module>
    from .modules.nodes import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS
  File "/root/comfy/ComfyUI/custom_nodes/comfyui-art-venture/modules/nodes.py", line 34, in <module>
    from .postprocessing import (
  File "/root/comfy/ComfyUI/custom_nodes/comfyui-art-venture/modules/postprocessing/__init__.py", line 1, in <module>
    from .color_blend import ColorBlend
  File "/root/comfy/ComfyUI/custom_nodes/comfyui-art-venture/modules/postprocessing/color_blend.py", line 5, in <module>
    import cv2
ModuleNotFoundError: No module named 'cv2'

Cannot import /root/comfy/ComfyUI/custom_nodes/comfyui-art-venture module for custom nodes: No module named 'cv2'

Import times for custom nodes:
   0.0 seconds: /root/comfy/ComfyUI/custom_nodes/websocket_image_save.py
   0.0 seconds: /root/comfy/ComfyUI/custom_nodes/image-resize-comfyui
   0.0 seconds: /root/comfy/ComfyUI/custom_nodes/sdxl_prompt_styler
   0.0 seconds: /root/comfy/ComfyUI/custom_nodes/ComfyUI-Eagle-PNGInfo
   0.0 seconds: /root/comfy/ComfyUI/custom_nodes/comfyui-various
   0.0 seconds (IMPORT FAILED): /root/comfy/ComfyUI/custom_nodes/comfyui-art-venture
   0.1 seconds: /root/comfy/ComfyUI/custom_nodes/ComfyUI-Advanced-ControlNet
   0.1 seconds: /root/comfy/ComfyUI/custom_nodes/ComfyUI-Manager
   1.2 seconds (IMPORT FAILED): /root/comfy/ComfyUI/custom_nodes/ComfyUI-Easy-Use
```
Fix bằng cách add thêm `pip install opencv-contrib-python-headless`:
```s
.apt_install("libgl1")
    .run_commands(
        "pip install opencv-contrib-python-headless",
    )
    .run_commands(
        "comfy node install image-resize-comfyui",
    )
```

---

Lỗi `ModuleNotFoundError: No module named 'accelerate'`: 
```s
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Easy-Use/py/libs/sampler.py", line 10, in <module>
    from ..brushnet.model_patch import add_model_patch
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Easy-Use/py/brushnet/__init__.py", line 8, in <module>
    from accelerate import init_empty_weights, load_checkpoint_and_dispatch
ModuleNotFoundError: No module named 'accelerate'

Cannot import /root/comfy/ComfyUI/custom_nodes/ComfyUI-Easy-Use module for custom nodes: No module named 'accelerate'
Adding /root/comfy/ComfyUI/custom_nodes to sys.path
Could not find efficiency nodes
Could not find ControlNetPreprocessors nodes
Loaded AdvancedControlNet nodes from /root/comfy/ComfyUI/custom_nodes/ComfyUI-Advanced-ControlNet
Could not find AnimateDiff nodes
Could not find IPAdapter nodes
Could not find VideoHelperSuite nodes
Could not load ImpactPack nodes Could not find ImpactPack nodes

Import times for custom nodes:
   0.0 seconds: /root/comfy/ComfyUI/custom_nodes/websocket_image_save.py
   0.0 seconds: /root/comfy/ComfyUI/custom_nodes/image-resize-comfyui
   0.0 seconds: /root/comfy/ComfyUI/custom_nodes/ComfyUI-Eagle-PNGInfo
   0.0 seconds: /root/comfy/ComfyUI/custom_nodes/sdxl_prompt_styler
   0.0 seconds: /root/comfy/ComfyUI/custom_nodes/comfyui-various
   0.1 seconds: /root/comfy/ComfyUI/custom_nodes/ComfyUI-Manager
   0.1 seconds: /root/comfy/ComfyUI/custom_nodes/ComfyUI-Advanced-ControlNet
   0.1 seconds: /root/comfy/ComfyUI/custom_nodes/comfyui-art-venture
   3.3 seconds (IMPORT FAILED): /root/comfy/ComfyUI/custom_nodes/ComfyUI-Easy-Use
```

Fix bằng cách add thêm `pip install accelerate`:
```s
.apt_install("libgl1")
    .run_commands(
        "pip install opencv-contrib-python-headless accelerate",
    )
    .run_commands(
        "comfy node install image-resize-comfyui",
    )
```

---

Lỗi `ERROR: Could not detect model type of: /root/comfy/ComfyUI/models/checkpoints/TTPLANET_Controlnet_Tile_realistic_v2_fp16.safetensors`:
```s
!!! Exception during processing !!! ERROR: Could not detect model type of: /root/comfy/ComfyUI/models/checkpoints/TTPLANET_Controlnet_Tile_realistic_v2_fp16.safetensors
Traceback (most recent call last):
  File "/root/comfy/ComfyUI/execution.py", line 317, in execute
    output_data, output_ui, has_subgraph = get_output_data(obj, input_data_all, execution_block_cb=execution_block_cb, pre_execute_cb=pre_execute_cb)
                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/execution.py", line 192, in get_output_data
    return_values = _map_node_over_list(obj, input_data_all, obj.FUNCTION, allow_interrupt=True, execution_block_cb=execution_block_cb, pre_execute_cb=pre_execute_cb)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/execution.py", line 169, in _map_node_over_list
    process_inputs(input_dict, i)
  File "/root/comfy/ComfyUI/execution.py", line 158, in process_inputs
    results.append(getattr(obj, func)(**inputs))
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/nodes.py", line 539, in load_checkpoint
    out = comfy.sd.load_checkpoint_guess_config(ckpt_path, output_vae=True, output_clip=True, embedding_directory=folder_paths.get_folder_paths("embeddings"))
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/sd.py", line 527, in load_checkpoint_guess_config
    raise RuntimeError("ERROR: Could not detect model type of: {}".format(ckpt_path))
RuntimeError: ERROR: Could not detect model type of: /root/comfy/ComfyUI/models/checkpoints/TTPLANET_Controlnet_Tile_realistic_v2_fp16.safetensors

Prompt executed in 0.87 seconds
```
Nghĩa là mình đang cho file model vào folder `/checkpoints`, trong khi folder đó cần phải là file dạng checkpoints. Fix tạm bằng cách download file này vào đó.
```py
"comfy --skip-prompt model download --url https://huggingface.co/stabilityai/stable-diffusion-2-inpainting/resolve/main/512-inpainting-ema.safetensors --relative-path models/checkpoints"
```
Theo comment trong post [này](https://openart.ai/workflows/gJQkI6ttORrWCPAiTaVO) thì họ bảo lấy bất kỳ file checkpoint nào của SDXL cũng được

---

Lỗi `'NoneType' object has no attribute 'shape'`:
```s
!!! Exception during processing !!! 'NoneType' object has no attribute 'shape'
Traceback (most recent call last):
  File "/root/comfy/ComfyUI/execution.py", line 317, in execute
    output_data, output_ui, has_subgraph = get_output_data(obj, input_data_all, execution_block_cb=execution_block_cb, pre_execute_cb=pre_execute_cb)
                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/execution.py", line 192, in get_output_data
    return_values = _map_node_over_list(obj, input_data_all, obj.FUNCTION, allow_interrupt=True, execution_block_cb=execution_block_cb, pre_execute_cb=pre_execute_cb)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/execution.py", line 169, in _map_node_over_list
    process_inputs(input_dict, i)
  File "/root/comfy/ComfyUI/execution.py", line 158, in process_inputs
    results.append(getattr(obj, func)(**inputs))
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/nodes.py", line 1429, in sample
    return common_ksampler(model, seed, steps, cfg, sampler_name, scheduler, positive, negative, latent_image, denoise=denoise)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/nodes.py", line 1396, in common_ksampler
    samples = comfy.sample.sample(model, noise, steps, cfg, sampler_name, scheduler, positive, negative, latent_image,
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Advanced-ControlNet/adv_control/sampling.py", line 116, in acn_sample
    return orig_comfy_sample(model, *args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Advanced-ControlNet/adv_control/utils.py", line 116, in uncond_multiplier_check_cn_sample
    return orig_comfy_sample(model, *args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/sample.py", line 43, in sample
    samples = sampler.sample(noise, positive, negative, cfg=cfg, latent_image=latent_image, start_step=start_step, last_step=last_step, force_full_denoise=force_full_denoise, denoise_mask=noise_mask, sigmas=sigmas, callback=callback, disable_pbar=disable_pbar, seed=seed)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 829, in sample
    return sample(self.model, noise, positive, negative, cfg, self.device, sampler, sigmas, self.model_options, latent_image=latent_image, denoise_mask=denoise_mask, callback=callback, disable_pbar=disable_pbar, seed=seed)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 729, in sample
    return cfg_guider.sample(noise, latent_image, sampler, sigmas, denoise_mask, callback, disable_pbar, seed)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 716, in sample
    output = self.inner_sample(noise, latent_image, device, sampler, sigmas, denoise_mask, callback, disable_pbar, seed)
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 695, in inner_sample
    samples = sampler.sample(self, sigmas, extra_args, callback, noise, latent_image, denoise_mask, disable_pbar)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 600, in sample
    samples = self.sampler_function(model_k, noise, sigmas, extra_args=extra_args, callback=k_callback, disable=disable_pbar, **self.extra_options)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.11/site-packages/torch/utils/_contextlib.py", line 116, in decorate_context
    return func(*args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/k_diffusion/sampling.py", line 161, in sample_euler_ancestral
    denoised = model(x, sigmas[i] * s_in, **extra_args)
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 299, in __call__
    out = self.inner_model(x, sigma, model_options=model_options, seed=seed)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 682, in __call__
    return self.predict_noise(*args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 685, in predict_noise
    return sampling_function(self.inner_model, x, timestep, self.conds.get("negative", None), self.conds.get("positive", None), self.cfg, model_options=model_options, seed=seed)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 279, in sampling_function
    out = calc_cond_batch(model, conds, x, timestep, model_options)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 202, in calc_cond_batch
    c['control'] = control.get_control(input_x, timestep_, c, len(cond_or_uncond))
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Advanced-ControlNet/adv_control/utils.py", line 758, in get_control_inject
    return self.get_control_advanced(x_noisy, t, cond, batched_number)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Advanced-ControlNet/adv_control/control.py", line 34, in get_control_advanced
    return self.sliding_get_control(x_noisy, t, cond, batched_number)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Advanced-ControlNet/adv_control/control.py", line 90, in sliding_get_control
    control = self.control_model(x=x_noisy.to(dtype), hint=self.cond_hint, timesteps=timestep.float(), context=context.to(dtype), y=y)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.11/site-packages/torch/nn/modules/module.py", line 1553, in _wrapped_call_impl
    return self._call_impl(*args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.11/site-packages/torch/nn/modules/module.py", line 1562, in _call_impl
    return forward_call(*args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/cldm/cldm.py", line 420, in forward
    assert y.shape[0] == x.shape[0]
           ^^^^^^^
AttributeError: 'NoneType' object has no attribute 'shape'

Prompt executed in 44.91 seconds
```
Theo comment trong post [này](https://openart.ai/workflows/gJQkI6ttORrWCPAiTaVO) thì họ bảo lấy bất kỳ file checkpoint nào của SDXL cũng được.
Nhưng mình đã cho vào folder /checkpoints 1 file của SD chứ ko phải SDXL. Thế nên cần sửa lại, download checkpoint file `https://civitai.com/api/download/models/302809`:
```py
.run_commands(  # download the inpainting model
    "comfy --skip-prompt model download --url https://huggingface.co/TTPlanet/TTPLanet_SDXL_Controlnet_Tile_Realistic/resolve/main/TTPLANET_Controlnet_Tile_realistic_v2_fp16.safetensors --relative-path models/controlnet",
    "comfy --skip-prompt model download --url https://huggingface.co/TTPlanet/TTPLanet_SDXL_Controlnet_Tile_Realistic/resolve/main/TTP_tile_preprocessor_v5.py --relative-path custom_nodes/",
    "comfy --skip-prompt model download --url https://civitai.com/api/download/models/302809 --relative-path models/checkpoints" # photonium
)
```

---

Lỗi `Deadline Exceeded` khi run `modal serve`. Hãy uninstall modal `python3.10 -m pip uninstall modal` đi, rồi `python3.10 -m pip install modal` lại.

---

Lỗi `PermissionError: [Errno 13] error while attempting to bind on address ('127.0.0.1', 8188)` khi run ComfyUI trên máy Windows local:
```
[2024-08-25 11:41]   File "asyncio\base_events.py", line 1536, in create_server
[2024-08-25 11:41] PermissionError: [Errno 13] error while attempting to bind on address ('127.0.0.1', 8188): an attempt was made to access a socket in a way forbidden by its access permissions
```
Hãy bật PWshell as admin rồi restart winnat như sau:
```sh
net stop winnat
net start winnat
```

---

Lỗi `ModuleNotFoundError` này thì fix đơn giản, cứ pip install các module thiếu thôi:
```s
WARNING: Traceback (most recent call last):
  File "/root/comfy/ComfyUI/nodes.py", line 1993, in load_custom_node
    module_spec.loader.exec_module(module)
  File "<frozen importlib._bootstrap_external>", line 940, in exec_module
  File "<frozen importlib._bootstrap>", line 241, in _call_with_frames_removed
  File "/root/comfy/ComfyUI/custom_nodes/wlsh_nodes/__init__.py", line 1, in <module>
    from .wlsh_nodes import NODE_CLASS_MAPPINGS
  File "/root/comfy/ComfyUI/custom_nodes/wlsh_nodes/wlsh_nodes.py", line 24, in <module>
    import piexif
ModuleNotFoundError: No module named 'piexif'

WARNING: Cannot import /root/comfy/ComfyUI/custom_nodes/wlsh_nodes module for custom nodes: No module named 'piexif'
Making the "web\extensions\Gemini_Zho" folder
Update to javascripts files detected
Copying GeminiAPINode.js to extensions folder
WARNING: Traceback (most recent call last):
  File "/root/comfy/ComfyUI/nodes.py", line 1993, in load_custom_node
    module_spec.loader.exec_module(module)
  File "<frozen importlib._bootstrap_external>", line 940, in exec_module
  File "<frozen importlib._bootstrap>", line 241, in _call_with_frames_removed
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Gemini/__init__.py", line 49, in <module>
    from .GeminiAPINode import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Gemini/GeminiAPINode.py", line 6, in <module>
    import google.generativeai as genai
ModuleNotFoundError: No module named 'google.generativeai'

WARNING: Cannot import /root/comfy/ComfyUI/custom_nodes/ComfyUI-Gemini module for custom nodes: No module named 'google.generativeai'

WARNING: Traceback (most recent call last):
  File "/root/comfy/ComfyUI/nodes.py", line 1993, in load_custom_node
    module_spec.loader.exec_module(module)
  File "<frozen importlib._bootstrap_external>", line 940, in exec_module
  File "<frozen importlib._bootstrap>", line 241, in _call_with_frames_removed
  File "/root/comfy/ComfyUI/custom_nodes/comfy-image-saver/__init__.py", line 1, in <module>
    from .nodes import NODE_CLASS_MAPPINGS
  File "/root/comfy/ComfyUI/custom_nodes/comfy-image-saver/nodes.py", line 5, in <module>
    import piexif
ModuleNotFoundError: No module named 'piexif'

WARNING: Cannot import /root/comfy/ComfyUI/custom_nodes/comfy-image-saver module for custom nodes: No module named 'piexif'
WARNING: Traceback (most recent call last):
  File "/root/comfy/ComfyUI/nodes.py", line 1993, in load_custom_node
    module_spec.loader.exec_module(module)
  File "<frozen importlib._bootstrap_external>", line 940, in exec_module
  File "<frozen importlib._bootstrap>", line 241, in _call_with_frames_removed
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-YOLO/__init__.py", line 1, in <module>
    from .nodes import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-YOLO/nodes.py", line 5, in <module>
    from ultralytics import YOLO, SAM
ModuleNotFoundError: No module named 'ultralytics'

WARNING: Cannot import /root/comfy/ComfyUI/custom_nodes/ComfyUI-YOLO module for custom nodes: No module named 'ultralytics'
WARNING: Traceback (most recent call last):
  File "/root/comfy/ComfyUI/nodes.py", line 1993, in load_custom_node
    module_spec.loader.exec_module(module)
  File "<frozen importlib._bootstrap_external>", line 940, in exec_module
  File "<frozen importlib._bootstrap>", line 241, in _call_with_frames_removed
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Manager/__init__.py", line 6, in <module>
    from .glob import manager_server
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Manager/glob/manager_server.py", line 16, in <module>
    import manager_core as core
ModuleNotFoundError: No module named 'manager_core'

WARNING: Cannot import /root/comfy/ComfyUI/custom_nodes/ComfyUI-Manager module for custom nodes: No module named 'manager_core'
```

---

Lỗi `FileNotFoundError: [Errno 2] No such file or directory: '/root/comfy/ComfyUI/custom_nodes/ComfyUI_UltimateSDUpscale/repositories/ultimate_sd_upscale/scripts/ultimate-upscale.py'`:
```s
WARNING: Traceback (most recent call last):
  File "/root/comfy/ComfyUI/nodes.py", line 1993, in load_custom_node
    module_spec.loader.exec_module(module)
  File "<frozen importlib._bootstrap_external>", line 940, in exec_module
  File "<frozen importlib._bootstrap>", line 241, in _call_with_frames_removed
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI_UltimateSDUpscale/__init__.py", line 32, in <module>
    from .nodes import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI_UltimateSDUpscale/nodes.py", line 6, in <module>
    from usdu_patch import usdu
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI_UltimateSDUpscale/usdu_patch.py", line 2, in <module>
    from repositories import ultimate_upscale as usdu
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI_UltimateSDUpscale/repositories/__init__.py", line 14, in <module>
    spec.loader.exec_module(ultimate_upscale)
  File "<frozen importlib._bootstrap_external>", line 936, in exec_module
  File "<frozen importlib._bootstrap_external>", line 1073, in get_code
  File "<frozen importlib._bootstrap_external>", line 1130, in get_data
FileNotFoundError: [Errno 2] No such file or directory: '/root/comfy/ComfyUI/custom_nodes/ComfyUI_UltimateSDUpscale/repositories/ultimate_sd_upscale/scripts/ultimate-upscale.py'

WARNING: Cannot import /root/comfy/ComfyUI/custom_nodes/ComfyUI_UltimateSDUpscale module for custom nodes: [Errno 2] No such file or directory: '/root/comfy/ComfyUI/custom_nodes/ComfyUI_UltimateSDUpscale/repositories/ultimate_sd_upscale/scripts/ultimate-upscale.py'
```
Fix bằng cách lúc git clone thì thêm --recursive như hướng dẫn ở [đây](https://github.com/ssitu/ComfyUI_UltimateSDUpscale/issues/15#issuecomment-1679261802)

---

Lỗi `TypeError: object of type 'NoneType' has no len()` khi chạy đến Node `StableSRColorFix`:
```s
!!! Exception during processing !!! object of type 'NoneType' has no len()
Traceback (most recent call last):
  File "/root/comfy/ComfyUI/execution.py", line 317, in execute
    output_data, output_ui, has_subgraph = get_output_data(obj, input_data_all, execution_block_cb=execution_block_cb, pre_execute_cb=pre_execute_cb)
                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/execution.py", line 222, in get_output_data
    output = merge_result_data(results, obj)
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/execution.py", line 175, in merge_result_data
    output_is_list = [False] * len(results[0])
                               ^^^^^^^^^^^^^^^
TypeError: object of type 'NoneType' has no len()

Prompt executed in 134.87 seconds
```
Fix bằng cách trên ComfyUI sửa cái StableSRColorFix node dùng `colorfix = AdaIN`. Theo hướng dẫn ở [đây](https://github.com/gameltb/Comfyui-StableSR/issues/1#issuecomment-1924043926)


---

Lỗi `AttributeError: 'NoneType' object has no attribute 'shape'` ở KSampler:
```s
!!! Exception during processing !!! 'NoneType' object has no attribute 'shape'
Traceback (most recent call last):
  File "/root/comfy/ComfyUI/execution.py", line 317, in execute
    output_data, output_ui, has_subgraph = get_output_data(obj, input_data_all, execution_block_cb=execution_block_cb, pre_execute_cb=pre_execute_cb)
                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/execution.py", line 192, in get_output_data
    return_values = _map_node_over_list(obj, input_data_all, obj.FUNCTION, allow_interrupt=True, execution_block_cb=execution_block_cb, pre_execute_cb=pre_execute_cb)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/execution.py", line 169, in _map_node_over_list
    process_inputs(input_dict, i)
  File "/root/comfy/ComfyUI/execution.py", line 158, in process_inputs
    results.append(getattr(obj, func)(**inputs))
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/nodes.py", line 1429, in sample
    return common_ksampler(model, seed, steps, cfg, sampler_name, scheduler, positive, negative, latent_image, denoise=denoise)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/nodes.py", line 1396, in common_ksampler
    samples = comfy.sample.sample(model, noise, steps, cfg, sampler_name, scheduler, positive, negative, latent_image,
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/custom_nodes/Comfyui-StableSR/nodes.py", line 75, in hook_sample
    return original_sample(*args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Advanced-ControlNet/adv_control/sampling.py", line 116, in acn_sample
    return orig_comfy_sample(model, *args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Advanced-ControlNet/adv_control/utils.py", line 116, in uncond_multiplier_check_cn_sample
    return orig_comfy_sample(model, *args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/sample.py", line 43, in sample
    samples = sampler.sample(noise, positive, negative, cfg=cfg, latent_image=latent_image, start_step=start_step, last_step=last_step, force_full_denoise=force_full_denoise, denoise_mask=noise_mask, sigmas=sigmas, callback=callback, disable_pbar=disable_pbar, seed=seed)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 829, in sample
    return sample(self.model, noise, positive, negative, cfg, self.device, sampler, sigmas, self.model_options, latent_image=latent_image, denoise_mask=denoise_mask, callback=callback, disable_pbar=disable_pbar, seed=seed)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 729, in sample
    return cfg_guider.sample(noise, latent_image, sampler, sigmas, denoise_mask, callback, disable_pbar, seed)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 716, in sample
    output = self.inner_sample(noise, latent_image, device, sampler, sigmas, denoise_mask, callback, disable_pbar, seed)
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 695, in inner_sample
    samples = sampler.sample(self, sigmas, extra_args, callback, noise, latent_image, denoise_mask, disable_pbar)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 600, in sample
    samples = self.sampler_function(model_k, noise, sigmas, extra_args=extra_args, callback=k_callback, disable=disable_pbar, **self.extra_options)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.11/site-packages/torch/utils/_contextlib.py", line 116, in decorate_context
    return func(*args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/k_diffusion/sampling.py", line 785, in sample_dpmpp_2m_sde_gpu
    return sample_dpmpp_2m_sde(model, x, sigmas, extra_args=extra_args, callback=callback, disable=disable, eta=eta, s_noise=s_noise, noise_sampler=noise_sampler, solver_type=solver_type)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.11/site-packages/torch/utils/_contextlib.py", line 116, in decorate_context
    return func(*args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/k_diffusion/sampling.py", line 688, in sample_dpmpp_2m_sde
    denoised = model(x, sigmas[i] * s_in, **extra_args)
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 299, in __call__
    out = self.inner_model(x, sigma, model_options=model_options, seed=seed)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 682, in __call__
    return self.predict_noise(*args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 685, in predict_noise
    return sampling_function(self.inner_model, x, timestep, self.conds.get("negative", None), self.conds.get("positive", None), self.cfg, model_options=model_options, seed=seed)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 279, in sampling_function
    out = calc_cond_batch(model, conds, x, timestep, model_options)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/samplers.py", line 202, in calc_cond_batch
    c['control'] = control.get_control(input_x, timestep_, c, len(cond_or_uncond))
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Advanced-ControlNet/adv_control/utils.py", line 758, in get_control_inject
    return self.get_control_advanced(x_noisy, t, cond, batched_number)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Advanced-ControlNet/adv_control/control.py", line 34, in get_control_advanced
    return self.sliding_get_control(x_noisy, t, cond, batched_number)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/custom_nodes/ComfyUI-Advanced-ControlNet/adv_control/control.py", line 90, in sliding_get_control
    control = self.control_model(x=x_noisy.to(dtype), hint=self.cond_hint, timesteps=timestep.float(), context=context.to(dtype), y=y)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.11/site-packages/torch/nn/modules/module.py", line 1553, in _wrapped_call_impl
    return self._call_impl(*args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.11/site-packages/torch/nn/modules/module.py", line 1562, in _call_impl
    return forward_call(*args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/root/comfy/ComfyUI/comfy/cldm/cldm.py", line 420, in forward
    assert y.shape[0] == x.shape[0]
           ^^^^^^^
AttributeError: 'NoneType' object has no attribute 'shape'
```
Vẫn giống cách fix của lỗi từng gặp bên trên: Thay file checkpoint của SDXL:

```py
"comfy --skip-prompt model download --url https://civitai.com/api/download/models/128078 --relative-path models/checkpoints", # SD XL
```


# 3. Huggingface Transformer / Huggingface Space

# 4. Google Colab

# 5. Runpod.io

# 6. Monster.ai

# 7. Openrouter.ai

# 8. BentoCloud (bentoml.com)

# 9. Skypilot

# REFERENCES

1 số web đang cung cấp các StableDiffusion API như này:

https://docs.modelslab.com/image-editing/overview

https://docs.modelslab.com/image-generation/community-models/overview

https://documenter.getpostman.com/view/18679074/2s83zdwReZ#9d45c9e2-e441-4edd-b639-861fcc537dc7

Tuy nhiên trang này ko cho kiểu Pay as you go, có vẻ bắt buộc subscribe plan: https://modelslab.com/pricing

Trang này có vẻ cho phép trả tiền theo kiểu Pay as you go:
https://docs.getimg.ai/reference/postenhancementsfacefix

fix face model: https://github.com/TencentARC/GFPGAN

text to video SD: https://blog.aiplayz.com/text-to-video/

1 số tool hay ho: 

https://github.com/brycedrennan/imaginAIry -> gen video

https://github.com/Nerogar/OneTrainer -> OneTrainer is a one-stop solution for all your stable diffusion training needs

https://github.com/huggingface/diffusers/tree/main/examples/ -> Các example projects về SD

https://github.com/comfyanonymous/ComfyUI_examples/tree/master Repo examples của ComfyUI

Nếu muốn download model yêu cầu login từ civitai thì dùng token: 
https://youtu.be/X5WVZ0NMaTg?t=494