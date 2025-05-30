function proxy_on() {
        export http_proxy=http://lm4sciencefj2:15c78115@10.54.0.93:3128
        export https_proxy=http://lm4sciencefj2:15c78115@10.54.0.93:3128
        export no_proxy=127.0.0.1,localhost
        echo -e "\033[32m[√] 已开启代理\033[0m"
}

# 关闭系统代理
function proxy_off(){
        unset http_proxy
        unset https_proxy
        unset no_proxy
        echo -e "\033[31m[×] 已关闭代理\033[0m"
}
