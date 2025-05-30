# author : Eggward Han
# 该脚本用于快速配置国内软件源，以加速常用开发工具和语言包的下载与更新过程。适用于中国大陆用户或在海外服务器上需要切换至国内镜像的场景。
# 目的：一键更换多个常用工具的默认源为国内镜像，提升访问速度和安装效率。
# 适用对象：Python、pip、Ubuntu APT、Node.js 和 Conda 用户。
# 注意事项：chsrc 是第三方工具，请确保信任其来源；系统级更改（如 APT）需管理员权限。

curl https://chsrc.run/posix | sudo bash

chsrc set python 
chsrc set pip
sudo chsrc set ubuntu
chsrc set node 
chsrc set conda 