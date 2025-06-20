SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
CONFIG_FILE="$SCRIPT_DIR/.env_config_sensecore"
cat << EOF >> ~/.bashrc

CONFIG_FILE="$CONFIG_FILE"
echo "\$CONFIG_FILE"
if [ -f "\$CONFIG_FILE" ]; then
    source "\$CONFIG_FILE"

    function proxy_on() {
        if [ -n "\$PROXY_USER" ] && [ -n "\$PROXY_PASS" ]; then
            export http_proxy="http://\${PROXY_USER}:\${PROXY_PASS}@\${PROXY_HOST}:\${PROXY_PORT}"
            export https_proxy="http://\${PROXY_USER}:\${PROXY_PASS}@\${PROXY_HOST}:\${PROXY_PORT}"
        else
            export http_proxy="http://\${PROXY_HOST}:\${PROXY_PORT}"
            export https_proxy="http://\${PROXY_HOST}:\${PROXY_PORT}"
        fi
        export no_proxy="\${NO_PROXY}"
        echo -e "\\033[32m[√] 已开启代理\\033[0m"
    }

    function proxy_off(){
        unset http_proxy
        unset https_proxy
        unset no_proxy
        echo -e "\\033[31m[×] 已关闭代理\\033[0m"
    }

    # 设置其他环境变量
    conda config --add envs_dirs "\${CONDA_ENVS_DIR}"
    export UV_DEFAULT_INDEX
    export HF_HOME
    export UV_CACHE_DIR

                        
fi
mkdir -p ~/.trash   #在家目录下创建一个.trash文件夹(隐藏文件，ls -a 查看)
alias rm=del        #使用别名del代替rm   
del()               #函数del，作用：将rm命令修改为mv命令
{  
    mv $@ ~/.trash/  
}  


EOF

# 创建清理脚本
cat << 'EOF' > ~/cleanTrashCan
#!/bin/bash

arrayA=($(find ~/.trash/* -mtime +7 | awk '{print $1}'))
for file in ${arrayA[@]}
do
    $(rm -rf "${file}")
    filename="${file##*/}"
    echo $filename
    $(sed -i /$filename/'d' "$HOME/.trash/.log")
done
EOF

# 赋予执行权限
chmod +x ~/cleanTrashCan

# 添加cron任务（如果尚未添加）
(crontab -l 2>/dev/null | grep -v "cleanTrashCan"; echo "10 18 * * * $HOME/cleanTrashCan") | crontab -
