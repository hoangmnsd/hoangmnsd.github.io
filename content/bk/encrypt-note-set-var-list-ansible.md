---
title: "Not a tutorial: Set Variable List in Playbook; Ignore errors (Ansible)"
date: 2022-08-21T13:09:35+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Notes]
#tags: [Ansible]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "This is just my notes when playaround with ansible playbook, not a tutorial"
---

This is just my notes when playaround with ansible playbook, not a tutorial

# 1. Story 1

Khi viết ansible playbook có khi bạn phải xử lý nhiều items giống nhau, đó là bạn phải dùng loop, with_items

Để tránh việc tạo quá nhiều biến, set_facts nhiều trong playbook, bạn nên đưa hết các item ra file var

Khi có thêm jinja template vào thì cũng cần biết cách để đưa var vào

## 1.1. Practice

Ví dụ file `./vars/group_vars.yml` của mình như này:
```yml
---
services_list:
  - name: svc_a
    svc_name: "svcA"
    svc_dir: "/opt/svcA"
    svc_user: "a"
  - name: svc_b
    svc_name: "svcB"
    svc_dir: "/opt/B"
    svc_user: "b"
systemd_template_file: ./systemd_template_file.j2
```
các variables được mình tổ chức thành 1 list `services_list`

file `./systemd_template_file.j2`: 
```
[Unit]
Description={{ service_name }}
After=syslog.target

[Service]
User={{ service_user }}
ExecStart={{ service_dir }}/bin/{{ service_name }} start
ExecStop={{ service_dir }}/bin/{{ service_name }} stop

[Install]
WantedBy=multi-user.target
```

file `./playbook.yml` sẽ như này:
```yml
---
- name: Test
  hosts: myhosts
  become: true
  gather_facts: true
  vars_files:
    - "./vars/group_vars.yml"

  tasks:
    - name: Create serviced service file
      template:
        src: "{{ systemd_template_file }}"
        dest: "/etc/systemd/system/{{ item.svc_name }}.service"
        owner: root
        group: root
        mode: 0644
      with_items: "{{ services_list }}"
      vars: 
        service_name: "{{ item.svc_name }}"
        service_dir: "{{ item.svc_dir }}"
        service_user: "{{ item.svc_user }}"
```

Nghĩa là playbook này chỉ có 1 task là tạo ra lần lượt các file `/etc/systemd/system/svc_a.service` và `/etc/systemd/system/svc_b.service`.  
Với nội dung file được lấy từ Jinja template `./systemd_template_file.j2`, variables được set trong task

Để ý đoạn này:
```yml
      vars: 
        service_name: "{{ item.svc_name }}"
        service_dir: "{{ item.svc_dir }}"
        service_user: "{{ item.svc_user }}"
```
Đây là các variables sẽ được sử dụng trong content file `./systemd_template_file.j2`

Việc sử dụng đc các biến thế này giúp cho code Ansbile của bạn ngắn lại, tuy nhiên sẽ khó hiểu hơn vì nhìn đâu cũng thấy biến 🤣


# 2. Story 2

Sẽ có lúc bạn muốn ignore 1 lỗi cụ thể nào đó trong quá trình run Ansible Playbook

Ví dụ bạn có 1 task mà thi thoảng sẽ bị lỗi (có thể bởi vì bạn run nó nhiều lần, lỗi mạng, etc..) và trả về message lỗi là: `Oh my god! Timeout!`.  
Bạn muốn ignore cái lỗi `Oh my god! Timeout!` đó.  

Cách làm:

```yml
# task này trả về lỗi và error_code khác 0, bạn register nó và ignore nó
- name: test
  shell: echo error; exit 123
  register: out
  ignore_errors: yes

# bước tiếp bạn define thế nào là lỗi, 
# Task trên chỉ lỗi khi return_code (rc) khác 0 và trong stderr ko có chuỗi `Oh my god! Timeout!`
# Điều này có nghĩa là nếu task trên trả về rc khác 0 và trong stderr CÓ chuỗi `Oh my god! Timeout!` thì sẽ bị ignore
- fail: msg="{{ out.stderr }}"
  when: "out.rc != 0 and 'Oh my god! Timeout!' not in out.stderr"
```


# CREDIT

https://unix.stackexchange.com/a/355584  