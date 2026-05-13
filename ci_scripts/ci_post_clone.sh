#!/bin/sh

# ============================================
# Xcode Cloud 后克隆脚本
# 用途：将仓库中的 SDK 文件链接到 Xcode Cloud 期望的位置
# ============================================

echo "===== 开始执行 ci_post_clone.sh ====="
echo "仓库根目录: ${CI_PRIMARY_REPOSITORY_PATH}"
echo "工作目录: $(pwd)"

# 定义源路径（Git 仓库中的实际位置）
REPO_PATH="${CI_PRIMARY_REPOSITORY_PATH}"
DEST_BASE="/Volumes/workspace"

# ============================================
# 1. 处理 SDK/Libs 目录（GTSDK.xcframework）
# ============================================
echo ""
echo "--- 1. 处理 SDK/Libs 目录 ---"

LIBS_SOURCE="${REPO_PATH}/SDK/Libs"
LIBS_DEST="${DEST_BASE}/SDK/Libs"

if [ -d "${LIBS_SOURCE}" ]; then
    if [ ! -d "${LIBS_DEST}" ]; then
        echo "创建目录: ${LIBS_DEST}"
        mkdir -p "${DEST_BASE}/SDK"
        echo "创建软链接: ${LIBS_DEST} -> ${LIBS_SOURCE}"
        ln -s "${LIBS_SOURCE}" "${LIBS_DEST}"
        echo "✅ SDK/Libs 链接成功"
    else
        echo "✅ SDK/Libs 已存在"
    fi
else
    echo "❌ 错误: 未找到 ${LIBS_SOURCE}"
    ls -la "${REPO_PATH}/SDK/" 2>/dev/null || echo "SDK 目录不存在"
fi

# ============================================
# 2. 处理 SDK/Bundles 目录（所有 JS 和 Bundle 资源）
# ============================================
echo ""
echo "--- 2. 处理 SDK/Bundles 目录 ---"

BUNDLES_SOURCE="${REPO_PATH}/SDK/Bundles"
BUNDLES_DEST="${DEST_BASE}/SDK/Bundles"

if [ -d "${BUNDLES_SOURCE}" ]; then
    if [ ! -d "${BUNDLES_DEST}" ]; then
        echo "创建软链接: ${BUNDLES_DEST} -> ${BUNDLES_SOURCE}"
        ln -s "${BUNDLES_SOURCE}" "${BUNDLES_DEST}"
        echo "✅ SDK/Bundles 链接成功"
        
        # 验证关键文件
        echo "验证关键文件:"
        ls -la "${BUNDLES_DEST}" | head -10
    else
        echo "✅ SDK/Bundles 已存在"
    fi
else
    echo "❌ 错误: 未找到 ${BUNDLES_SOURCE}"
fi

# ============================================
# 3. 处理 SDK/PrivacyInfo.xcprivacy
# ============================================
echo ""
echo "--- 3. 处理 SDK/PrivacyInfo.xcprivacy ---"

PRIVACY_SOURCE="${REPO_PATH}/SDK/PrivacyInfo.xcprivacy"
PRIVACY_DEST="${DEST_BASE}/SDK/PrivacyInfo.xcprivacy"

if [ -f "${PRIVACY_SOURCE}" ]; then
    if [ ! -f "${PRIVACY_DEST}" ]; then
        # 确保目录存在
        mkdir -p "${DEST_BASE}/SDK"
        echo "创建软链接: ${PRIVACY_DEST} -> ${PRIVACY_SOURCE}"
        ln -s "${PRIVACY_SOURCE}" "${PRIVACY_DEST}"
        echo "✅ PrivacyInfo.xcprivacy 链接成功"
    else
        echo "✅ PrivacyInfo.xcprivacy 已存在"
    fi
else
    echo "❌ 错误: 未找到 ${PRIVACY_SOURCE}"
fi

# ============================================
# 4. 处理 HBuilder-Hello/Pandora 目录
# ============================================
echo ""
echo "--- 4. 处理 HBuilder-Hello/Pandora 目录 ---"

PANDORA_SOURCE="${REPO_PATH}/HBuilder-Hello/Pandora"
PANDORA_DEST="${REPO_PATH}/HBuilder-Hello/Pandora"  # 这个路径已经是正确的

if [ -d "${PANDORA_SOURCE}" ]; then
    echo "✅ Pandora 目录存在: ${PANDORA_SOURCE}"
    echo "内容预览:"
    ls -la "${PANDORA_SOURCE}" | head -5
else
    echo "⚠️ 警告: 未找到 Pandora 目录（可能不影响构建）"
fi

# ============================================
# 5. 处理 control.xml
# ============================================
echo ""
echo "--- 5. 处理 control.xml ---"

CONTROL_SOURCE="${REPO_PATH}/HBuilder-Hello/control.xml"
CONTROL_DEST="${DEST_BASE}/repository/HBuilder-Hello/control.xml"

if [ -f "${CONTROL_SOURCE}" ]; then
    if [ ! -f "${CONTROL_DEST}" ]; then
        # 确保目标目录存在
        mkdir -p "$(dirname ${CONTROL_DEST})"
        echo "创建软链接: ${CONTROL_DEST} -> ${CONTROL_SOURCE}"
        ln -s "${CONTROL_SOURCE}" "${CONTROL_DEST}"
        echo "✅ control.xml 链接成功"
    else
        echo "✅ control.xml 已存在"
    fi
else
    echo "⚠️ 警告: 未找到 control.xml"
fi

# ============================================
# 最终验证
# ============================================
echo ""
echo "--- 最终验证 ---"
echo "检查关键路径:"

PATHS_TO_VERIFY=(
    "/Volumes/workspace/SDK/Libs/GTSDK.xcframework"
    "/Volumes/workspace/SDK/Bundles/weexUniJs.js"
    "/Volumes/workspace/SDK/Bundles/uni-jsframework.js"
    "/Volumes/workspace/SDK/Bundles/PandoraApi.bundle"
    "/Volumes/workspace/SDK/PrivacyInfo.xcprivacy"
)

for path in "${PATHS_TO_VERIFY[@]}"; do
    if [ -e "$path" ]; then
        echo "✅ $path"
    else
        echo "❌ $path - 缺失"
    fi
done

echo ""
echo "===== ci_post_clone.sh 执行完成 ====="
