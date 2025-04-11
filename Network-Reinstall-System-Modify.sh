#!/bin/bash

CXTaddLine="$1"
CXTaddVER=""
CXTisUEFI=""
CXTmyipapi=""
CXTisCN="No"

if [[ $EUID -ne 0 ]]; then
  clear
  echo "Error: This Reinstall script must be run as root!" 1>&2
  exit 1
fi
  echo "Core Download[Global]..."
  wget --no-check-certificate -qO ~/Core_Install.sh 'https://raw.githubusercontent.com/crixsz/Reinstall-VPS/test/CoreInstall.sh' && chmod a+x ~/Core_Install.sh
  CentOSMirrors=""
  CentOSVaultMirrors=""
  DebianMirrors=""
  UbuntuMirrors=""
  echo -e "\n\n\n"
  echo -e "\n"
  echo "                                                           "
  echo "================================================================"
  echo "=                                                              ="
  echo "=                     [BIOS_LEGACY]                            ="
  echo "=                  Network Reinstall OS                        ="
  echo "=                                                              ="
  echo "=                                                              ="
  echo "=                                                              ="
  echo "================================================================"
  echo "                                                                "
  echo "(Which System want to Install): "
  echo "                                                                "
  echo "   1) CentOS 9"
  echo "   2) CentOS 8"
  echo "   3) Debian 7【Recommend】"
  echo "   4) Debian 11【Recommend】"
  echo "   5) Debian 10"
  echo "   6) OpenWRT"
  echo "   7) Oracle 9"
  echo "   8) Rocky 9"
  echo "   9) Rocky 8【Recommend】"
  echo "   10) Ubuntu 22【Recommend】"
  echo "   11) Ubuntu 20"
  echo "   21) Windows Server 2022【Recommend】"
  echo "   22) Windows Server 2019"
  echo "   23) Windows Server 2016"
  echo "   24) Windows Server 2012 R2"
  echo "   99) (More System)"
  echo "   100) Bare-metal System Deployment Platform(Advanced Users)"
  echo "   0) Exit"
  echo -ne "\n(Your option): "
  echo "                                                                "
  read N
case $N in
  1)
    echo -e "\nInstall...CentOS 9\n"
    read -s -n1 -p "(Press any key to continue...)"
    bash ~/Core_Install.sh -a -v 64 -dd "https://odc.cxthhhhh.com/d/SyStem/CentOS/CentOS_9.X_x64_Legacy_NetInstallation_Stable_v1.6.vhd.gz" $DebianMirrors $CXTaddLine
    ;;
  2)
    echo -e "\nInstall...CentOS 8\n"
    read -s -n1 -p "(Press any key to continue...)"
    bash ~/Core_Install.sh -a -v 64 -dd "https://odc.cxthhhhh.com/d/SyStem/CentOS/CentOS_8.X_x64_Legacy_NetInstallation_Stable_v6.8.vhd.gz" $DebianMirrors $CXTaddLine
    ;;
  3)
    echo -e "\nInstall...CentOS 7\n"
    read -s -n1 -p "(Press any key to continue...)"
    bash ~/Core_Install.sh -a -v 64 -dd "https://odc.cxthhhhh.com/d/SyStem/CentOS/CentOS_7.X_x64_Legacy_NetInstallation_Final_v9.8.vhd.gz" $DebianMirrors $CXTaddLine
    ;;
  4)
    echo -e "\nInstall...Debian 11\n"
    read -s -n1 -p "(Press any key to continue...)"
    bash ~/Core_Install.sh -d 11 -a -v 64 $DebianMirrors $CXTaddLine
    ;;
  5)
    echo -e "\nInstall...Debian 10\n"
    read -s -n1 -p "(Press any key to continue...)"
    bash ~/Core_Install.sh -d 10 -a -v 64 $DebianMirrors $CXTaddLine
    ;;
  6)
    echo -e "\nInstall...OpenWRT\n"
    read -s -n1 -p "(Press any key to continue...)"
    bash ~/Core_Install.sh -a -v 64 -dd "https://odc.cxthhhhh.com/d/SyStem/OpenWRT-Virtualization-Servers/Stable/openwrt-x86-64-generic-squashfs-combined.img.gz" $DebianMirrors $CXTaddLine
    ;;
  7)
    echo -e "\nInstall...Oracle 9\n"
    read -s -n1 -p "(Press any key to continue...)"
    bash ~/Core_Install.sh -a -v 64 -dd "https://odc.cxthhhhh.com/d/SyStem/Oracle/Oracle_9.X_x64_Legacy_NetInstallation_Stable_v1.8.vhd.gz" $DebianMirrors $CXTaddLine
    ;;
  8)
    echo -e "\nInstall...Rocky 9\n"
    read -s -n1 -p "(Press any key to continue...)"
    bash ~/Core_Install.sh -a -v 64 -dd "https://odc.cxthhhhh.com/d/SyStem/Rocky/Rocky_8.X_x64_Legacy_NetInstallation_Stable_v6.8.vhd.gz" $DebianMirrors $CXTaddLine
    ;;
  9)
    echo -e "\nInstall...Rocky 8\n"
    read -s -n1 -p "(Press any key to continue...)"
    bash ~/Core_Install.sh -a -v 64 -dd "https://odc.cxthhhhh.com/d/SyStem/Rocky/Rocky_8.X_x64_Legacy_NetInstallation_Stable_v6.8.vhd.gz" $DebianMirrors $CXTaddLine
    ;;
  10)
    echo -e "\nInstall...Ubuntu 22\n"
    read -s -n1 -p "(Press any key to continue...)"
    bash ~/Core_Install.sh -u 22.04 -a -v 64 $UbuntuMirrors $CXTaddLine
    ;;
  11)
    echo -e "\nInstall...Ubuntu 20\n"
    read -s -n1 -p "(Press any key to continue...)"
    bash ~/Core_Install.sh -u 20.04 -a -v 64 $UbuntuMirrors $CXTaddLine
    ;;
  21)
    echo -e "\nInstall...Windows Server 2022\n"
    read -s -n1 -p "(Press any key to continue...)"
    bash ~/Core_Install.sh -a -v 64 -dd "https://odc.cxthhhhh.com/d/SyStem/Windows_DD_Disks/Disk_Windows_Server_2022_DataCenter_CN_v2.12.vhd.gz" $DebianMirrors $CXTaddLine
    ;;
  22)
    echo -e "\nInstall...Windows Server 2019\n"
    read -s -n1 -p "(Press any key to continue...)"
    bash ~/Core_Install.sh -a -v 64 -dd "https://odc.cxthhhhh.com/d/SyStem/Windows_DD_Disks/Disk_Windows_Server_2019_DataCenter_CN_v5.1.vhd.gz" $DebianMirrors $CXTaddLine
    ;;
  23)
    echo -e "\nInstall...Windows Server 2016\n"
    read -s -n1 -p "(Press any key to continue...)"
    bash ~/Core_Install.sh -a -v 64 -dd "https://odc.cxthhhhh.com/d/SyStem/Windows_DD_Disks/Disk_Windows_Server_2016_DataCenter_CN_v4.12.vhd.gz" $DebianMirrors $CXTaddLine
    ;;
  24)
    echo -e "\nInstall...Windows Server 2012 R2\n"
    read -s -n1 -p "(Press any key to continue...)"
    bash ~/Core_Install.sh -a -v 64 -dd "https://odc.cxthhhhh.com/d/SyStem/Windows_DD_Disks/Disk_Windows_Server_2012R2_DataCenter_CN_v4.29.vhd.gz" $DebianMirrors $CXTaddLine
    ;;
  99)
    echo "更多系统前往CXT博客及ODC查看。https://www.cxthhhhh.com"
    exit 1
    ;;
  100)
    echo -e "\nInstall...Bare-metal System Deployment Platform(Advanced Users)\n"
    read -s -n1 -p "(Press any key to continue...)"
    bash ~/Core_Install.sh -a -v 64 -dd "https://odc.cxthhhhh.com/d/SyStem/Bare-metal_System_Deployment_Platform/CXT_Bare-metal_System_Deployment_Platform_v3.6.vhd.gz" $DebianMirrors $CXTaddLine
    ;;
  0) exit 0 ;;
  *)
    echo "Wrong input!"
    exit 1
    ;;
  esac

echo "-----------------------------------------------------------------------------------------------"
echo -e "\033[32m Start Installation \033[0m"
echo "-----------------------------------------------------------------------------------------------"
echo -e "\n"
