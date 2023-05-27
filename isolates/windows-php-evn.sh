#!/bin/bash
# windows系统下php环境安装，安装依赖于git-bash工具下进行
# 安装后会自动进行相关的配置处理，安装需要手动确认操作，安装成功后即可使用
# 安装成功后会在桌面生成一个启动脚本，方便管理
# 安装工具：php、apache、nginx、mysql 四个，允许指定各自安装版本，不指定则安装最新版
#
# php-cgi与php-fpm有所区别，windows下使用php-cgi时有两种模式
#   1、在php.ini配置doc_root绝对路径，所有请求将定位到此根目录下访问，不实用多项目目录配置
#   2、在php.ini配置doc_root相对路径（比如指定为 .），所有请求将来DOCUMENT_ROOT目录进行定位，适用于多项目目录配置
#
# 输出帮助信息
show_help(){
    echo "
windows系统git-bash内PHP环境安装工具

命令：
    $(basename "${BASH_SOURCE[0]}") install-path [option ...]

参数：
    install-path        安装目录，不指定则只取最新版本号

选项：
    --php version       指定php安装版本号，默认最新版
    --apache version    指定apache安装版本号，默认最新版（不建议指定）
                        不指定脚本会自动获取php使用相同的VC编译版本进行匹配下载
                        如果PHP与apache没有匹配的VC版本时则需要指定apache编译VC号
    --apache-vc version 指定apache编译使用的VC版本号
                        当apache不匹配的PHP编译VC版本时可指定
                        指定后如果PHP的VC与apache的VC不相同则只能使用cgi模式
    --nginx version     指定nginx安装版本号，默认最新版
    --mysql version     指定mysql安装版本号，默认最新版
    -h, -?              显示帮助信息

说明：
    脚本直接获取软件官网信息进行下载，保证各包不存在内核加壳或修改
    下载安装速度取决于当前的网络，也可以手动将下载的包放在当前目录下
    安装完成后会进行基本配置修改，保证后面可正常使用，并且在桌面生成管理脚本工具
"
    exit 0
}

# 输出错误信息并终止运行
show_error(){
    echo "[error] $1" >&2
    exit 1
}
# 判断上个命令是否执行错误，错误就终止执行并输出错误说明
if_error(){
    if [ $? != 0 ];then
        show_error "$1"
    fi
}
# 判断指定参数是否为版本号
is_version(){
    if ! [[ $1 =~ ^[0-9]{1,3}(\.[0-9]{1,3}){2}$ ]];then
        show_error "请指定正确版本号：$1"
    fi
}
# 比较版本号大小
if_version(){
    local RESULT VERSIONS=`echo -e "$1\n$3"|sort -Vrb`
    case "$2" in
        "==")
            RESULT=`echo -e "$VERSIONS"|uniq|wc -l|grep 1`
        ;;
        "!=")
            RESULT=`echo -e "$VERSIONS"|uniq|wc -l|grep 2`
        ;;
        ">")
            RESULT=`echo -e "$VERSIONS"|uniq -u|head -n 1|grep "$1"`
        ;;
        ">=")
            RESULT=`echo -e "$VERSIONS"|uniq|head -n 1|grep "$1"`
        ;;
        "<")
            RESULT=`echo -e "$VERSIONS"|uniq -u|tail -n 1|grep "$1"`
        ;;
        "<=")
            RESULT=`echo -e "$VERSIONS"|uniq|tail -n 1|grep "$1"`
        ;;
        *)
            show_error "未知版本判断条件：$2"
        ;;
    esac
    if [ -n "$RESULT" ]; then
        return 0;
    fi
    return 1;
}
# 必需在windows系统下运行此脚本
if ! uname|grep -qP 'MINGW(64|32)' || ! echo $BASH|grep -q '^/usr/bin/bash$';then
    show_error "windows系统git-bash环境专用脚本"
fi
# 添加环境变量，直接添加到windows系统环境变量配置中
# add_path(){
#     # 判断目录是否存在
#     if [ -z "$1" ] || [ ! -d $1 ];then
#         show_error "不存在目录 $1 ，不可添加到环境目录中"
#     fi
#     local TEMP_PATH ADD_PATH=$(cd $1;pwd -W)
#     while read TEMP_PATH;do
#         if [ "$1" = "$TEMP_PATH" ];then
#             echo "[warn] $1 目录已经配置windows系统环境变量，跳过配置"
#             return
#         fi
#     done <<EOF
# echo "$PATH"|grep -oP '[^:]+'
# EOF
#     cmd <<EOF
# SETX PATH %PATH%;$ADD_PATH
# EOF
# }
for((INDEX=1; INDEX<=$#; INDEX++));do
    case "${@:$INDEX:1}" in
        -h|-\?)
            show_help
        ;;
        --php)
            PHP_VERSION=${@:((++INDEX)):1}
            is_version "$PHP_VERSION"
            if if_version "$PHP_VERSION" '<' '7.0.0';then
                show_error "php最小安装版本：7.0.0"
            fi
        ;;
        --apache)
            APACHE_VERSION=${@:((++INDEX)):1}
            is_version "$APACHE_VERSION"
            if if_version "$APACHE_VERSION" '<' '2.0.50';then
                show_error "apache最小安装版本：2.0.50"
            fi
        ;;
        --apache-vc)
            APACHE_VC_VERSION=${@:((++INDEX)):1}
            if [[ "$APACHE_VC_VERSION" =~ ^[1-9][0-9]$ ]];then
                show_error "apache编译VC版本号错误，必需是两位数字"
            fi
        ;;
        --nginx)
            NGINX_VERSION=${@:((++INDEX)):1}
            is_version "$NGINX_VERSION"
            if if_version "$NGINX_VERSION" '<' '1.0.0';then
                show_error "nginx最小安装版本：1.0.0"
            fi
        ;;
        --mysql)
            MYSQL_VERSION=${@:((++INDEX)):1}
            is_version "$MYSQL_VERSION"
            if if_version "$MYSQL_VERSION" '<' '5.0.0';then
                show_error "mysql最小安装版本：5.0.0"
            fi
        ;;
        *)
            INSTALL_PATH=${@:$INDEX:1}
            if [ ! -d "$INSTALL_PATH" ];then
                echo "[info] 安装目录不存在，立即创建目录 $INSTALL_PATH"
                mkdir -p "$INSTALL_PATH"
                if_error "创建目录 $INSTALL_PATH 失败"
            fi
            INSTALL_PATH=$(cd ${@:$INDEX:1};pwd)
        ;;
    esac
done
echo "[info] 如果长时间没有反应建议 Ctrl + C 终止脚本，再运行尝试"
# 运行CURL
run_curl(){
    if ! curl -LkN --max-time 1800 --connect-timeout 1800 $@ 2>/dev/null;then
        echo '' >&2
        show_error "请确认连接 ${@:$#} 是否能正常访问！"
    fi
}
# 获取最新版本号
get_version(){
    local TEMP_VERSION=$(run_curl "$2"|grep -oP "$3"|sort -Vrb|head -n 1|grep -oP "\d+(\.\d+){2}")
    if [ -z "$TEMP_VERSION" ];then
        show_error "获取版本号信息失败"
    else
        echo $TEMP_VERSION
    fi
    eval "$1=\$TEMP_VERSION"
}
# 获取系统位数
if uname|grep -qP 'MINGW(64)';then
    OS_BIT=64
else
    OS_BIT=86
fi
# 获取新版本
if [ -z "$PHP_VERSION" ];then
    echo -n '[info] 获取PHP最新版本号：'
    get_version PHP_VERSION 'https://www.php.net/supported-versions.php' '#v\d+\.\d+\.\d+'
fi
# 获取下载包名
# PHP_FILE='php-8.1.9-Win32-vs16-x64.zip'
echo -n '[info] 提取PHP编译使用VC版本号：'
PHP_DOWNLOAD_URL='https://windows.php.net/downloads/releases/'
PHP_FILE=$(run_curl $PHP_DOWNLOAD_URL|grep -oP "php-$PHP_VERSION-Win32-vs\d+-x$OS_BIT\.zip"|head -n 1)
if [ -z "$PHP_FILE" ];then
    PHP_DOWNLOAD_URL=${PHP_DOWNLOAD_URL}archives/
    PHP_FILE=$(run_curl $PHP_DOWNLOAD_URL|grep -oP "php-$PHP_VERSION-Win32-vs\d+-x$OS_BIT\.zip"|head -n 1)
fi
if_error "php-$PHP_VERSION 包不存在无法下载"
if [ $OS_BIT = '86' ];then
    OS_BIT=32
fi
# 提取VC信息
if [ -n "$APACHE_VC_VERSION" ];then
    VC_VERSION=$APACHE_VC_VERSION
else
    VC_VERSION=$(echo "$PHP_FILE"|grep -oP 'vs\d+-'|grep -oP '\d+')
fi
echo "$VC_VERSION"
if (( VC_VERSION >= 16 ));then
    VC_NAME=VS$VC_VERSION
else
    VC_NAME=VC$VC_VERSION
fi
# 提取对应的版本
if [ -z "$APACHE_VERSION" ];then
    echo -n '[info] 获取apache最新版本号：'
    get_version APACHE_VERSION "https://www.apachelounge.com/download/$VC_NAME/" "(apache|httpd)-\d+\.\d+\.\d+-win$OS_BIT-$VC_NAME\.zip"
elif [ -z "$APACHE_VC_VERSION" ];then
    run_curl "https://www.apachelounge.com/download/$VC_NAME/"|grep -oP "(apache|httpd)-$APACHE_VERSION-win$OS_BIT-$VC_NAME\.zip" >/dev/null
    if_error "找不到匹配的apache版本，请指定 --apache-vc 编译的VC版本号"
fi
if [ -z "$NGINX_VERSION" ];then
    echo -n '[info] 获取nginx最新版本号：'
    get_version NGINX_VERSION 'http://nginx.org/en/download.html' 'Stable version.*?nginx-\d+\.\d+\.\d+\.tar\.gz'
fi
if [ -z "$MYSQL_VERSION" ];then
    echo -n '[info] 获取mysql最新版本号：'
    get_version MYSQL_VERSION 'https://dev.mysql.com/downloads/mysql/' 'mysql-\d+\.\d+\.\d+'
fi

# 没有指定安装目录
if [ -z "$INSTALL_PATH" ];then
    exit 0
fi

if ! [[ "$INSTALL_PATH" =~ ^([a-zA-Z0-9]|/|-|_|\.)+$ ]];then
    show_error "安装目录不可包含[a-z0-9/-_.]以外的字符，否则可能导致安装后的服务不可用，请确认安装目录：$INSTALL_PATH"
fi

cd "$INSTALL_PATH"

# 下载安装包
download_file(){
    local FILE_NAME=$(basename "$1")
    if [ ! -e "$FILE_NAME" ];then
        echo "[info] 下载：$FILE_NAME [下载中...]"
        if (run_curl -O -o "$FILE_NAME" "$1" 2>/dev/null);then
            rm -f "$FILE_NAME"
            run_curl --http1.1 -O -o "$FILE_NAME" "$1"
        fi
        if [ $? != 0 ];then
            rm -f "$FILE_NAME"
            show_error "下载 $FILE_NAME 失败，下载地址：$1"
        fi
    else
        echo "[info] 下载：$FILE_NAME [已下载]"
    fi
    if [ ! -d ${3:-$2} ];then
        echo "[info] 解压：$FILE_NAME [解压中...]"
        unzip "$FILE_NAME" -d $2 >/dev/null 2>/dev/null
        if [ $? != 0 ];then
            rm -f "$FILE_NAME"
            show_error "解压 $FILE_NAME 失败，下载地址：$1"
        fi
        # 目录迁移
        local DEC_PATH
        while [ $(find $2 -maxdepth 1 -type d|grep -P '/.+'|wc -l) = 1 ];do
            DEC_PATH=$(find $2 -maxdepth 1 -type d|grep -P '/.+')
            mv $DEC_PATH ./$2-new
            rm -rf $2
            mv ./$2-new ./$2
        done
    else
        echo "[info] 解压：$FILE_NAME [已解压]"
    fi
}

php_init(){
    echo "PHP配置处理"
    [ -d "$INSTALL_PATH/php-$PHP_VERSION" ] || show_error "php-$PHP_VERSION 下载解压失败，安装终止"
    cd "$INSTALL_PATH/php-$PHP_VERSION"
    if [ ! -e ./php.ini ];then
        cp php.ini-development php.ini
        if_error "php.ini 配置文件丢失，无法进行配置"
    fi
    local EXTENSION_NAME
    # 开启扩展
    for EXTENSION_NAME in bz2 curl gd gettext gmp mbstring openssl pdo pdo_mysql sockets;do
        if [ -e ./ext/php_${EXTENSION_NAME}.dll ];then
            sed -i -r "s/^\s*;\s*(extension=${EXTENSION_NAME})/\1/" php.ini
        fi
    done
    # 开启cgi
    sed -i -r "s/^\s*;\s*(cgi.fix_pathinfo=1)/\1/" php.ini
    # 扩展目录
    sed -i -r 's/^\s*;?\s*(extension_dir\s*=)\s*"ext"\s*/\1 "ext"/' php.ini
    # 访问目录范围限制配置
    # 配置doc_root目录
    sed -i -r "s,^\s*;?\s*(doc_root\s*=).*,\1 .," php.ini
    sed -i -r "s,^\s*;?\s*(open_basedir\s*=).*,\1 .," php.ini
    # 配置user_dir目录，此目录为 /home/ 相下进行的
    # sed -i -r "s,^\s*;?\s*(user_dir\s*=).*,\1 ./," php.ini
    ln -svf $INSTALL_PATH/php-$PHP_VERSION/php.exe /usr/bin/php
    # 安装composer
    echo "[info] 下载安装 composer"
    cat > composer-installer.php <<EOF
<?php
copy('https://getcomposer.org/installer', 'composer-setup.php');
if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') {
    require './composer-setup.php';
} else {
    echo "composer 安装文件校验失败\n";
}
unlink('composer-setup.php');
EOF
    ./php composer-installer.php
    if [ -e ./composer.phar ];then
        ln -svf $INSTALL_PATH/php-$PHP_VERSION/composer.phar /usr/bin/composer
        echo "[info] composer 安装成功";
    else
        echo "[warn] composer 安装失败";
    fi
    rm -f composer-installer.php
}
apache_init(){
    echo "apache配置处理"
    [ -d "$INSTALL_PATH/httpd-$APACHE_VERSION" ] || show_error "apache-$APACHE_VERSION 下载解压失败，安装终止"
    cd "$INSTALL_PATH/httpd-$APACHE_VERSION"
    # 已经配置过的就跳过
    if grep -qP '^LoadModule\s+vhost_alias_module\s+' ./conf/httpd.conf;then
        return
    fi
    # 通用配置开启
    # 开启rewrite模块
    sed -i -r 's/\s*#\s*(LoadModule\s+rewrite_module\s+.*)/\1/' ./conf/httpd.conf
    # 开启access_compat_module模块，否则无法使用Order命令
    sed -i -r 's/\s*#\s*(LoadModule\s+access_compat_module\s+.*)/\1/' ./conf/httpd.conf
    # 开启vhost_alias模块
    sed -i -r 's/\s*#\s*(LoadModule\s+vhost_alias_module\s+.*)/\1/' ./conf/httpd.conf
    # 打开vhosts
    sed -i -r 's,\s*#\s*(Include\s+conf/extra/httpd-vhosts.conf.*),\1,' ./conf/httpd.conf
    # 注释配置
    if [ -e conf/extra/httpd-vhosts.conf ];then
        sed -i -r 's/^(\s*[^#]+)/# \1/' ./conf/extra/httpd-vhosts.conf
    fi
    # 修改SRVROOT或ServerRoot
    local APACHE_INSTALL_PATH=$(pwd|sed -r 's,^/([a-z]+)/,\1:/,')
    if ! sed -i -r "s,\s*(Define\s+SRVROOT)\s+.*,\1 \"$APACHE_INSTALL_PATH\"," ./conf/httpd.conf;then
        sed -i -r "s,\s*(ServerRoot)\s+.*,\1 \"$APACHE_INSTALL_PATH\"," ./conf/httpd.conf
    fi
    # 配置ServerName，否则启动会有警告
    sed -i -r 's/\s*#\s*(ServerName\s+)[a-zA-Z0-9_\.:]+\s*$/\1 localhost/' ./conf/httpd.conf
    # 配置与PHP连接
    if [ -z "$APACHE_VC_VERSION" -o "$APACHE_VC_VERSION" = "$VC_VERSION" ];then
        # 配置PHP模块，所有目录的反斜线应转换为正斜线
        local APACHE_MODULE_VERSION=${APACHE_VERSION%.*}
        local PHP_MODULE_PATH=$(find "$INSTALL_PATH/php-$PHP_VERSION" -name "*${APACHE_MODULE_VERSION//./_}.dll")
        if [ $? = 0 ];then
            local PHP_INSTALL_PATH=$(cd $INSTALL_PATH/php-$PHP_VERSION;pwd|sed -r 's,^/([a-z]+)/,\1:/,')
            cat >> ./conf/httpd.conf <<EOF

LoadModule php_module "$PHP_INSTALL_PATH/$(basename $PHP_MODULE_PATH)"
<FilesMatch \.php$>
    SetHandler application/x-httpd-php
</FilesMatch>
# 配置 php.ini 的路径
PHPIniDir "$PHP_INSTALL_PATH"

EOF
            cat >> ./conf/extra/httpd-vhosts.conf <<EOF
# 示例模板
<VirtualHost _default_:80>
    ServerName localhost
    DocumentRoot "$DOC_ROOT"
    <Directory "./">
        Options -Indexes -FollowSymLinks +ExecCGI
        AllowOverride All
        Order allow,deny
        Allow from all
        Require all granted
    </Directory>
</VirtualHost>
EOF
            return
        fi
    fi
    # 配置cgi模式
    # 开启gcgi代理模块
    sed -i -r 's/\s*#\s*(LoadModule\s+proxy_module\s+.*)/\1/' ./conf/httpd.conf
    sed -i -r 's/\s*#\s*(LoadModule\s+proxy_fcgi_module\s+.*)/\1/' ./conf/httpd.conf
    # 配置代理
    cat >> ./conf/extra/httpd-vhosts.conf <<EOF
# 示例模板
<VirtualHost _default_:80>
    ServerName localhost
    DocumentRoot "$DOC_ROOT/localhost/public"
    ProxyPass "/" "fcgi://127.0.0.1:9000/"
</VirtualHost>
EOF
}
nginx_init(){
    echo "nginx配置处理"
    [ -d "$INSTALL_PATH/nginx-$NGINX_VERSION" ] || show_error "nginx-$NGINX_VERSION 下载解压失败，安装终止"
    cd "$INSTALL_PATH/nginx-$NGINX_VERSION/conf"
    if [ ! -d ./vhosts ];then
        mkdir ./vhosts
        LAST_NUM=$(grep -n '^}' nginx.conf|tail -n 1|grep -oP '\d+')
        sed -i "${LAST_NUM}i include vhosts/*.conf;" nginx.conf
        cd ./vhosts
        cat > ssl <<conf
# 此文件为https证书相关配置模板，正常使用时请复制此模板并修改证书地址和监听端口，并修改文件为对应域名名为便识别，比如 www.api.com.ssl
# 注意：ssl连接握手前还不知道具体域名，当有请求时先使用默认的证书再逐个配置，所以过多个不同域名（主域名不同）的证书建议使用不同的IP或服务器分开

listen       443 ssl;
# 常规https配置，此配置不建议开启
# ssl                  on;

# 配置会话缓存，1m大概4000个会话
ssl_session_cache    shared:SSL:1m;
ssl_session_timeout  5m;

# ssl_ciphers  HIGH:!aNULL:!MD5;
# ssl_prefer_server_ciphers  on;
# 强制必需使用https
if (\$scheme = "http") {
    return 301 https://\$host\$request_uri;
}

# 发送HSTS头信息，强制浏览器使用https协议发送数据
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
conf
        cat > host.cert <<conf
# 注意修改证书名
# 从1.15.9版本开始且OpenSSL-1.0.2以上证书文件名可以使用变量（使用变量会导致每次请求重新加载证书，会额外增加开销）
ssl_certificate      certs/ssl.pem;
ssl_certificate_key  certs/ssl.key;
conf
        cat > websocket <<conf
# 此文件为共用文件，用于其它 server 块引用
# 代理websocket连接，建议使用复制文件再重命名方便多个 websocket 代理并存
# 引用后需要视需求修改：匹配地址、代理websocket地址
location /websocket {
    # 去掉路径前缀，只保存小括号匹配的路径信息（包括GET参数），不去掉将原路径代理访问
    rewrite ^[^/]+/(.*) /\$1 break;

    # 代理的websocket地址
    proxy_pass http://127.0.0.1:800;
    
    # 以下常规配置
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
}
conf
        cat > php <<conf
# 此文件为共用文件，用于其它 server 块引用
# PHP配置
if (!-e \$request_filename) {
    rewrite  ^/(.*)$ /index.php?s=\$1  last;
    break;
}

# 代理 http://127.0.0.1:80 地址
#location ~ \.php$ {
#    proxy_pass   http://127.0.0.1;
#}

# fastcgi接口监听 127.0.0.1:9000
# 转到php-fpm上
location ~ \.php\$ {
    fastcgi_pass   127.0.0.1:9000;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
    include        fastcgi_params;
}
# 使用静态配置
include vhosts/static;
conf
        cat > static <<conf
# 此文件为共用文件，用于其它 server 块引用
# 常规静态配置
location = / {
    index index.html index.htm index.php;
}
#error_page  404              /404.html;

# 去掉响应头服务器标识
server_tokens off;

# 重定向错误页面
# error_page   500 502 503 504  /50x.html;
# 指定错误页面根目录，也可以不指定
# location = /50x.html {
#     root   html;
# }

# 静态可访问后缀
location ~* ^.+\.(jpg|jpeg|png|css|js|gif|html|htm|xls)$ {
    access_log  off;
    expires     30d;
}
conf
        cat > static.conf.default <<conf
# 此文件为静态服务配置模板
# 使用时建议复制文件并去掉文件名后缀 .default
# 开启后视需求修改：域名、ssl、根目录、独立日志
server {
    # 配置端口号
    listen 80;

    # 配置https
    # include vhosts/ssl;
    # 指定使用的证书
    # include vhosts/host.cert;

    # 配置访问域名，多个空格隔开
    server_name  localhost;

    # 配置根目录
    root $DOC_ROOT/localhost/dist;

    # 独立日志文件，方便查看
    access_log logs/\$host-access.log

    # 引用静态文件基础配置
    include vhosts/static;
}
conf
        cat > php.conf.default <<conf
# 此文件为PHP服务配置模板
# 使用时建议复制文件并去掉文件名后缀 .default
# 开启后视需求修改：域名、ssl、根目录、独立日志
server {
    # 配置http端口号
    listen 80;

    # 配置https
    # include vhosts/ssl;
    # 指定使用的证书
    # include vhosts/host.cert;

    # 配置访问域名，多个空格隔开
    server_name localhost;

    # 配置根目录
    root $DOC_ROOT/localhost/public;

    # 独立日志文件，方便查看
    access_log logs/\$host-access.log;

    # 检查请求实体大小，超出返回413状态码，为0则不检查。
    # client_max_body_size 10m;

    # 引用PHP基础配置
    include vhosts/php;
}
conf
        cat > deny.other.conf.default <<conf
# 此文件为拒绝IP直接访问或未知域名配置，很多漏洞就是通过IP扫描，屏蔽直接IP访问减少部分安全事件泄露和扫描次数
# 使用时直接去掉文件名后缀 .default 即可，此配置不影响正常域名访问，仅限制没配置的域名地址不可访问
# 注意：同一监听IP地址和端口号只允许一个服务配置为 default_server
server {
    # 配置http端口号
    listen 80 default_server;

    # 配置https端口号
    listen 443 default_server;

    # 配置无效访问域名
    # 此域名配置会在其它域名匹配不上时使用
    server_name "";

    # 非标准代码444直接关闭连接，即终端无任何正常响应数据
    return 444;
}
conf
    fi
    
}
mysql_init(){
    echo "mysql配置处理"
    [ -d "$INSTALL_PATH/mysql-$MYSQL_VERSION" ] || show_error "mysql-$MYSQL_VERSION 下载解压失败，安装终止"
    cd "$INSTALL_PATH/mysql-$MYSQL_VERSION"
    if [ ! -d ./database/mysql ];then
        echo '[info] 初始化数据库'
        if [ -e "./scripts/mysql_install_db" ];then
            ./scripts/mysql_install_db --basedir=./ --datadir=./database
        else
            ./bin/mysqld --initialize --basedir=./ --datadir=./database
        fi
    fi
    if [ ! -e ./my.ini ];then
        # 版本专用配置
        if if_version "$MYSQL_VERSION" "<" "8.0.26"; then
            # 8.0.26之前
            local LOG_UPDATES='log_slave_updates'
        else
            # 8.0.26起改名
            local LOG_UPDATES='log_replica_updates'
        fi
        cat > ./my.ini <<MY_CONF
# mysql配置文件，更多可查看官方文档
# https://dev.mysql.com/doc/refman/8.0/en/server-system-variables.html

[mysqld]
# 需要开启的增加将前面的注释符号 # 去掉即可
# 此文件是安装脚本自动生成的，并会自动增加一些常规配置

# 数据库保存目录
datadir=database

# socket连接文件
socket=./mysql.sock

# 错误目录路径
log-error=./mysqld.log

# 进程PID保证文件路径
pid-file=./mysqld.pid

# 关闭加载本地文件，加载本地文件可能存在安全隐患，无特殊要求不建议开启
local-infile=0

# 启动用户
# user=mysql

# SQL处理模式配置，不同版本有对应默认模式
# MySQL的SQL模式不同版本会有些变化，以下部分弃用模式未列出。
# 默认均为严格模式，在生产环境建议使用严格模式，兼容模式容易造成数据写入丢失或转换。
# 写数据时注意：数据类型、字符集、值合法性、值范围等
#
# MySQL8.0默认：ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION。
# MySQL5.7默认：ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION。
#
# 组合模式值：
#   ANSI
#       相当于： REAL_AS_FLOAT, PIPES_AS_CONCAT, ANSI_QUOTES, IGNORE_SPACE, ONLY_FULL_GROUP_BY（MySQL5.7.5开始增加）
#
#   TRADITIONAL
#       MySQL8.0相当于：STRICT_TRANS_TABLES, STRICT_ALL_TABLES, NO_ZERO_IN_DATE, NO_ZERO_DATE, ERROR_FOR_DIVISION_BY_ZERO, NO_ENGINE_SUBSTITUTION
#
# 标准模式值：
#   ALLOW_INVALID_DATES
#       不要对日期进行全面检查，仅验证月份和日期是否在范围内（比如月份只有1~12，日期段是每月不尽相同），
#       此模式针对date和datetime类型字段，验证失败会变成：0000-00-00，严格模式产生错误失败写入。
#
#   ANSI_QUOTES
#       将双引号解析为标识符引号，即双引号功能类似反引号。
#
#   ERROR_FOR_DIVISION_BY_ZERO
#       除0报错（一般程序除数为0均异常）。mysql除0操作将等于NULL。此模式已经弃用。
#       如果不指定此选项不会产生警告，指定会产生警告如果还启用严格模式将报错。在SQL中还可以指定IGNORE关键字忽略。
#
#   HIGH_NOT_PRECEDENCE
#       提升not运算优先级，默认not运算优先级不尽相同，指定后not将先于其它运算。
#
#   IGNORE_SPACE
#       允许内置函数名与左括号之间有空格（默认内置函数使用时函数后与左括号不能间隔）。
#       启用后内置函数将被视为保留字。自定义的函数或存储允许有空格且不受此模式影响。
#
#   NO_AUTO_CREATE_USER
#       禁止GRANT创建空密码账号。此模式已经弃用
#
#   NO_AUTO_VALUE_ON_ZERO
#       此模式影响指定auto_increment字段处理。当指定auto_increment字段写入0后，MYSQL通常会在遇到0后生成新序列号，启用后禁止自动生成新序列号。
#
#   NO_BACKSLASH_ESCAPES
#       禁用反斜杠字符作为字符串和标识符中的转义字符，指定后反斜杠将视为普通字符串处理，即没有转义字符。
#
#   NO_DIR_IN_CREATE
#       创建表时，忽略所有INDEX DIRECTORY和DATA DIRECTORY指令。此选项在副本服务器上很有用。
#
#   NO_ENGINE_SUBSTITUTION
#       当使用CREATE TABLE或ALTER TABLE之类的语句时指定禁用或未编译的存储引擎时，自动替换为默认存储引擎。不指定SQL中不可用的存储引擎将报错。
#
#   NO_UNSIGNED_SUBTRACTION
#       无符号字段允许写入有符号数值，当为负数时会转为0并写入。不指定将报错。
#
#   NO_ZERO_DATE
#       允许0000-00-00作为有效日期，从8.0开始弃用
#
#   NO_ZERO_IN_DATE
#       允许日期在年的部分是非零但当月或日部分可为0，比如：2010-00-01或2010-01-00，不会自动转为0000-00-00。从8.0开始弃用
#
#   ONLY_FULL_GROUP_BY
#       禁止
#
#   PAD_CHAR_TO_FULL_LENGTH
#       禁止查询时去掉char类型字段后面空格，char定长字段写入长度未满时后面是会补空格填满。从8.0.13开始弃用
#       默认会自动去掉后面的空格字符，指定此参数后保留后面的空格字符并返回.
#
#   PIPES_AS_CONCAT
#       将||视为字符串连接符（类似使用concat函数）而不是 or 运算符。
#
#   REAL_AS_FLOAT
#       将REAL作为FLOAT别名，不指定则REAL是DOUBLE的别名。
#
#   STRICT_ALL_TABLES
#       为所有存储引擎启用严格的SQL模式。无效的数据值被拒绝执行。
#
#   STRICT_TRANS_TABLES
#       为事务存储引擎启用严格的SQL模式，并在可能的情况下为非事务存储引擎启用
#
#   TIME_TRUNCATE_FRACTIONAL
#       当写入TIME、DATE、TIMESTAMP类型字段时有小数秒且小数位数超过限定位数时使用截断而不是四舍五入。默认不指定时是四舍五入。截断可以理解为字符串截取。从8.0起增加。
#
# 兼容模式
# sql_mode=NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
# 严格模式
sql_mode=ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO

# 配置慢查询
# log-slow-queries=
# long_query_time=1s

#重置密码专用，重置密码后必需注释并重启服务
# 8.0及以上版本修改SQL（先去掉密码然后再重启修改密码）：update mysql.user set authentication_string='' where user='root';
# 8.0以下版本修改SQL：update mysql.user set password=password('root') where user='root';
# skip-grant-tables

# 总最大连接数，过小会报Too many connections
max_connections=16384

# 单个用户最大连接数据，为0不限制，默认为0
# max_user_connections=0

# 配置线程数，线程数过多会在并发时产生过多的线程切换，导致性能不升反降
# 可动态SQL修改
# innodb_thread_concurrency=1

# mysql 缓冲区配置项很多，具体可以SQL：show global variables like '%buffer%';

# 配置缓冲区容量，如果独享服务器可配置到物理内存的80%左右，如果是共享可配置在50%~70%左右。
# 建议超过1G以上，默认是128M，需要配置整数，最大值=2**(CPU位数64或32)-1。可动态SQL修改
# innodb_buffer_pool_size=128M

# 普通索引、范围索引或不使用索引联接缓冲区大小，最大4G-1
# 可以动态配置，默认256KB
# join_buffer_size=128M

# 设置必需排序缓冲区大小，最大4G-1
# 可以动态配置，默认256KB
# sort_buffer_size=2M

# 使用加密连接，复制时源和副本均需要配置
# 证书颁发机构 (CA) 证书文件的路径名，即根证书
# ssl_ca=cacert.pem

# 服务器公钥证书文件的路径名，通信公钥（服务器和客户端）
# ssl_cert=server-cert.pem

# 服务器私钥文件的路径名，通信私钥（仅服务器）
# ssl_key=server-key.pem

# 开启二进制日志
log-bin=mysql-bin-sync

# 配置自动删除几天前历史二进制日志
# 为0即禁止自动删除，此配置早期不建议使用
# expire_logs_days=7

# 配置自动删除几秒前历史二进制日志。默认2592000，即30天前。
# 为0即禁止自动删除，此配置为新增并建议使用
# 二进制日志可用于复制和恢复等操作，但占用空间
binlog_expire_logs_seconds=2592000

# 配置主从唯一ID
# server-id=1

# 日志在每次事务提交时写入并刷新到磁盘
innodb_flush_log_at_trx_commit=1

# 启用事务同步组数，多组同步可以减少同步到磁盘次数来提升性能，但异常时也容易丢失未同步数据
# 最安全的是每组同步一次（每组可以理解为每个事务），为0即关闭
sync_binlog=1

# 二进制格式，已经指定后不建议修改
# ROW       按每行动态记录，复制安全可靠，占用空间大，默认格式
# STATEMENT 按语句记录，复制对不确定性SQL产生复制警告，占用空间小
# MIXED     按行或语句记录，影响语句异常的按行记录否则按语句记录，占用空间适中，且安全可靠
#           混合模式使用临时表在8.0以前会强制不安全使用行记录直到临时表删除
#           innodb支持语句记录事务等级必需是可重读和串行
binlog_format=ROW

# 二进制日志记录模式
# full      记录所有列数据，即使有的列未修改，默认选项
# minimal   只记录要修改的列，可以减少二进制日志体量
# noblob    记录所有列数据，但blod或text之类列未修改不记录，其它列未修改仍记录
binlog_row_image=minimal

# 作为从服务器时的中继日志
# 中继日志是副本复制时创建产生，与二进制日志格式一样。
# 中继日志是当复制I/O线程、刷新日志、文件过大时会创建。创建规则与二进制日志类似。
# 中继文件会在复制完成后自动删除
#relay_log=school-relay-bin

#可以被复制的库。二进制需要同步的数据库名
#binlog-do-db=

#不可以被从服务器复制的库
binlog-ignore-db=mysql

# 多主复制时需要配置自增步进值，防止多主产生同时的自增值
auto_increment_increment=1

# 多主复制时需要配置自增开始值，避开自增值相同
auto_increment_offset=1

# 版本要求mysql5.7+ 设置数据提交延时长度，默认为0无延时
# 有延时会减少提交次数，减少同步队列数（微秒单位）,即集中写二进制日志到磁盘
# 增加延时提交在服务器异常时可能导致数据丢失
#binlog_group_commit_sync_delay=10

# 并行复制，默认为DATABASE（MYSQL5.6兼容值），版本要求MYSQL5.6+
#slave_parallel_type=LOGICAL_CLOCK
# 并行复制线程数
#slave_parallel_workers=$TOTAL_THREAD_NUM

# 启用自动中继日志恢复
relay_log_recovery=ON

# 复制的二进制数据写入到自己的二进制日志中，默认：ON
# 当使用链复制时使用此项，比如：C复制B，而B复制A
# 当需要切换为主数据库时建议关闭，这样就可以保证切换后的二进制日志不会混合
# 组复制时需要开启
# $LOG_UPDATES=OFF

[client]
# 使用加密连接，复制时副本需要配置
# 要使用加密复制时，配置SQL需要增加：MASTER_SSL=1 或 SOURCE_SSL=1
# 例如：CHANGE MASTER TO ... MASTER_SSL=1
# 例如：CHANGE REPLICATION SOURCE TO ... SOURCE_SSL=1
# 证书颁发机构 (CA) 证书文件的路径名，即根证书
# ssl_ca=cacert.pem

# 服务器公钥证书文件的路径名，通信公钥（服务器和客户端）
# ssl_cert=client-cert.pem

# 服务器私钥文件的路径名，通信私钥（仅服务器）
# ssl_key=client-key.pem

# 8.0以上，默认的字符集是utf8mb4，php7.0及以前的连接会报未知字符集错
# character-set-server=utf8
MY_CONF
    fi
}

echo '[info] 下载各软件包'
# PHP下载
download_file "$PHP_DOWNLOAD_URL$PHP_FILE" "php-$PHP_VERSION" &
# apache下载
download_file https://www.apachelounge.com/download/$VC_NAME/binaries/httpd-$APACHE_VERSION-win$OS_BIT-$VC_NAME.zip "httpd-$APACHE_VERSION" &
# nginx下载
download_file http://nginx.org/download/nginx-$NGINX_VERSION.zip "nginx-$NGINX_VERSION" &
# mysql下载
download_file https://dev.mysql.com/get/Downloads/mysql-${MYSQL_VERSION%.*}/mysql-$MYSQL_VERSION-winx64.zip "mysql-$MYSQL_VERSION" &

# 等待下载完
echo '[wait] 等待下载解压完成'
wait
# 创建web目录
if [ ! -d ./www ];then
    mkdir ./www
    # 生成测试文件
    cat >> ./www/index.php <<EOF
<?php

phpinfo();

EOF
fi
# 根目录
DOC_ROOT=$(cd ./www;pwd|sed -r 's,^/([a-z]+)/,\1:/,')

exit

php_init
apache_init
nginx_init
mysql_init

echo "[info] 生成启动脚本文件"
cd "$INSTALL_PATH"

cat > run.sh <<EOF
#!/bin/bash
APM_HAS_PHP=$([ -z "$APACHE_VC_VERSION" -o "$APACHE_VC_VERSION" = "$VC_VERSION" ];echo $?)
has_run(){
    ps ax|grep \$1|grep -q "/\$1"
}
stop_run(){
    if has_run \$1;then
        kill \$(ps ax|grep \$1|grep "/\$1"|awk '{print \$1}')
        if [ \$? = 0 ];then
            echo "[info] 已停止 \$1"
        else
            echo "[warn] 无法停止 \$1"
        fi
    else
        echo "[warn] 未找到启动进程，无法停止 \$1"
    fi
}
start_php_cgi(){
    # 启动PHP
    if has_run php-cgi;then
        echo "[warn] php-cgi已经在运行中";
    else
        nohup ./php-$PHP_VERSION/php-cgi.exe -b 127.0.0.1:9000 2>/dev/null >/dev/null &
        echo "[info] php-cgi已运行";
    fi
}
start_nginx(){
    # 启动nginx，需要指定目前前缀或者在nginx安装目录中启动，否则报错 failed (3: The system cannot find the path specified)
    if has_run nginx;then
        echo "[warn] nginx已经在运行中";
    else
        nohup ./nginx-$NGINX_VERSION/nginx.exe -p ./nginx-$NGINX_VERSION 2>/dev/null >/dev/null &
        echo "[info] nginx已运行";
    fi
}
start_httpd(){
    # 启动apache
    if has_run httpd;then
        echo "[warn] apache已经在运行中";
    else
        nohup ./httpd-$APACHE_VERSION/bin/httpd.exe 2>/dev/null >/dev/null &
        echo "[info] apache已运行";
    fi
}
start_mysqld(){
    # 启动mysql
    if has_run mysqld;then
        echo "[warn] mysql已经在运行中";
    else
        nohup ./mysql-$MYSQL_VERSION/bin/mysqld.exe 2>/dev/null >/dev/null &
        echo "[info] mysql已运行";
    fi
}
start_apm(){
    start_httpd
    if [ "\$APM_HAS_PHP" = 1 ];then
        start_php_cgi
    fi
    start_mysqld
}
stop_apm(){
    stop_run httpd
    if [ "\$APM_HAS_PHP" = 1 ];then
        stop_run php-cgi
    fi
    stop_run mysqld
}
start_npm(){
    start_nginx
    start_php_cgi
    start_mysqld
}
stop_npm(){
    stop_run nginx
    stop_run php-cgi
    stop_run mysqld
}
show_status(){
    if [ "\$1" = 0 ];then
        echo "\e[40;35m已启动\e[0m";
    else
        echo "\e[40;37m未已启动\e[0m";
    fi
}
cd "$INSTALL_PATH"
while true;do
    clear
    PHP_CGI_STATUS=\$(has_run php-cgi; echo \$?)
    NGINX_STATUS=\$(has_run nginx; echo \$?)
    HTTPD_STATUS=\$(has_run httpd; echo \$?)
    MYSQLD_STATUS=\$(has_run mysqld; echo \$?)
    NPM_STATUS=\$([ "\$NGINX_STATUS\$PHP_CGI_STATUS\$MYSQLD_STATUS" = '000' ]; echo \$?)
    if [ "\$APM_HAS_PHP" = 1 ];then
        APM_STATUS=\$([ "\$HTTPD_STATUS\$PHP_CGI_STATUS\$MYSQLD_STATUS" = '000' ]; echo \$?)
    else
        APM_STATUS=\$([ "\$HTTPD_STATUS\$MYSQLD_STATUS" = '00' ]; echo \$?)
    fi

    echo -e "
\e[40;33m可操作序号：\e[0m

\e[40;32m 1、启停apache+php+mysql\e[0m    [\$(show_status \$APM_STATUS)]
\e[40;32m 2、启停nginx+php+mysql\e[0m     [\$(show_status \$NPM_STATUS)]
\e[40;32m 3、启停apache\e[0m  [\$(show_status \$HTTPD_STATUS)]
\e[40;32m 4、启停nginx\e[0m   [\$(show_status \$NGINX_STATUS)]
\e[40;32m 5、启停mysql\e[0m   [\$(show_status \$MYSQLD_STATUS)]
\e[40;32m 6、启停php-cgi\e[0m [\$(show_status \$PHP_CGI_STATUS)]
\e[40;31m 7、刷新状态\e[0m
\e[40;31m 8、退出界面\e[0m

\e[40;35m服务处理：启动（+） 停止（-） 重启（*）\e[0m
\e[40;36m输入示例：重启 apache，输入 *3\e[0m

"
    while read -p "请输入要功能+操作序号：" -r INPUT_NUM;do
        case "\$INPUT_NUM" in
            [\+\-\*]1)
                SERVER_NAME=apm
            ;;
            [\+\-\*]2)
                SERVER_NAME=npm
            ;;
            [\+\-\*]3)
                SERVER_NAME=httpd
            ;;
            [\+\-\*]4)
                SERVER_NAME=nginx
            ;;
            [\+\-\*]5)
                SERVER_NAME=mysqld
            ;;
            [\+\-\*]6)
                SERVER_NAME=php-cgi
            ;;
            7)
                break
            ;;
            8)
                exit
            ;;
            *)
                echo "请输入处理+操作序号，请重新输入"
                continue
            ;;
        esac
        ACTION_NAME=\${INPUT_NUM:0:1}
        if [ "\$ACTION_NAME" = '-' -o "\$ACTION_NAME" = '*' ];then
            if declare -F stop_\${SERVER_NAME//-/_} >/dev/null 2>/dev/null;then
                stop_\${SERVER_NAME//-/_}
            else
                stop_run \$SERVER_NAME
            fi
        fi
        if [ "\$ACTION_NAME" = '+' -o "\$ACTION_NAME" = '*' ];then
            start_\${SERVER_NAME//-/_}
        fi
        echo '[info] 即将刷新界面'
        sleep 2s
        break
    done
done

EOF

