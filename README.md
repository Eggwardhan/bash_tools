# bash_tools项目说明
## 一、项目简介
`bash_tools`是一个包含多个bash脚本工具的项目，旨在为用户提供便捷的系统操作辅助。这些脚本涵盖了环境配置、网络检查、软件安装、进程管理等多个方面，能有效提升工作效率，简化日常系统管理任务。

## 二、文件说明
|文件名|功能概述|
|--|--|
|`.bashrc`|bash环境副本|
|`.env_config_hsh`|初始化文件，fj环境配置所需参数,目前包含PROXY， conda， cache配置|
|`.env_config_sensecore`|添加了用于配置sensecore环境的内容到`.bashrc`的相关设置|
|`all_keys.txt`|存储着与项目相关的各类密钥|
|`append_to_bashrc.sh`|主要功能是向`.bashrc`文件追加配置内容，当前添加了sensecore的配置，通过运行该脚本可方便地修改bash环境配置|
|`check_proxy.sh`|用于设置网络代理设置切换|
|`get_github.sh`|用于从GitHub更换host|
|`kill_zombie.sh`|负责查找并终止僵尸进程，有效清理系统中占用资源但无实际作用的僵尸进程，优化系统性能|
|`source_change.sh`|用于更改系统软件源，帮助用户切换到更合适的软件源，以提高软件安装和更新的速度|
|`uv_install.sh`|用于安装与uv相关的软件或组件，具体安装内容需查看脚本内的安装命令确定|

## 三、使用方法
1. **下载项目**：在终端中使用`git clone https://github.com/Eggwardhan/bash_tools.git`命令将项目克隆到本地。
2. **运行脚本**：进入项目目录，例如`cd bash_tools`。对于不同功能的脚本，执行方式有所不同。
    - 若要运行`append_to_bashrc.sh`脚本，直接在终端输入`bash append_to_bashrc.sh`即可完成对`.bashrc`文件的配置追加操作，之后可能需要重新启动bash会话使配置生效。
    - 若要进行模块换源，运行source_change.sh脚本，根据需求修改要切换的源。
## 四、注意事项
1. 部分脚本可能需要一定的系统权限才能正常运行，例如更改软件源、终止进程等操作，运行时请确保具有足够权限。
2. 在修改`.bashrc`文件时，若配置错误可能导致bash环境异常，建议在修改前备份`.bashrc`文件。
