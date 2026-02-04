#!/bin/bash

# LiquidGlassDemo 项目生成脚本
# 使用 XcodeGen 生成免签调试的 Xcode 项目

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔧 检查 XcodeGen..."

if ! command -v xcodegen &> /dev/null; then
    echo "❌ XcodeGen 未安装"
    echo ""
    echo "请使用以下方式安装："
    echo "  brew install xcodegen"
    echo ""
    echo "或者使用 Mint："
    echo "  mint install yonaskolb/XcodeGen"
    exit 1
fi

echo "✅ XcodeGen 已安装"
echo ""
echo "🚀 生成 Xcode 项目..."

xcodegen generate

echo ""
echo "✅ 项目生成完成！"
echo ""
echo "📂 打开项目："
echo "   open LiquidGlassDemo.xcodeproj"
echo ""
echo "💡 提示："
echo "   - 此项目已配置为免签调试模式"
echo "   - 可直接在模拟器上运行"
echo "   - 真机调试需要使用 TrollStore 或其他方式"
