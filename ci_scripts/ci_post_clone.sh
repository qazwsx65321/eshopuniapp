#!/bin/sh

# ============================================
# Xcode Cloud 后克隆脚本（最终定版）
# 用途：将仓库中的 SDK 目录完整链接到 Xcode Cloud 期望的位置
# 解决：所有头文件、库文件、资源文件的路径问题
# ============================================

echo "=========================================="
echo "开始执行 ci_post_clone.sh"
echo "=========================================="
echo "仓库根目录: ${CI_PRIMARY_REPOSITORY_PATH}"
echo "当前时间: $(date)"
echo ""

# 定义路径
REPO_PATH="${CI_PRIMARY_REPOSITORY_PATH}"
DEST_BASE="/Volumes/workspace"

# ============================================
# 1. 处理完整的 SDK 目录（核心解决方案）
# ============================================
echo "=== 步骤 1: 链接整个 SDK 目录 ==="

SDK_SOURCE="${REPO_PATH}/SDK"
SDK_DEST="${DEST_BASE}/SDK"

if [ -d "${SDK_SOURCE}" ]; then
    echo "✅ 找到源 SDK 目录: ${SDK_SOURCE}"
    
    # 删除已存在的目标（如果是目录或链接）
    if [ -e "${SDK_DEST}" ]; then
        echo "目标路径已存在，正在移除..."
        rm -rf "${SDK_DEST}"
    fi
    
    # 创建软链接
    ln -s "${SDK_SOURCE}" "${SDK_DEST}"
    echo "✅ 已创建链接: ${SDK_DEST} -> ${SDK_SOURCE}"
    
    # 验证 SDK 目录结构
    echo ""
    echo "SDK 目录结构验证:"
    ls -la "${SDK_DEST}"
else
    echo "❌ 错误: 未找到 SDK 目录: ${SDK_SOURCE}"
    exit 1
fi

# ============================================
# 2. 验证关键子目录和文件
# ============================================
echo ""
echo "=== 步骤 2: 验证关键文件 ==="

# 定义需要检查的关键路径
KEY_PATHS=(
    "SDK/inc/PDRCore.h"
    "SDK/Libs/GTSDK.xcframework"
    "SDK/Bundles/weexUniJs.js"
    "SDK/Bundles/uni-jsframework.js"
    "SDK/Bundles/PandoraApi.bundle"
    "SDK/PrivacyInfo.xcprivacy"
)

ALL_FOUND=true
for path in "${KEY_PATHS[@]}"; do
    full_path="${DEST_BASE}/${path}"
    if [ -e "${full_path}" ]; then
        echo "  ✅ ${path}"
    else
        echo "  ❌ ${path} - 缺失"
        ALL_FOUND=false
    fi
done

# 检查 UTS 目录（如果存在）
if [ -d "${DEST_BASE}/SDK/UTS" ]; then
    echo "  ✅ SDK/UTS 目录存在"
    echo "     UTS 目录内容:"
    ls -la "${DEST_BASE}/SDK/UTS" | head -5
fi

# ============================================
# 3. 处理 HBuilder-Hello 项目资源
# ============================================
echo ""
echo "=== 步骤 3: 处理项目资源文件 ==="

# 创建 repository 下的目标目录
mkdir -p "${DEST_BASE}/repository/HBuilder-Hello"

# 处理 control.xml
CONTROL_SOURCE="${REPO_PATH}/HBuilder-Hello/control.xml"
CONTROL_DEST="${DEST_BASE}/repository/HBuilder-Hello/control.xml"

if [ -f "${CONTROL_SOURCE}" ]; then
    if [ -e "${CONTROL_DEST}" ]; then
        rm -f "${CONTROL_DEST}"
    fi
    ln -s "${CONTROL_SOURCE}" "${CONTROL_DEST}"
    echo "✅ control.xml 链接成功"
else
    echo "⚠️ control.xml 不存在（可选文件）"
fi

# 处理 Pandora 目录
PANDORA_SOURCE="${REPO_PATH}/HBuilder-Hello/Pandora"
PANDORA_DEST="${DEST_BASE}/repository/HBuilder-Hello/Pandora"

if [ -d "${PANDORA_SOURCE}" ]; then
    if [ -e "${PANDORA_DEST}" ]; then
        rm -rf "${PANDORA_DEST}"
    fi
    ln -s "${PANDORA_SOURCE}" "${PANDORA_DEST}"
    echo "✅ Pandora 目录链接成功"
else
    echo "⚠️ Pandora 目录不存在（可选文件）"
fi

# ============================================
# 4. 处理 HBuilder 源代码目录中的头文件搜索路径
# ============================================
echo ""
echo "=== 步骤 4: 创建额外的头文件链接 ==="

# 有些项目可能会在 HBuilder 目录中查找头文件
HBUILDER_INC_SOURCE="${REPO_PATH}/HBuilder/inc"
HBUILDER_INC_DEST="${DEST_BASE}/HBuilder/inc"

if [ -d "${HBUILDER_INC_SOURCE}" ]; then
    if [ ! -L "${HBUILDER_INC_DEST}" ] && [ ! -d "${HBUILDER_INC_DEST}" ]; then
        mkdir -p "${DEST_BASE}/HBuilder"
        ln -s "${HBUILDER_INC_SOURCE}" "${HBUILDER_INC_DEST}"
        echo "✅ HBuilder/inc 链接成功"
    fi
fi

# ============================================
# 最终验证和总结
# ============================================
echo ""
echo "=========================================="
echo "最终验证结果"
echo "=========================================="

# 检查最关键的几个路径
CRITICAL_PATHS=(
    "/Volumes/workspace/SDK/inc/PDRCore.h"
    "/Volumes/workspace/SDK/Libs/GTSDK.xcframework"
    "/Volumes/workspace/SDK/Bundles/weexUniJs.js"
)

MISSING_COUNT=0
for path in "${CRITICAL_PATHS[@]}"; do
    if [ -e "${path}" ]; then
        echo "✅ ${path}"
    else
        echo "❌ ${path}"
        MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
done

echo ""
if [ $MISSING_COUNT -eq 0 ]; then
    echo "🎉 所有关键文件都已就绪！"
    echo "🎉 Xcode Cloud 构建应该可以成功完成！"
else
    echo "⚠️ 仍有 ${MISSING_COUNT} 个关键文件缺失"
    echo "请检查 Git 仓库中的 SDK 目录结构"
fi

echo ""
echo "=========================================="
echo "ci_post_clone.sh 执行完成"
echo "=========================================="
