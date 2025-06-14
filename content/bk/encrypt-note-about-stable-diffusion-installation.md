---
title: "Not a tutorial: Stable Diffusion installation Notes"
date: 2023-08-25T13:09:35+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Notes]
#tags: [Stable-Diffusion]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "This is just my notes when playaround with Stable Diffusion, not a tutorial"
---

This is just my notes when playaround with Stable Diffusion, not a tutorial

# 1. Nếu máy bạn có card NVIDIA 

I follow this tutorial: https://www.howtogeek.com/830179/how-to-run-stable-diffusion-on-your-pc-to-generate-ai-images/

Mình sẽ tóm tắt lại các step.

Install Miniconda từ https://docs.conda.io/en/latest/miniconda.html. Mình Chọn bản Miniconda3 Windows 64 bit

Run file exe để cài đặt.

Download the Stable Diffusion GitHub Repository and the Latest Checkpoint: https://huggingface.co/CompVis/stable-diffusion#model-access

Ấn vào `stable-diffusion-v-1-4-original` (https://huggingface.co/CompVis/stable-diffusion-v-1-4-original). Sẽ ra chỗ download file `sd-v1-4.ckpt` (https://huggingface.co/CompVis/stable-diffusion-v-1-4-original/resolve/main/sd-v1-4.ckpt)

Git clone hoặc download file zip repo này về: https://github.com/CompVis/stable-diffusion -> giải nén (Mình chọn `D:\downloads\stable-diffusion-lab\stable-diffusion-main`)

Window -> miniconda3 ra màn hình terminal màu đen:

- Direct vào folder git repo `cd D:\downloads\stable-diffusion-lab\stable-diffusion-main`

- Run command: `conda env create -f environment.yaml`

  Chờ 1 lúc lâu (15-20p) đến khi:

  ```
  (base) PS D:\downloads\stable-diffusion-lab\stable-diffusion-main> conda env create -f environment.yaml
  Collecting package metadata (repodata.json): done
  Solving environment: done


  ==> WARNING: A newer version of conda exists. <==
    current version: 23.5.2
    latest version: 23.7.3

  Please update conda by running

      $ conda update -n base -c defaults conda

  Or to minimize the number of packages updated during conda update use

      conda install conda=23.7.3



  Downloading and Extracting Packages

  Preparing transaction: done
  Verifying transaction: done
  Executing transaction: done
  ...
  #
  # To activate this environment, use
  #
  #     $ conda activate ldm
  #
  # To deactivate an active environment, use
  #
  #     $ conda deactivate
  ```

- Run command: `conda activate ldm`

  ```
  (base) PS D:\downloads\stable-diffusion-lab\stable-diffusion-main> conda activate ldm
  (ldm) PS D:\downloads\stable-diffusion-lab\stable-diffusion-main>
  ```

- Run command: `mkdir models\ldm\stable-diffusion-v1`

  ```
  (ldm) PS D:\downloads\stable-diffusion-lab\stable-diffusion-main> mkdir models\ldm\stable-diffusion-v1


      Directory: D:\downloads\stable-diffusion-lab\stable-diffusion-main\models\ldm


  Mode                 LastWriteTime         Length Name
  ----                 -------------         ------ ----
  d-----         8/25/2023   9:57 PM                stable-diffusion-v1
  ```

- Move file `sd-v1-4.ckpt` vào folder `D:\downloads\stable-diffusion-lab\stable-diffusion-main\models\ldm\stable-diffusion-v1`

- Rename file đó thành `model.ckpt`

- Run command: `pip install git+https://github.com/huggingface/transformers.git`

  ```
  (ldm) PS D:\downloads\stable-diffusion-lab\stable-diffusion-main> pip install git+https://github.com/huggingface/transformers.git
  Collecting git+https://github.com/huggingface/transformers.git
    Cloning https://github.com/huggingface/transformers.git to c:\users\admin\appdata\local\temp\pip-req-build-kbes8daa
    Installing build dependencies ... done
    Getting requirements to build wheel ... done
      Preparing wheel metadata ... done
  Requirement already satisfied: numpy>=1.17 in c:\users\admin\.conda\envs\ldm\lib\site-packages (from transformers==4.33.0.dev0) (1.24.4)

  ...
  Successfully built transformers
  Installing collected packages: transformers
    Attempting uninstall: transformers
      Found existing installation: transformers 4.19.2
      Uninstalling transformers-4.19.2:
        Successfully uninstalled transformers-4.19.2
  Successfully installed transformers-4.33.0.dev0
  ```

- Run command: `python scripts/txt2img.py --prompt "a close-up portrait of a cat by pablo picasso, vivid, abstract art, colorful, vibrant" --plms --n_iter 5 --n_samples 1`

  Đến đây thì mình gặp lỗi này:  

  ```
  Downloading pytorch_model.bin: 100%|██████████████████████████████████████████████| 1.71G/1.71G [02:32<00:00, 11.2MB/s]
  Traceback (most recent call last):
    File "scripts/txt2img.py", line 352, in <module>
      main()
    File "scripts/txt2img.py", line 246, in main
      model = load_model_from_config(config, f"{opt.ckpt}")
    File "scripts/txt2img.py", line 64, in load_model_from_config
      model.cuda()
    File "C:\Users\Admin\.conda\envs\ldm\lib\site-packages\pytorch_lightning\core\mixins\device_dtype_mixin.py", line 127, in cuda
      return super().cuda(device=device)
    File "C:\Users\Admin\.conda\envs\ldm\lib\site-packages\torch\nn\modules\module.py", line 688, in cuda
      return self._apply(lambda t: t.cuda(device))
    File "C:\Users\Admin\.conda\envs\ldm\lib\site-packages\torch\nn\modules\module.py", line 578, in _apply
      module._apply(fn)
    File "C:\Users\Admin\.conda\envs\ldm\lib\site-packages\torch\nn\modules\module.py", line 578, in _apply
      module._apply(fn)
    File "C:\Users\Admin\.conda\envs\ldm\lib\site-packages\torch\nn\modules\module.py", line 578, in _apply
      module._apply(fn)
    [Previous line repeated 1 more time]
    File "C:\Users\Admin\.conda\envs\ldm\lib\site-packages\torch\nn\modules\module.py", line 601, in _apply
      param_applied = fn(param)
    File "C:\Users\Admin\.conda\envs\ldm\lib\site-packages\torch\nn\modules\module.py", line 688, in <lambda>
      return self._apply(lambda t: t.cuda(device))
    File "C:\Users\Admin\.conda\envs\ldm\lib\site-packages\torch\cuda\__init__.py", line 216, in _lazy_init
      torch._C._cuda_init()
  RuntimeError: Found no NVIDIA driver on your system. Please check that you have an NVIDIA GPU and installed a driver from http://www.nvidia.com/Download/index.aspx
  ```

  Mình chịu vì mình ko có card NVIDIA trên máy này. Đành tạm dừng ý tưởng run Stable Diffusion trên con NUC11i5 thôi 😥

# 2. Nếu máy bạn không có card NIVIDIA

Nếu ko có card NVIDIA thì bạn có thể nghĩ đến chuyện dùng project này: https://github.com/bes-dev/stable_diffusion.openvino#readme

mình làm trên python3.9 thấy khá OK, hơi chậm thôi

Git clone repo trên về rồi run các command sau trên GitBash hoặc WSL: 

```sh
python3.9 -m pip install --upgrade pip
python3.9 -m pippip install openvino-dev[onnx,pytorch]==2022.3.0
python3.9 -m pippip install -r requirements.txt

python3.9 demo.py --prompt "Street-art painting of Emilia Clarke in style of Banksy, photorealism"
# vào folder stable_diffusion.openvino/ sẽ thấy output.png hiện ra
```

Ví dụ mình run với prompt về Messi theo phong cách picasso, Log:

```
$ python3.9 demo.py --prompt "a close-up portrait of Lionel Messi by pablo picasso, vivid, abstract art, colorful" --output messi.png
Downloading: 100%|██████████████████████████████████████████████████████████████████████████████████████████| 905/905 [00:00<00:00, 694kB/s]
Downloading: 100%|████████████████████████████████████████████████████████████████████████████████████████| 939k/939k [00:01<00:00, 950kB/s]
Downloading: 100%|████████████████████████████████████████████████████████████████████████████████████████| 512k/512k [00:00<00:00, 534kB/s]
Downloading: 100%|██████████████████████████████████████████████████████████████████████████████████████████| 389/389 [00:00<00:00, 288kB/s]
Downloading: 100%|█████████████████████████████████████████████████████████████████████████████████████| 2.12M/2.12M [00:01<00:00, 1.59MB/s]
Downloading: 100%|████████████████████████████████████████████████████████████████████████████████████████| 569k/569k [00:00<00:00, 585kB/s]
Downloading: 100%|███████████████████████████████████████████████████████████████████████████████████████| 246M/246M [00:25<00:00, 9.74MB/s]
Downloading: 100%|█████████████████████████████████████████████████████████████████████████████████████| 2.30M/2.30M [00:01<00:00, 1.59MB/s]
Downloading: 100%|█████████████████████████████████████████████████████████████████████████████████████| 1.72G/1.72G [02:57<00:00, 9.70MB/s]
Downloading: 100%|████████████████████████████████████████████████████████████████████████████████████████| 383k/383k [00:00<00:00, 474kB/s]
Downloading: 100%|█████████████████████████████████████████████████████████████████████████████████████| 99.0M/99.0M [00:09<00:00, 9.93MB/s]
Downloading: 100%|████████████████████████████████████████████████████████████████████████████████████████| 324k/324k [00:00<00:00, 412kB/s]
Downloading: 100%|█████████████████████████████████████████████████████████████████████████████████████| 68.3M/68.3M [00:08<00:00, 8.00MB/s]
32it [03:36,  6.77s/it]
```

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/stable-diffusion-openvino-messi.jpg)

Giờ ý tưởng tiếp của mình là đem project này lên VM Cloud, rồi làm 1 app prompt từ Telegram -> generate image -> send images về đúng Telegram đó: 
- Ý tưởng này sẽ ko thể làm được do code này chỉ hoạt động với chip intel mà thôi, còn VM của mình thì dùng chip arm. ([nguồn](https://github.com/bes-dev/stable_diffusion.openvino/issues/147))

# 3. Bonus

Việc sử dụng phương án `stable_diffusion.openvino` giúp mình optimized được dung lượng RAM đáng kể. 

Bình thường thì RAM mình luôn ở trạng thái 50% (Use 7GB/ total 16GB)

Do để render ảnh thì `stable_diffusion.openvino` sẽ tiêu tốn 1 lượng RAM khá lớn, bạn sẽ thấy trong quá trình render, RAM tăng lên 100% (Use 15~16GB/ total 16GB), render xong thì giảm.

Kết quả là sau khi render xong, RAM của bạn chỉ còn Use 4GB/total 16GB. Như vậy là openvino đã giúp máy clear hết RAM thừa.

Thực ra mình cũng đọc được rằng bản thân Windows đã optimized tốt cho RAM rồi, không cần quan tâm quá nhiều đến việc clear RAM vì Windows sẽ tự động làm cho chúng ta. 
Nhưng với những người thích nhìn % RAM giảm xuống thì có thể thử dùng phương án này.  

# 4. Troubleshoot 

- Khi run bằng GitBash cần run với quyền Admin

- Nếu bị lỗi này, thì nguyên nhân là chỗ ouput cần có tên file đầy đủ `--output messi.png`: 

```
Admin@DESKTOP-GKJJ17P MINGW64 /d/downloads/stable-diffusion-lab/stable_diffusion.openvino (master)
$ python3.9 demo.py --prompt "a close-up portrait of Lionel Messi by pablo picasso, vivid, abstract art, colorful" --output messi
Downloading: 100%|##########| 246M/246M [00:21<00:00, 11.4MB/s]
Downloading: 100%|##########| 2.30M/2.30M [00:01<00:00, 1.57MB/s]
Downloading: 100%|##########| 1.72G/1.72G [02:28<00:00, 11.6MB/s]
Downloading: 100%|##########| 383k/383k [00:00<00:00, 523kB/s]
Downloading: 100%|##########| 99.0M/99.0M [00:08<00:00, 11.2MB/s]
Downloading: 100%|##########| 324k/324k [00:00<00:00, 415kB/s]
Downloading: 100%|##########| 68.3M/68.3M [00:05<00:00, 11.6MB/s]
32it [03:13,  6.06s/it]
Traceback (most recent call last):
  File "D:\downloads\stable-diffusion-lab\stable_diffusion.openvino\demo.py", line 83, in <module>
    main(args)
  File "D:\downloads\stable-diffusion-lab\stable_diffusion.openvino\demo.py", line 50, in main
    cv2.imwrite(args.output, image)
cv2.error: OpenCV(4.5.5) D:\a\opencv-python\opencv-python\opencv\modules\imgcodecs\src\loadsave.cpp:730: error: (-2:Unspecified error) could not find a writer for the specified extension in function 'cv::imwrite_'
```


# CREDIT

https://www.howtogeek.com/830179/how-to-run-stable-diffusion-on-your-pc-to-generate-ai-images/

https://github.com/huggingface/diffusers/issues/1377#issuecomment-1325580890

https://github.com/bes-dev/stable_diffusion.openvino#readme