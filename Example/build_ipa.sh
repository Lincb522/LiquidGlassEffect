#!/bin/bash

# LiquidGlassDemo IPA 构建脚本
# 构建免签 IPA 用于 TrollStore 安装

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PROJECT_NAME="LiquidGlassDemo"
SCHEME="LiquidGlassDemo"
BUILD_DIR="$SCRIPT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/$PROJECT_NAME.xcarchive"
IPA_PATH="$SCRIPT_DIR/$PROJECT_NAME.ipa"

echo "🧹 清理旧构建..."
rm -rf "$BUILD_DIR"
rm -f "$IPA_PATH"
mkdir -p "$BUILD_DIR"

echo ""
echo "🔨 构建项目..."

xcodebuild archive \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=iOS" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    AD_HOC_CODE_SIGNING_ALLOWED=YES \
    | xcpretty || xcodebuild archive \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=iOS" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    AD_HOC_CODE_SIGNING_ALLOWED=YES

echo ""
echo "📦 创建 IPA..."

# 创建 Payload 目录
PAYLOAD_DIR="$BUILD_DIR/Payload"
mkdir -p "$PAYLOAD_DIR"

# 复制 .app 到 Payload
APP_PATH="$ARCHIVE_PATH/Products/Applications/$PROJECT_NAME.app"
if [ -d "$APP_PATH" ]; then
    cp -r "$APP_PATH" "$PAYLOAD_DIR/"
else
    echo "❌ 找不到 .app 文件: $APP_PATH"
    exit 1
fi

# 压缩为 IPA
cd "$BUILD_DIR"
zip -r "$IPA_PATH" Payload -x "*.DS_Store"
cd "$SCRIPT_DIR"

echo ""
echo "🧹 清理临时文件..."
rm -rf "$BUILD_DIR"

echo ""
echo "✅ IPA 构建完成！"
echo ""
echo "📱 IPA 文件: $IPA_PATH"
echo ""
echo "💡 安装方式："
echo "   1. TrollStore: 直接安装 IPA"
echo "   2. Sideloadly: 需要 Apple ID"
echo "   3. AltStore: 需要 Apple ID"
