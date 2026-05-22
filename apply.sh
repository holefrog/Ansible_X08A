#!/bin/bash

# 切换到脚本所在目录，确保相对路径执行正确
cd "$(dirname "$0")" || exit

# 连接到目标安卓设备
adb connect 192.168.50.180

# 运行 Ansible playbook
# 清单文件可由 ansible.cfg 默认配置，或者在运行时通过参数传入，例如：./apply.sh -i my_inventory
# "$@" 允许你在执行脚本时附加其他 Ansible 参数，例如 ./apply.sh -v 或 ./apply.sh --tags apps
ansible-playbook site.yml -K "$@"