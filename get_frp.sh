#!/usr/bin/env bash
set -e

# 1. 检查 jq 是否安装
if ! command -v jq &>/dev/null; then
    echo "jq not found, installing..."
    sudo apt update && sudo apt install -y jq
fi

# 2. 获取最新 release JSON
release_json=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest)

# 3. 解析最新版本号
version=$(echo "$release_json" | jq -r '.tag_name' | sed 's/^v//')

# 4. 自动识别系统 + 架构
os=$(uname | tr '[:upper:]' '[:lower:]')         # linux / darwin
arch=$(uname -m)                                # x86_64 / aarch64 / arm64
# 映射 uname 架构到 frp 名称
case "$arch" in
    x86_64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) echo "Unsupported arch: $arch"; exit 1 ;;
esac

file_name="frp_${version}_${os}_${arch}.tar.gz"

# 5. 找到对应下载 URL
download_url=$(echo "$release_json" | jq -r --arg file "$file_name" '.assets[] | select(.name == $file) | .browser_download_url')
download_url="https://ghfast.top/$download_url"
echo $download_url
if [ -z "$download_url" ]; then
    echo "Error: cannot find download URL for $file_name"
    exit 1
fi

# 6. 下载
echo "Downloading $file_name ..."
curl -L -o "$file_name" "$download_url"

# 7. 解压
echo "Extracting ..."
tar -xzf "$file_name"

echo "Done. Binary is in frp_${version}_${os}_${arch}/"
