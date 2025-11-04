#!/bin/bash

# Windows 应用签名脚本
# 用法: ./sign_windows.sh <证书路径> <证书密码> <要签名的文件>

set -e

CERT_FILE="$1"
CERT_PASSWORD="$2"
INPUT_FILE="$3"
OUTPUT_FILE="${INPUT_FILE%.exe}-signed.exe"

# 检查参数
if [ -z "$CERT_FILE" ] || [ -z "$CERT_PASSWORD" ] || [ -z "$INPUT_FILE" ]; then
    echo "用法: $0 <证书路径> <证书密码> <要签名的文件>"
    echo "示例: $0 cert.pfx mypassword app.exe"
    exit 1
fi

# 检查证书文件是否存在
if [ ! -f "$CERT_FILE" ]; then
    echo "错误: 证书文件不存在: $CERT_FILE"
    exit 1
fi

# 检查输入文件是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "错误: 输入文件不存在: $INPUT_FILE"
    exit 1
fi

# 检查 osslsigncode 是否已安装
if ! command -v osslsigncode &> /dev/null; then
    echo "错误: osslsigncode 未安装"
    echo "请运行: brew install osslsigncode"
    exit 1
fi

echo "开始签名: $INPUT_FILE"
echo "证书文件: $CERT_FILE"
echo "输出文件: $OUTPUT_FILE"

# 执行签名
osslsigncode sign \
  -pkcs12 "$CERT_FILE" \
  -pass "$CERT_PASSWORD" \
  -n "蓝快加速器" \
  -i "https://radnb.com" \
  -t http://timestamp.digicert.com \
  -in "$INPUT_FILE" \
  -out "$OUTPUT_FILE"

echo "签名完成: $OUTPUT_FILE"

# 验证签名
echo "验证签名..."
osslsigncode verify "$OUTPUT_FILE"

echo "签名验证成功！"
