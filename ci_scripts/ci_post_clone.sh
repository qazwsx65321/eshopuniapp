#!/bin/sh

# ============================================
# Xcode Cloud 后克隆脚本
# 用途：将仓库中的 SDK 文件链接到 Xcode Cloud 期望的位置
# 解决：GTSDK.xcframework、资源文件、头文件的所有路径问题
# ============================================

echo "===== 开始执行 ci_post_clone.sh ====="
echo "仓库根目录: ${CI_PRIMARY_REPOSITORY_PATH}"
echo "当前时间: $(date)"

# 定义路径
REPO_PATH="${CI_PRIMARY_REPOSITORY_PATH}"
DEST_BASE="/Volumes/workspace"

# 创建基础目录
mkdir -p "${DEST_BASE}/SDK"
mkdir -p "${DEST_BASE}/repository/HBuilder-Hello"

# ============================================
# 1. 处理 SDK/Libs 目录（GTSDK.xcframework）
# ============================================
echo ""
echo "=== 1. 处理 SDK/Libs 目录 ==="

LIBS_SOURCE="${REPO_PATH}/SDK/Libs"
LIBS_DEST="${DEST_BASE}/SDK/Libs"

if [ -d "${LIBS_SOURCE}" ]; then
    if [ ! -L "${LIBS_DEST}" ] && [ ! -d "${LIBS_DEST}" ]; then
        ln -s "${LIBS_SOURCE}" "${LIBS_DEST}"
        echo "✅ 已创建链接: ${LIBS_DEST} -> ${LIBS_SOURCE}"
    else
        echo "✅ SDK/Libs 已存在"
    fi
    
    # 验证 GTSDK.xcframework
    if [ -d "${LIBS_DEST}/GTSDK.xcframework" ]; then
        echo "✅ GTSDK.xcframework 可用"
    else
        echo "⚠️ 警告: GTSDK.xcframework 不存在"
    fi
else
    echo "❌ 错误: 未找到 ${LIBS_SOURCE}"
    exit 1
fi

# ============================================
# 2. 处理 SDK/inc 目录（头文件，包含 PDRCore.h）
# ============================================
echo ""
echo "=== 2. 处理 SDK/inc 目录 ==="

INC_SOURCE="${REPO_PATH}/SDK/inc"
INC_DEST="${DEST_BASE}/SDK/inc"

if [ -d "${INC_SOURCE}" ]; then
    if [ ! -L "${INC_DEST}" ] && [ ! -d "${INC_DEST}" ]; then
        ln -s "${INC_SOURCE}" "${INC_DEST}"
        echo "✅ 已创建链接: ${INC_DEST} -> ${INC_SOURCE}"
    else
        echo "✅ SDK/inc 已存在"
    fi
    
    # 验证 PDRCore.h
    if [ -f "${INC_DEST}/PDRCore.h" ]; then
        echo "✅ PDRCore.h 可用"
    else
        echo "⚠️ 警告: PDRCore.h 不存在于 ${INC_DEST}"
        ls -la "${INC_DEST}" | head -10
    fi
else
    echo "❌ 错误: 未找到 ${INC_SOURCE}"
    echo "查找 PDRCore.h 的实际位置..."
    PDR_PATH=$(find "${REPO_PATH}" -name "PDRCore.h" 2>/dev/null | head -1)
    if [ -n "$PDR_PATH" ]; then
        echo "找到 PDRCore.h 在: ${PDR_PATH}"
        PDR_DIR=$(dirname "${PDR_PATH}")
        ln -s "${PDR_DIR}" "${INC_DEST}"
        echo "✅ 已链接到: ${PDR_DIR}"
    else
        echo "❌ 严重错误: 未找到 PDRCore.h"
        exit 1
    fi
fi

# ============================================
# 3. 处理 SDK/Bundles 目录（JS 和 Bundle 资源）
# ============================================
echo ""
echo "=== 3. 处理 SDK/Bundles 目录 ==="

BUNDLES_SOURCE="${REPO_PATH}/SDK/Bundles"
BUNDLES_DEST="${DEST_BASE}/SDK/Bundles"

if [ -d "${BUNDLES_SOURCE}" ]; then
    if [ ! -L "${BUNDLES_DEST}" ] && [ ! -d "${BUNDLES_DEST}" ]; then
        ln -s "${BUNDLES_SOURCE}" "${BUNDLES_DEST}"
        echo "✅ 已创建链接: ${BUNDLES_DEST} -> ${BUNDLES_SOURCE}"
    else
        echo "✅ SDK/Bundles 已存在"
    fi
    
    # 验证关键文件
    echo "验证关键资源文件:"
    for file in weexUniJs.js weex-polyfill.js uni-jsframework.js uni-jsframework-vue3.js __uniappes6.js unincomponents.ttf; do
        if [ -f "${BUNDLES_DEST}/${file}" ]; then
            echo "  ✅ ${file}"
        else
            echo "  ⚠️ ${file} 缺失"
        fi
    done
    
    # 验证 Bundle 目录
    for bundle in PandoraApi.bundle DCTZImagePickerController.bundle DCSVProgressHUD.bundle; do
        if [ -d "${BUNDLES_DEST}/${bundle}" ]; then
            echo "  ✅ ${bundle}"
        else
            echo "  ⚠️ ${bundle} 缺失"
        fi
    done
else
    echo "❌ 错误: 未找到 ${BUNDLES_SOURCE}"
    exit 1
fi

# ============================================
# 4. 处理 SDK/PrivacyInfo.xcprivacy
# ============================================
echo ""
echo "=== 4. 处理 SDK/PrivacyInfo.xcprivacy ==="

PRIVACY_SOURCE="${REPO_PATH}/SDK/PrivacyInfo.xcprivacy"
PRIVACY_DEST="${DEST_BASE}/SDK/PrivacyInfo.xcprivacy"

if [ -f "${PRIVACY_SOURCE}" ]; then
    if [ ! -L "${PRIVACY_DEST}" ] && [ ! -f "${PRIVACY_DEST}" ]; then
        ln -s "${PRIVACY_SOURCE}" "${PRIVACY_DEST}"
        echo "✅ 已创建链接: ${PRIVACY_DEST} -> ${PRIVACY_SOURCE}"
    else
        echo "✅ PrivacyInfo.xcprivacy 已存在"
    fi
else
    echo "⚠️ 警告: 未找到 PrivacyInfo.xcprivacy"
fi

# ============================================
# 5. 处理 HBuilder-Hello/control.xml
# ============================================
echo ""
echo "=== 5. 处理 control.xml ==="

CONTROL_SOURCE="${REPO_PATH}/HBuilder-Hello/control.xml"
CONTROL_DEST="${DEST_BASE}/repository/HBuilder-Hello/control.xml"

if [ -f "${CONTROL_SOURCE}" ]; then
    if [ ! -L "${CONTROL_DEST}" ] && [ ! -f "${CONTROL_DEST}" ]; then
        ln -s "${CONTROL_SOURCE}" "${CONTROL_DEST}"
        echo "✅ 已创建链接: ${CONTROL_DEST} -> ${CONTROL_SOURCE}"
    else
        echo "✅ control.xml 已存在"
    fi
else
    echo "⚠️ 警告: 未找到 control.xml"
fi

# ============================================
# 6. 处理 HBuilder-Hello/Pandora 目录
# ============================================
echo ""
echo "=== 6. 处理 Pandora 目录 ==="

PANDORA_SOURCE="${REPO_PATH}/HBuilder-Hello/Pandora"
PANDORA_DEST="${DEST_BASE}/repository/HBuilder-Hello/Pandora"

if [ -d "${PANDORA_SOURCE}" ]; then
    if [ ! -L "${PANDORA_DEST}" ] && [ ! -d "${PANDORA_DEST}" ]; then
        ln -s "${PANDORA_SOURCE}" "${PANDORA_DEST}"
        echo "✅ 已创建链接: ${PANDORA_DEST} -> ${PANDORA_SOURCE}"
    else
        echo "✅ Pandora 目录已存在"
    fi
    echo "✅ Pandora 目录可用"
else
    echo "⚠️ 警告: 未找到 Pandora 目录（可能不影响构建）"
fi

# ============================================
# 最终验证
# ============================================
echo ""
echo "=== 最终验证 ==="
echo "所有关键路径检查:"

VERIFY_PATHS=(
    "/Volumes/workspace/SDK/Libs/GTSDK.xcframework"
    "/Volumes/workspace/SDK/inc/PDRCore.h"
    "/Volumes/workspace/SDK/Bundles/weexUniJs.js"
    "/Volumes/workspace/SDK/Bundles/uni-jsframework.js"
    "/Volumes/workspace/SDK/Bundles/PandoraApi.bundle"
)

ALL_OK=true
for path in "${VERIFY_PATHS[@]}"; do
    if [ -e "$path" ]; then
        echo "  ✅ $path"
    else
        echo "  ❌ $path - 缺失"
        ALL_OK=false
    fi
done

echo ""
if [ "$ALL_OK" = true ]; then
    echo "🎉 所有关键文件都已就绪，构建应该可以成功！"
else
    echo "⚠️ 部分文件缺失，请检查上面的错误信息"
fi

echo ""
echo "===== ci_post_clone.sh 执行完成 ====="
