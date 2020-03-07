#!/bin/bash

#====================================================
#	System Request:Debian 7+/Ubuntu 14.04+/Centos 6+
#	Dscription: V2ray ws+tls onekey
#	Official document: www.v2ray.com
#====================================================

#fonts color
Green="\033[32m"
Red="\033[31m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"

#notification information
OK="${Green}[OK]${Font}"
Error="${Red}[错误]${Font}"
Info="${Green}[信息]${Font}"

nginx_conf_dir="/etc/nginx/conf.d"
nginx_conf="${nginx_conf_dir}/v2ray.conf"
nginx_version="1.16.1"
openssl_version="1.1.1d"
jemalloc_version="5.2.1"
nginx_dir="/etc/nginx"
nginx_openssl_src="/usr/local/src"


source /etc/os-release

#从VERSION中提取发行版系统的英文名称，为了在debian/ubuntu下添加相对应的Nginx apt源
VERSION=`echo ${VERSION} | awk -F "[()]" '{print $2}'`

check_system(){

    if [[ "${ID}" == "centos" && ${VERSION_ID} -ge 7 ]];then
        echo -e "${OK} ${GreenBG} 当前系统为 Centos ${VERSION_ID} ${VERSION} ${Font} "
        INS="yum"
        echo -e "${OK} ${GreenBG} SElinux 设置中，请耐心等待，不要进行其他操作${Font} "
        setsebool -P httpd_can_network_connect 1
        echo -e "${OK} ${GreenBG} SElinux 设置完成 ${Font} "
        ## Centos 也可以通过添加 epel 仓库来安装，目前不做改动
        cat>/etc/yum.repos.d/nginx.repo<<EOF
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/mainline/centos/7/\$basearch/
gpgcheck=0
enabled=1
EOF
        echo -e "${OK} ${GreenBG} Nginx 源 安装完成 ${Font}"
    elif [[ "${ID}" == "debian" && ${VERSION_ID} -ge 8 ]];then
        echo -e "${OK} ${GreenBG} 当前系统为 Debian ${VERSION_ID} ${VERSION} ${Font} "
        INS="apt"
        ## 添加 Nginx apt源
        if [ ! -f nginx_signing.key ];then
        echo "deb http://nginx.org/packages/mainline/debian/ ${VERSION} nginx" >> /etc/apt/sources.list
        echo "deb-src http://nginx.org/packages/mainline/debian/ ${VERSION} nginx" >> /etc/apt/sources.list
        wget -nc https://nginx.org/keys/nginx_signing.key
        apt-key add nginx_signing.key
        fi
    elif [[ "${ID}" == "ubuntu" && `echo "${VERSION_ID}" | cut -d '.' -f1` -ge 16 ]];then
        echo -e "${OK} ${GreenBG} 当前系统为 Ubuntu ${VERSION_ID} ${VERSION_CODENAME} ${Font} "
        INS="apt"
        ## 添加 Nginx apt源
        if [ ! -f nginx_signing.key ];then
        echo "deb http://nginx.org/packages/mainline/ubuntu/ ${VERSION_CODENAME} nginx" >> /etc/apt/sources.list
        echo "deb-src http://nginx.org/packages/mainline/ubuntu/ ${VERSION_CODENAME} nginx" >> /etc/apt/sources.list
        wget -nc https://nginx.org/keys/nginx_signing.key
        apt-key add nginx_signing.key
        fi
    else
        echo -e "${Error} ${RedBG} 当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内，安装中断 ${Font} "
        exit 1
    fi

}
is_root(){
    # shellcheck disable=SC2046
    # shellcheck disable=SC2006
    if [ `id -u` == 0 ]
        then echo -e "${OK} ${GreenBG} 当前用户是root用户，进入安装流程 ${Font} "
        sleep 3
    else
        echo -e "${Error} ${RedBG} 当前用户不是root用户，请切换到root用户后重新执行脚本 ${Font}"
        exit 1
    fi
}
judge(){
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} $1 完成 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} $1 失败${Font}"
        exit 1
    fi
}
ntpdate_install(){
    if [[ "${ID}" == "centos" ]];then
        ${INS} install ntpdate -y
    else
        ${INS} update
        ${INS} install ntpdate -y
    fi
    judge "安装 NTPdate 时间同步服务 "
}
chrony_install() {
    ${INS} -y install chrony
    judge "安装 chrony 时间同步服务 "

    timedatectl set-ntp true

    if [[ "${ID}" == "centos" ]]; then
        systemctl enable chronyd && systemctl restart chronyd
    else
        systemctl enable chrony && systemctl restart chrony
    fi

    judge "chronyd 启动 "

    timedatectl set-timezone Asia/Shanghai

    echo -e "${OK} ${GreenBG} 等待时间同步 ${Font}"
    sleep 10

    chronyc sourcestats -v
    chronyc tracking -v
    date
    read -rp "请确认时间是否准确,误差范围±3分钟(Y/N): " chrony_install
    [[ -z ${chrony_install} ]] && chrony_install="Y"
    case $chrony_install in
    [yY][eE][sS] | [yY])
        echo -e "${GreenBG} 继续安装 ${Font}"
        sleep 2
        ;;
    *)
        echo -e "${RedBG} 安装终止 ${Font}"
        exit 2
        ;;
    esac
}

dependency_install(){
    ${INS} install wget git lsof bzip2 pcre pcre-devel zlib-devel epel-release haveged -y

    if [[ "${ID}" == "centos" ]];then
       ${INS} -y install crontabs
    else
        ${INS} install cron
    fi
    judge "安装 crontab"

    # 新版的IP判定不需要使用net-tools
    # ${INS} install net-tools -y
    # judge "安装 net-tools"

    ${INS} install bc -y
    judge "安装 bc"

    ${INS} install unzip -y
    judge "安装 unzip"

    ${INS} install java-1.8.0-openjdk -y
    judge "安装java-1.8.0-openjdk"
    curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash
    ${INS} install nodejs -y
    judge "安装nodejs"

    wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
    ${INS} install apache-maven -y

    judge "安装apache-maven"
}

modify_nginx(){
    ## sed 部分地方 适应新配置修正
    if [[ -f /etc/nginx/nginx.conf.bak ]];then
        cp /etc/nginx/nginx.conf.bak /etc/nginx/nginx.conf
    fi
    sed -i "/server_name/c \\\tserver_name ${domain};" ${nginx_conf}
    sed -i "27i \\\tproxy_intercept_errors on;"  /etc/nginx/nginx.conf
}
web_camouflage(){
    mkdir /opt/jar/db -p
    # shellcheck disable=SC2164
    cd /opt
    git clone https://github.com/iamlinhui/template.git -b master
    git clone https://github.com/iamlinhui/template-console.git -b master

    # shellcheck disable=SC2164
    cd /opt/template
    mvn clean package -Dmaven.test.skip=true
    mv /opt/template/vpn-admin/target/*.jar /opt/jar/admin.jar
    mv /opt/template/proxy/target/*.jar /opt/jar/v2ray-proxy.jar
    mv /opt/template/conf/*.yaml /opt/jar

    # shellcheck disable=SC2164
    cd /opt/template-console
    npm install
    npm run build:prod
    mv /opt/template-console/dist /opt/jar/web

    judge "git 项目编译完成"
}
v2ray_install(){
    if [[ -d /root/v2ray ]]; then
        rm -rf /root/v2ray
    fi
    if [[ -d /etc/v2ray ]]; then
        rm -rf /etc/v2ray
    fi
    mkdir -p /root/v2ray
    cd /root/v2ray || exit
    wget -N --no-check-certificate https://install.direct/go.sh

    ## wget http://install.direct/go.sh

    if [[ -f go.sh ]]; then
        rm -rf $v2ray_systemd_file
        systemctl daemon-reload
        bash go.sh --force
        judge "安装 V2ray"
    else
        echo -e "${Error} ${RedBG} V2ray 安装文件下载失败，请检查下载地址是否可用 ${Font}"
        exit 4
    fi
    # 清除临时文件
    rm -rf /root/v2ray

}

nginx_install() {
    ${INS} install nginx -y
    if [[ -d /etc/nginx ]];then
        echo -e "${OK} ${GreenBG} nginx 安装完成 ${Font}"
        sleep 2
    else
        echo -e "${Error} ${RedBG} nginx 安装失败 ${Font}"
        exit 5
    fi
    if [[ ! -f /etc/nginx/nginx.conf.bak ]];then
        cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
        echo -e "${OK} ${GreenBG} nginx 初始配置备份完成 ${Font}"
        sleep 1
    fi

    # 修改基本配置
    sed -i 's/#user  nobody;/user  root;/' ${nginx_dir}/conf/nginx.conf
    sed -i 's/worker_processes  1;/worker_processes  3;/' ${nginx_dir}/conf/nginx.conf
    sed -i 's/    worker_connections  1024;/    worker_connections  4096;/' ${nginx_dir}/conf/nginx.conf
    sed -i '$i include conf.d/*.conf;' ${nginx_dir}/conf/nginx.conf

    # 添加配置文件夹，适配旧版脚本
    mkdir ${nginx_dir}/conf/conf.d
}
ssl_install(){
    if [[ "${ID}" == "centos" ]];then
        ${INS} install socat nc -y
    else
        ${INS} install socat netcat -y
    fi
    judge "安装 SSL 证书生成脚本依赖"

    curl  https://get.acme.sh | sh
    judge "安装 SSL 证书生成脚本"

}
domain_check(){
    stty erase '^H' && read -p "请输入你的域名信息(eg:www.baidu.com):" domain
    domain_ip=`ping ${domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
    echo -e "${OK} ${GreenBG} 正在获取 公网ip 信息，请耐心等待 ${Font}"
    local_ip=`curl -4 ip.sb`
    echo -e "域名dns解析IP：${domain_ip}"
    echo -e "本机IP: ${local_ip}"
    sleep 2
    if [[ $(echo ${local_ip}|tr '.' '+'|bc) -eq $(echo ${domain_ip}|tr '.' '+'|bc) ]];then
        echo -e "${OK} ${GreenBG} 域名dns解析IP  与 本机IP 匹配 ${Font}"
        sleep 2
    else
        echo -e "${Error} ${RedBG} 域名dns解析IP 与 本机IP 不匹配 是否继续安装？（y/n）${Font}" && read install
        case $install in
        [yY][eE][sS]|[yY])
            echo -e "${GreenBG} 继续安装 ${Font}"
            sleep 2
            ;;
        *)
            echo -e "${RedBG} 安装终止 ${Font}"
            exit 2
            ;;
        esac
    fi
}

port_exist_check(){
    # shellcheck disable=SC2006
    if [[ 0 -eq `lsof -i:"$1" | wc -l` ]];then
        echo -e "${OK} ${GreenBG} $1 端口未被占用 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} 检测到 $1 端口被占用，以下为 $1 端口占用信息 ${Font}"
        lsof -i:"$1"
        echo -e "${OK} ${GreenBG} 5s 后将尝试自动 kill 占用进程 ${Font}"
        sleep 5
        lsof -i:"$1" | awk '{print $2}'| grep -v "PID" | xargs kill -9
        echo -e "${OK} ${GreenBG} kill 完成 ${Font}"
        sleep 1
    fi
}
acme() {
    systemctl stop firewalld.service
    if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force --test; then
        echo -e "${OK} ${GreenBG} SSL 证书测试签发成功，开始正式签发 ${Font}"
        rm -rf "$HOME/.acme.sh/${domain}_ecc"
        sleep 2
    else
        echo -e "${Error} ${RedBG} SSL 证书测试签发失败 ${Font}"
        rm -rf "$HOME/.acme.sh/${domain}_ecc"
        exit 1
    fi

    if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force; then
        echo -e "${OK} ${GreenBG} SSL 证书生成成功 ${Font}"
        sleep 2
        mkdir /data
        if "$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath /etc/nginx/v2ray.crt --keypath /etc/nginx/v2ray.key --ecc --force; then
            echo -e "${OK} ${GreenBG} 证书配置成功 ${Font}"
            sleep 2
        fi
    else
        echo -e "${Error} ${RedBG} SSL 证书生成失败 ${Font}"
        rm -rf "$HOME/.acme.sh/${domain}_ecc"
        exit 1
    fi
}
v2ray_conf_add(){
    # shellcheck disable=SC2164
    mkdir -p /etc/v2ray && cd /etc/v2ray
    rm -f /etc/v2ray/config.json
    cp /opt/template/conf/config.json /etc/v2ray/config.json
    judge "V2ray 配置修改"
}
nginx_conf_add(){
    touch ${nginx_conf_dir}/v2ray.conf
    cat>${nginx_conf_dir}/v2ray.conf<<EOF
    server {
      listen 443 ssl http2;
      server_name hostname;
      root /opt/jar/web;
      ssl_certificate       /etc/nginx/v2ray.crt;
      ssl_certificate_key   /etc/nginx/v2ray.key;
      ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
      ssl_ciphers           TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;


      location /api {
          proxy_pass http://127.0.0.1:9091/;
      }

      location /ws/ {
          proxy_redirect off;
          proxy_pass http://127.0.0.1:8081;
          proxy_http_version 1.1;
          proxy_set_header Upgrade \$http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_set_header Host \$http_host;
          proxy_set_header X-Real-IP \$remote_addr;
          proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      }
    }

    server {
        listen 80;
        server_name hostname;
        return 301 https:///\$http_host\$request_uri;
    }
EOF

    modify_nginx
    judge "Nginx 配置修改"

}

start_process_systemd(){
    ### nginx服务在安装完成后会自动启动。需要通过restart或reload重新加载配置
    systemctl start nginx
    judge "Nginx 启动"


    systemctl start v2ray
    judge "V2ray 启动"


    # 运行 admin
    nohup java -jar -Xms40m -Xmx40m -XX:MaxDirectMemorySize=10M -XX:MaxMetaspaceSize=80m  /opt/jar/admin.jar --spring.config.location=/opt/jar/admin.yaml > /dev/null 2>&1 &
    judge "admin 启动"

    # 运行 v2ray-proxy
    nohup java -jar -Xms40m -Xmx40m -XX:MaxDirectMemorySize=10M -XX:MaxMetaspaceSize=80m /opt/jar/v2ray-proxy.jar --spring.config.location=/opt/jar/proxy.yaml > /dev/null 2>&1 &
    judge "proxy 启动"
}

acme_cron_update(){
    if [[ "${ID}" == "centos" ]];then
        sed -i "/acme.sh/c 0 0 * * 0 systemctl stop nginx && \"/root/.acme.sh\"/acme.sh --cron --home \"/root/.acme.sh\" > /dev/null && systemctl start nginx " /var/spool/cron/root
    else
        sed -i "/acme.sh/c 0 0 * * 0 systemctl stop nginx && \"/root/.acme.sh\"/acme.sh --cron --home \"/root/.acme.sh\" > /dev/null && systemctl start nginx " /var/spool/cron/crontabs/root
    fi
    judge "cron 计划任务更新"
}
show_information(){
    systemctl start firewalld.service
    firewall-cmd --list-port
    firewall-cmd --zone=public --add-port=443/tcp --permanent
    firewall-cmd --reload
    clear
    echo -e "${OK} ${Green} 安装成功 "
}

main(){
    is_root
    check_system
    #chrony_install
    #dependency_install
    domain_check
    #v2ray_install
    #port_exist_check 443
    #port_exist_check 9091
    #port_exist_check 6001
    #port_exist_check 8081
    #port_exist_check 8091
    #nginx_install

    #web_camouflage
    #v2ray_conf_add
    #nginx_conf_add

    #改变证书安装位置，防止端口冲突关闭相关应用
    systemctl stop nginx
    systemctl stop v2ray

    #将证书生成放在最后，尽量避免多次尝试脚本从而造成的多次证书申请
    ssl_install
    acme
    show_information
    acme_cron_update
    start_process_systemd
}

main


