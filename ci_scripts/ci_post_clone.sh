#!/bin/sh

# ============================================
# Xcode Cloud 后克隆脚本（最终简化版）
# 用途：链接 SDK 目录到正确位置
# ============================================

echo "=========================================="
echo "开始执行 ci_post_clone.sh"
echo "=========================================="
echo "仓库根目录: ${CI_PRIMARY_REPOSITORY_PATH}"
echo ""

REPO_PATH="${CI_PRIMARY_REPOSITORY_PATH}"
DEST_BASE="/Volumes/workspace"

# ============================================
# 1. 链接整个 SDK 目录
# ============================================
echo "=== 步骤 1: 链接 SDK 目录 ==="

SDK_SOURCE="${REPO_PATH}/SDK"
SDK_DEST="${DEST_BASE}/SDK"

if [ -d "${SDK_SOURCE}" ]; then
    if [ -e "${SDK_DEST}" ]; then
        rm -rf "${SDK_DEST}"
    fi
    ln -s "${SDK_SOURCE}" "${SDK_DEST}"
    echo "✅ SDK 目录链接成功: ${SDK_DEST} -> ${SDK_SOURCE}"
else
    echo "❌ 错误: SDK 目录不存在"
    exit 1
fi

# ============================================
# 2. 验证关键文件
# ============================================
echo ""
echo "=== 步骤 2: 验证关键文件 ==="

KEY_PATHS=(
    "SDK/inc/PDRCore.h"
    "SDK/Libs/GTSDK.xcframework"
    "SDK/Bundles/weexUniJs.js"
    "SDK/Bundles/uni-jsframework.js"
    "SDK/libs/libuchardet.a"
)

ALL_OK=true
for path in "${KEY_PATHS[@]}"; do
    full_path="${DEST_BASE}/${path}"
    if [ -e "${full_path}" ]; then
        echo "  ✅ ${path}"
    else
        echo "  ❌ ${path} - 缺失"
        ALL_OK=false
    fi
done

# ============================================
# 3. 处理项目资源
# ============================================
echo ""
echo "=== 步骤 3: 处理项目资源 ==="

mkdir -p "${DEST_BASE}/repository/HBuilder-Hello"

if [ -f "${REPO_PATH}/HBuilder-Hello/control.xml" ]; then
    ln -sf "${REPO_PATH}/HBuilder-Hello/control.xml" "${DEST_BASE}/repository/HBuilder-Hello/control.xml"
    echo "✅ control.xml 链接成功"
fi

if [ -d "${REPO_PATH}/HBuilder-Hello/Pandora" ]; then
    ln -sf "${REPO_PATH}/HBuilder-Hello/Pandora" "${DEST_BASE}/repository/HBuilder-Hello/Pandora"
    echo "✅ Pandora 目录链接成功"
fi

echo ""
echo "=========================================="
if [ "$ALL_OK" = true ]; then
    echo "✅ 所有关键文件都已就绪"
    echo "🎉 Xcode Cloud 构建应该可以成功！"
else
    echo "⚠️ 部分文件缺失，请检查 Git 仓库"
fi
echo "=========================================="
