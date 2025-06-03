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
EOF
