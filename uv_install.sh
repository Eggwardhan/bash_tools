curl -LsSf https://astral.sh/uv/install.sh | sh


echo 'UV_CACHE_DIR=/mnt/cache/houzhaohui/.cache/uv' >> ~/.bashrc
pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple

source $HOME/.local/bin/env
source ~/.bashrc