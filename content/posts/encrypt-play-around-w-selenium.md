---
title: "Play around with Python-Selenium"
date: 2021-10-06T13:47:39+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Notes]
tags: [Python,Selenium]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "This is just my notes when playaround with python-selenium, not a tutorial"
---

This is just my notes when playaround with python-selenium, not a tutorial

# 1. Workspace 1: Windows, GitBash terminal, PowerShell, Docker for Windows, Firefox

**Prepare**:  

- Install Python, selenium follow this docs:  
    https://selenium-python.readthedocs.io/installation.html  
    Open GitBash:  
        ```sh
        pip install selenium
        ```  
    Download geckodriver, extract to exe file, update PATH environment

- Run Selenium webdriver follow this docs:  
    https://github.com/SeleniumHQ/docker-selenium#quick-start   
    Run on Powershell:  
    ```sh
    docker run -d -p 4444:4444 -p 7900:7900 --shm-size="2g" selenium/standalone-firefox:4.0.0-rc-2-20210930
    ```

- After all, you can run your python script in GitBash

- Open the Selenium Webdriver to see what happen when your code execute

**Script**:  

This is a sample script for particular website, you should change the code arcording to your site:

```sh
# import unittest
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
import logging, os
from time import sleep

"""
Get particular monthly fee from https://xxxx.com

You should prepair some Evironment Variables as below sample:
USER_NAME: user name to login
PASSWORD: password to login

This script has no required argument 
"""

# Set level to DEBUG for debugging, INFO for general usage.
logger = logging.getLogger()
logger.setLevel(logging.INFO)
MONTH_TO_SEARCH = "10/2021"

# get env variables
USER = os.environ.get('USER_NAME')
PASSWORD = os.environ.get('PASSWORD')

# setup
driver = webdriver.Firefox()
driver.implicitly_wait(2)
driver.get("https://xxxx.com/login")

# login
user = driver.find_element_by_name("Username")
user.clear()
user.send_keys(USER)
passw = driver.find_element_by_name("Password")
passw.clear()
passw.send_keys(PASSWORD)
driver.find_element_by_xpath('//button[@type="submit"]').click()
sleep(5)

# direct to other, then get data
driver.get("https://xxxx.com/ThanhToanTrucTuyen/LichSuThanhToan")

# input start month
start_month = driver.find_element_by_id("thangBatDau")
start_month.send_keys(Keys.DELETE, MONTH_TO_SEARCH)

# input end month
end_month = driver.find_element_by_id("thangKetThuc")
end_month.send_keys(Keys.DELETE, MONTH_TO_SEARCH)

# click button to get data
driver.find_element_by_id("btnSearch").click()
sleep(5) # wait for getting data
month_id_raw = driver.find_elements_by_xpath("/html/body/div[1]/main/div[3]/div/div/div/div[4]/div/table/tbody/tr/td[1]")
print("number of records: " + str(len(month_id_raw)))

if len(month_id_raw) == 0: 
    print("Have no data of %s" % MONTH_TO_SEARCH)

if len(month_id_raw) == 1: 
    print("Month: %s" % month_id_raw[0].text)
    total_fee_raw = driver.find_elements_by_xpath("/html/body/div[1]/main/div[3]/div/div/div/div[4]/div/table/tbody/tr/td[8]")
    print("Total of %s is: %s VND" % (MONTH_TO_SEARCH, total_fee_raw[0].text))

# close
sleep(5)
driver.close()

```


# 2. Workspace 2: Raspberry Pi 4B 8G, Raspion OS Lite without desktop

**Prepare**: 

```sh
python --version # 3.9
pip3 install selenium==4.11.2
sudo apt-get install chromium-chromedriver -y
docker run --name selenium -d -p 4444:4444 --shm-size="2g" kynetiv/selenium-standalone-chromium-pi:latest 
```

**Script**:  
```python
# import unittest
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
import logging, os
from time import sleep
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service

"""
Get particular monthly fee from https://xxxx.com

You should prepair some Evironment Variables as below sample:
USER_NAME: user name to login
PASSWORD: password to login

This script has no required argument.
Test successfully on Raspian OS (Raspberry Pi 4B).  
To prepare environment on Raspian OS, follow this topic: https://hoangmnsd.github.io/posts/encrypt-play-around-w-selenium/
"""

# Set level to DEBUG for debugging, INFO for general usage.
logger = logging.getLogger()
logger.setLevel(logging.INFO)
MONTH_TO_SEARCH = "05/2022"

# get env variables
USER = os.environ.get('USER_NAME')
PASSWORD = os.environ.get('PASSWORD')

# setup
chrome_options = Options()
chrome_options.add_argument("--headless")
chrome_options.add_argument('ignore-certificate-errors') # if you are want to access a not valid cert website (insecure)
service = Service('/usr/lib/chromium-browser/chromedriver')
driver = webdriver.Chrome(service=service, options=chrome_options)
driver.get("https://xxxx.com/login")
# html = driver.page_source        # DEBUG
# print(html)                      # DEBUG
```
