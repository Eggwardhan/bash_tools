# author : Eggward Han
# 该脚本用于快速配置国内软件源，以加速常用开发工具和语言包的下载与更新过程。适用于中国大陆用户或在海外服务器上需要切换至国内镜像的场景。
# 目的：一键更换多个常用工具的默认源为国内镜像，提升访问速度和安装效率。
# 适用对象：Python、pip、Ubuntu APT、Node.js 和 Conda 用户。
# 注意事项：chsrc 是第三方工具，请确保信任其来源；系统级更改（如 APT）需管理员权限。

# curl https://chsrc.run/posix | sudo bash
# 如果失败了运行
#!/usr/bin/env bash

set -e

OS="$(uname -s)"
ARCH="$(uname -m)"
VERSION="${1:-pre}"  # 默认版本为 pre

echo "🛠️ 安装 chsrc（版本: $VERSION）"
echo "🔍 操作系统: $OS"
echo "🔍 架构: $ARCH"

install_windows() {
  echo "📥 Windows 环境，使用 PowerShell 安装 chsrc（Gitee 镜像）..."
  powershell.exe -NoProfile -Command \
    "& { iwr -useb https://gitee.com/RubyMetric/chsrc/raw/main/tool/installer.ps1 | iex } -Version $VERSION"
}

install_macos_or_linux() {
  echo "📥 macOS/Linux 环境，使用 Gitee 安装脚本..."

  INSTALL_URL="https://gitee.com/RubyMetric/chsrc/raw/main/tool/installer.sh"

  if [ "$EUID" -eq 0 ]; then
    bash -c "curl -fsSL $INSTALL_URL | bash -s -- -v $VERSION"
  else
    bash -c "curl -fsSL $INSTALL_URL | bash -s -- -v $VERSION"
  fi
}

# 判断平台
case "$OS" in
  Linux)
    if grep -qi microsoft /proc/version; then
      install_windows  # Windows Subsystem for Linux
    else
      install_macos_or_linux
    fi
    ;;
  Darwin)
    install_macos_or_linux
    ;;
  MINGW*|MSYS*|CYGWIN*)
    install_windows
    ;;
  *)
    echo "❌ 不支持的操作系统: $OS"
    exit 1
    ;;
esac

echo "✅ chsrc 安装完成。可运行 chsrc -h 查看命令。"


chsrc set python 
chsrc set pip
sudo chsrc set ubuntu
chsrc set node 
chsrc set conda 
