#!/bin/bash
#
# nodejs快速编译安装shell脚本
#
# 安装命令
# bash nodejs-install.sh new
# bash nodejs-install.sh $verions_num
# 
# 查看最新版命令
# bash nodejs-install.sh
#
# 可运行系统：
# CentOS 5+
# Ubuntu 15+
#
####################################################################################
##################################### 安装处理 #####################################
####################################################################################
# 定义安装类型
DEFINE_INSTALL_TYPE='configure'
# 加载基本处理
source basic.sh
# 初始化安装
init_install '8.0.0' "https://nodejs.org/zh-cn/download/" 'v\d+\.\d+\.\d+/'
memory_require 4 # 内存最少G
work_path_require 1 # 安装编译目录最少G
install_path_require 1 # 安装目录最少G
# ************** 相关配置 ******************
# 编译初始选项（这里的指定必需有编译项）
CONFIGURE_OPTIONS="--prefix=$INSTALL_PATH$NODEJS_VERSION"
# 编译增加项（这里的配置会随着编译版本自动生成编译项）
ADD_OPTIONS=$ARGV_options
# ************** 编译安装 ******************
# 下载nodejs包
download_software https://nodejs.org/dist/v$NODEJS_VERSION/node-v$NODEJS_VERSION.tar.gz
# 解析选项
parse_options CONFIGURE_OPTIONS $ADD_OPTIONS
# 安装依赖
echo "安装相关已知依赖"
# 在编译目录里BUILDING.md文件有说明依赖版本要求，GCC在不同的大版本中有差异
GCC_MIN_VERSION="`cat BUILDING.md|grep -oP '\`gcc\` and \`g\+\+\` (>= )?\d+(\.\d+)+ or newer'|grep -oP '\d+(\.\d+)+'`"
if [ -n "$GCC_MIN_VERSION" ];then
    if echo "$GCC_MIN_VERSION"|grep -qP '^\d+\.\d+$';then
        GCC_MIN_VERSION="$GCC_MIN_VERSION.0"
    fi
    # 获取当前安装的gcc版本
    for ITEM in `which -a gcc`; do
        GCC_CURRENT_VERSION=`$ITEM -v 2>&1|grep -oP '\d+(\.\d+){2}'|tail -n 1`
        if if_version $GCC_MIN_VERSION '<=' $GCC_CURRENT_VERSION;then
            break
        fi
    done
    if ! if_command gcc || if_version $GCC_MIN_VERSION '>' $GCC_CURRENT_VERSION;then
        run_install_shell gcc-install.sh $GCC_MIN_VERSION
        if_error '安装失败：gcc-$GCC_MIN_VERSION'
    fi
    echo "gcc-$GCC_MIN_VERSION ok"
else
    echo '获取 gcc 最低版本号失败'
fi
# 安装python3
PYTHON_MIN_VERSION=`cat BUILDING.md|grep -oP 'Python\s+3(\.\d+)+'|grep -oP '\d+(\.\d+)+'|head -n 1`
if [ -z "$PYTHON_MIN_VERSION" ];then
    # 安装python2
    PYTHON_MIN_VERSION=`cat BUILDING.md|grep -oP 'Python\s+2(\.\d+)+'|grep -oP '\d+(\.\d+)+'|head -n 1`
fi
if [ -n "$PYTHON_MIN_VERSION" ];then
    if echo "$PYTHON_MIN_VERSION"|grep -qP '^\d+\.\d+$';then
        PYTHON_MIN_VERSION="$PYTHON_MIN_VERSION.0"
    fi
    if if_version "$PYTHON_MIN_VERSION" ">=" "3.0.0"; then
        PYTHON_NAME="python3"
    elif if_version "$PYTHON_MIN_VERSION" ">=" "2.0.0"; then
        PYTHON_NAME="python2"
    else
        PYTHON_NAME="python"
    fi
    if ! if_command $PYTHON_NAME || if_version $PYTHON_MIN_VERSION '>' "`eval "$PYTHON_NAME -V 2>&1 | grep -oP '\d+(\.\d+)+'"`";then
        run_install_shell python-install.sh $PYTHON_MIN_VERSION
        if_error 'install $PYTHON_NAME fail'
    fi
    echo "python-$PYTHON_MIN_VERSION ok"
else
    echo '获取 python 最低版本号失败'
fi

# 编译安装
configure_install $CONFIGURE_OPTIONS

echo "安装成功：nodejs-$NODEJS_VERSION";
