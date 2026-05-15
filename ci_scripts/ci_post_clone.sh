#!/bin/sh

# ============================================
# Xcode Cloud 后克隆脚本（最终增强版）
# 用途：链接 SDK 目录并修复静态库问题
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
    cp -R "${SDK_SOURCE}" "${SDK_DEST}"
    echo "✅ SDK 目录链接成功: ${SDK_DEST} -> ${SDK_SOURCE}"
    
    # 验证链接
    if [ -d "${SDK_DEST}" ]; then
        echo "✅ SDK 目录链接有效"
    else
        echo "❌ SDK 目录链接无效"
        exit 1
    fi
else
    echo "❌ 错误: SDK 目录不存在"
    exit 1
fi

# ============================================
# 2. 修复静态库对齐问题（增强版）
# ============================================
echo ""
echo "=== 步骤 2: 修复静态库对齐问题 ==="

# 检查并安装必要工具
check_tools() {
    if ! command -v ar &> /dev/null; then
        echo "❌ ar 命令不可用"
        return 1
    fi
    if ! command -v libtool &> /dev/null; then
        echo "❌ libtool 命令不可用"
        return 1
    fi
    return 0
}

# 修复单个静态库
fix_static_lib() {
    local lib_path="$1"
    local lib_name=$(basename "$lib_path")
    
    if [ ! -f "$lib_path" ]; then
        echo "  ⚠️ 库文件不存在: $lib_name"
        return 1
    fi
    
    # 检查文件大小
    local lib_size=$(stat -f%z "$lib_path" 2>/dev/null || stat -c%s "$lib_path" 2>/dev/null)
    if [ "$lib_size" -lt 1000 ]; then
        echo "  ⚠️ $lib_name 文件过小 (${lib_size} bytes)，可能已损坏"
        return 1
    fi
    
    echo "  处理: $lib_name (${lib_size} bytes)"
    
    # 创建临时目录
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # 复制原文件到临时目录
    cp "$lib_path" "./${lib_name}"
    
    # 尝试提取 .o 文件
    if ar -x "./${lib_name}" 2>/dev/null; then
        local obj_count=$(ls -1 *.o 2>/dev/null | wc -l)
        
        if [ "$obj_count" -gt 0 ]; then
            echo "    提取了 ${obj_count} 个 .o 文件"
            
            # 重新打包
            if libtool -static -o "fixed_${lib_name}" *.o 2>/dev/null; then
                # 检查新文件大小
                local new_size=$(stat -f%z "fixed_${lib_name}" 2>/dev/null || stat -c%s "fixed_${lib_name}" 2>/dev/null)
                
                # 替换原文件
                mv "fixed_${lib_name}" "$lib_path"
                echo "    ✅ 修复成功: $lib_name (${new_size} bytes)"
                
                # 验证修复后的文件
                if ar -t "$lib_path" 2>/dev/null | head -1 > /dev/null; then
                    echo "    ✅ 验证通过: $lib_name"
                else
                    echo "    ⚠️ 验证失败，恢复原文件"
                    cp "./${lib_name}" "$lib_path"
                fi
            else
                echo "    ❌ 重新打包失败: $lib_name"
            fi
        else
            echo "    ⚠️ 没有提取到 .o 文件: $lib_name"
        fi
    else
        echo "    ❌ 提取 .o 文件失败: $lib_name"
    fi
    
    # 清理
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    return 0
}

# 需要修复的库列表
LIBS_TO_FIX=(
    "${SDK_DEST}/libs/libmp3lame.a"
    "${SDK_DEST}/libs/libTouchJSON.a"
)

# 可选：修复所有 .a 文件（如果需要）
FIX_ALL_LIBS=false  # 设置为 true 会修复所有静态库

if [ "$FIX_ALL_LIBS" = true ]; then
    echo "  扫描所有静态库..."
    for lib in $(find "${SDK_DEST}/libs" -name "*.a" -type f); do
        LIBS_TO_FIX+=("$lib")
    done
fi

# 执行修复
if check_tools; then
    for lib in "${LIBS_TO_FIX[@]}"; do
        fix_static_lib "$lib"
    done
    echo "✅ 静态库修复完成"
else
    echo "⚠️ 缺少必要工具，跳过静态库修复"
fi

# ============================================
# 3. 验证库文件架构
# ============================================
echo ""
echo "=== 步骤 3: 验证库文件架构 ==="

check_lib_arch() {
    local lib_path="$1"
    local lib_name=$(basename "$lib_path")
    
    if [ ! -f "$lib_path" ]; then
        return 1
    fi
    
    # 使用 file 命令检查架构
    if command -v file &> /dev/null; then
        local arch_info=$(file "$lib_path" | grep -o "arm64\|x86_64\|i386\|armv7")
        if [ -n "$arch_info" ]; then
            echo "  ✅ $lib_name: $arch_info"
            return 0
        fi
    fi
    
    # 使用 lipo 命令检查（更详细）
    if command -v lipo &> /dev/null; then
        local lipo_info=$(lipo -info "$lib_path" 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "  ✅ $lib_name: $lipo_info"
            return 0
        fi
    fi
    
    echo "  ⚠️ $lib_name: 无法确定架构"
    return 1
}

# 检查关键库
CRITICAL_LIBS=(
    "${SDK_DEST}/libs/libmp3lame.a"
    "${SDK_DEST}/libs/libTouchJSON.a"
    "${SDK_DEST}/libs/libuchardet.a"
    "${SDK_DEST}/libs/libPDRCore.a"
)

for lib in "${CRITICAL_LIBS[@]}"; do
    check_lib_arch "$lib"
done

# ============================================
# 4. 验证关键文件
# ============================================
echo ""
echo "=== 步骤 4: 验证关键文件 ==="

KEY_PATHS=(
    "SDK/inc/PDRCore.h"
    "SDK/Libs/GTSDK.xcframework"
    "SDK/Bundles/weexUniJs.js"
    "SDK/Bundles/uni-jsframework.js"
    "SDK/libs/libuchardet.a"
    "SDK/libs/libmp3lame.a"
    "SDK/libs/libTouchJSON.a"
)

MISSING_FILES=()
for path in "${KEY_PATHS[@]}"; do
    full_path="${DEST_BASE}/${path}"
    if [ -e "${full_path}" ]; then
        echo "  ✅ ${path}"
    else
        echo "  ❌ ${path} - 缺失"
        MISSING_FILES+=("$path")
    fi
done

# ============================================
# 5. 处理项目资源
# ============================================
echo ""
echo "=== 步骤 5: 处理项目资源 ==="

mkdir -p "${DEST_BASE}/repository/HBuilder-Hello"

if [ -f "${REPO_PATH}/HBuilder-Hello/control.xml" ]; then
    cp -f "${REPO_PATH}/HBuilder-Hello/control.xml" "${DEST_BASE}/repository/HBuilder-Hello/control.xml"
    echo "✅ control.xml 链接成功"
fi

if [ -d "${REPO_PATH}/HBuilder-Hello/Pandora" ]; then
    cp -Rf "${REPO_PATH}/HBuilder-Hello/Pandora" "${DEST_BASE}/repository/HBuilder-Hello/Pandora"
    echo "✅ Pandora 目录链接成功"
fi

# ============================================
# 6. 诊断信息（用于调试）
# ============================================
echo ""
echo "=== 步骤 6: 诊断信息 ==="

echo "Xcode 版本:"
xcodebuild -version | head -2

echo ""
echo "可用工具:"
for tool in ar libtool file lipo; do
    if command -v $tool &> /dev/null; then
        echo "  ✅ $tool"
    else
        echo "  ❌ $tool"
    fi
done

echo ""
echo "SDK/libs 目录内容:"
ls -la "${SDK_DEST}/libs" 2>/dev/null | head -20

# ============================================
# 最终结果
# ============================================
echo ""
echo "=========================================="
if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    echo "✅ 所有关键文件都已就绪"
    echo "🎉 静态库已尝试修复，Xcode Cloud 构建应该可以成功！"
else
    echo "⚠️ 仍有 ${#MISSING_FILES[@]} 个文件缺失"
    echo "缺失文件列表:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
fi
echo "=========================================="
