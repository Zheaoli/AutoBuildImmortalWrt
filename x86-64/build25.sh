#!/bin/bash
# Log file for debugging
# 目前暂不支持第三方软件apk 待后续开发 仓库内可以集成
source shell/custom-packages.sh
#echo "第三方软件包: $CUSTOM_PACKAGES"
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >> $LOGFILE
echo "编译固件大小为: $PROFILE MB"
echo "Include Docker: $INCLUDE_DOCKER"

echo "Create pppoe-settings"
mkdir -p  /home/build/immortalwrt/files/etc/config

# 创建pppoe配置文件 yml传入环境变量ENABLE_PPPOE等 写入配置文件 供99-custom.sh读取
cat << EOF > /home/build/immortalwrt/files/etc/config/pppoe-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

echo "cat pppoe-settings"
cat /home/build/immortalwrt/files/etc/config/pppoe-settings



# 输出调试信息
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始构建固件..."

# ============= imm仓库内的插件==============
# 定义所需安装的包列表 下列插件你都可以自行删减
PACKAGES=""
PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-theme-argon"
PACKAGES="$PACKAGES luci-app-argon-config"
PACKAGES="$PACKAGES luci-i18n-argon-config-zh-cn"
#24.10
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
PACKAGES="$PACKAGES xray-core hysteria luci-i18n-passwall-zh-cn"
PACKAGES="$PACKAGES luci-app-openclash"
PACKAGES="$PACKAGES luci-i18n-homeproxy-zh-cn"
PACKAGES="$PACKAGES openssh-sftp-server"

# 文件管理器
PACKAGES="$PACKAGES luci-i18n-filemanager-zh-cn"

# ============= routing feed 路由协议相关包 ==============
PACKAGES="$PACKAGES ahcpd"
PACKAGES="$PACKAGES alfred"
PACKAGES="$PACKAGES babel-pinger"
PACKAGES="$PACKAGES babeld"
PACKAGES="$PACKAGES batctl"
PACKAGES="$PACKAGES batmand"
PACKAGES="$PACKAGES bird2"
PACKAGES="$PACKAGES bmx7"
PACKAGES="$PACKAGES cjdns"
PACKAGES="$PACKAGES luci-app-cjdns"
PACKAGES="$PACKAGES mesh11sd"
PACKAGES="$PACKAGES naywatch"
PACKAGES="$PACKAGES ndppd"
PACKAGES="$PACKAGES nodogsplash"
PACKAGES="$PACKAGES ohybridproxy"
PACKAGES="$PACKAGES olsrd"
PACKAGES="$PACKAGES opennds"
PACKAGES="$PACKAGES pimbd"
PACKAGES="$PACKAGES prince"
PACKAGES="$PACKAGES vis"
# quagga 全部子包
PACKAGES="$PACKAGES quagga-zebra quagga-bgpd quagga-ospfd quagga-ospf6d"
PACKAGES="$PACKAGES quagga-ripd quagga-ripngd quagga-isisd quagga-vtysh"
PACKAGES="$PACKAGES quagga-babeld quagga-pimd quagga-watchquagga"
# frr 全部子包
PACKAGES="$PACKAGES frr frr-zebra frr-bgpd frr-ospfd frr-ospf6d"
PACKAGES="$PACKAGES frr-ripd frr-ripngd frr-isisd frr-pimd"
PACKAGES="$PACKAGES frr-ldpd frr-babeld frr-eigrpd frr-fabricd"
PACKAGES="$PACKAGES frr-nhrpd frr-pbrd frr-staticd frr-bfdd"
PACKAGES="$PACKAGES frr-vrrpd frr-pathd frr-vtysh frr-watchfrr"
# ======== shell/custom-packages.sh =======
# 合并imm仓库以外的第三方插件 暂时注释
#PACKAGES="$PACKAGES $CUSTOM_PACKAGES"


# 判断是否需要编译 Docker 插件
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding package: luci-i18n-dockerman-zh-cn"
fi

# 若构建openclash 则添加内核
if echo "$PACKAGES" | grep -q "luci-app-openclash"; then
    echo "✅ 已选择 luci-app-openclash，添加 openclash core"
    mkdir -p files/etc/openclash/core
    # Download clash_meta
    META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64.tar.gz"
    wget -qO- $META_URL | tar xOvz > files/etc/openclash/core/clash_meta
    chmod +x files/etc/openclash/core/clash_meta
    # Download GeoIP and GeoSite
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -O files/etc/openclash/GeoIP.dat
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O files/etc/openclash/GeoSite.dat
else
    echo "⚪️ 未选择 luci-app-openclash"
fi

# 构建镜像
echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with the following packages:"
echo "$PACKAGES"

make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE=$PROFILE

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
