#!/bin/sh

# ============================================
# Xcode Cloud 后克隆脚本
# 用途：修复 GTSDK.xcframework 路径问题
# ============================================

echo "===== 开始执行 ci_post_clone.sh ====="

# 1. 显示当前工作目录和仓库路径
echo "当前工作目录: $(pwd)"
echo "仓库根目录: ${CI_PRIMARY_REPOSITORY_PATH}"

# 2. 自动查找 GTSDK.xcframework 的实际位置
echo "正在查找 GTSDK.xcframework..."

# 在仓库根目录下递归查找（排除隐藏文件夹和 DerivedData）
GTSDK_PATH=$(find "${CI_PRIMARY_REPOSITORY_PATH}" -name "GTSDK.xcframework" -type d -not -path "*/.*" -not -path "*/DerivedData/*" 2>/dev/null | head -1)

# 3. 检查是否找到
if [ -z "$GTSDK_PATH" ]; then
    echo "❌ 错误：未找到 GTSDK.xcframework"
    echo "当前仓库目录结构："
    ls -la "${CI_PRIMARY_REPOSITORY_PATH}"
    echo ""
    echo "请检查："
    echo "  1. GTSDK.xcframework 是否已提交到 Git 仓库"
    echo "  2. .gitignore 是否忽略了 .xcframework 文件"
    echo "  3. 文件名大小写是否正确"
    exit 1
fi

echo "✅ 找到 GTSDK.xcframework 在: ${GTSDK_PATH}"

# 4. 设置目标路径（Xcode Cloud 期望的路径）
DEST_DIR="/Volumes/workspace/SDK/Libs"
DEST_PATH="${DEST_DIR}/GTSDK.xcframework"

echo "目标路径应该是: ${DEST_PATH}"

# 5. 检查目标路径是否已存在
if [ -d "$DEST_PATH" ]; then
    echo "✅ GTSDK.xcframework 已存在于目标路径，无需操作"
    exit 0
fi

# 6. 创建目标目录并建立软链接
echo "正在创建目标目录: ${DEST_DIR}"
mkdir -p "${DEST_DIR}"

if [ $? -ne 0 ]; then
    echo "❌ 无法创建目标目录"
    exit 1
fi

echo "正在创建软链接: ${DEST_PATH} -> ${GTSDK_PATH}"
ln -s "${GTSDK_PATH}" "${DEST_PATH}"

if [ $? -eq 0 ]; then
    echo "✅ 软链接创建成功"
    echo "验证链接："
    ls -la "${DEST_PATH}"
else
    echo "❌ 软链接创建失败"
    exit 1
fi

echo "===== ci_post_clone.sh 执行完成 ====="
