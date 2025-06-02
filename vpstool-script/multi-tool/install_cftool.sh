#!/bin/bash

#
# Install linux kernel for TCP BBR and BBR Plus
#
# Copyright (C) 2021-2023 JinWYP
#


# 4.4 LTS 4.9 LTS 4.14 LTS 4.19 LTS
# 5.4 LTS 5.10 LTS


# The latest longterm version of the 4.x kernel is 4.19.113. If you want to install it, you can only find a 4.19 rpm package to install it.

# Starting from Linux 4.9, TCP BBR has become part of the Linux kernel. Therefore, the first prerequisite for enabling BBR is that the current system kernel version is greater than or equal to 4.9

# Linux kernel 5.6 is officially released, with built-in wireguard module
# Linux 5.6 introduces FQ-PIE packet scheduler to help combat Bufferbloat
# 5.5 kernel supports cake queues
# Zilaiguang Boss: The default queue algorithm of xamod kernel 5.8 has been changed to fq_pie. It used to be cake.


# centos8 installed the default kernel kernel-core-4.18.0-240.15.1.el8_3.x86_64, kernel-modules-4.18.0-240.15.1.el8_3.x86_64
# ubuntu16 installed the default kernel linux-generic 4.4.0.210, linux-headers-4.4.0-210
# ubuntu18 installed the default kernel linux-generic 4.15.0.140, linux-headers-4.15.0-140
# ubuntu20 installed the default kernel linux-image-5.4.0-70-generic, linux-headers-5.4.0-70
# debian10 installation completes the default kernel 4.19.0-16-amd64
# debian11 installs the default kernel linux-image-5.10.0-8-amd64

# UJX6N compiled bbr plus kernel 5.10.27-bbrplus 5.9.16 5.4.86
# UJX6N compiled bbr plus kernel 4.19.164 4.14.213 4.9.264-1.bbrplus
# https://github.com/cx9208/bbrplus/issues/27


# BBR Speed â€‹â€‹Test
# https://www.shopee6.com/web/web-tutorial/bbr-vs-plus-vs-bbr2.html
# https://hostloc.com/thread-644985-1-1.html

# https://dropbox.tech/infrastructure/evaluating-bbrv2-on-the-dropbox-edge-network



export LC_ALL=C
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8


sudoCmd=""
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
fi


#fonts color
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
bold(){
    echo -e "\033[1m\033[01m$1\033[0m"
}

Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"





osCPU=""
osArchitecture="arm"
osInfo=""
osRelease=""
osReleaseVersion=""
osReleaseVersionNo=""
osReleaseVersionNoShort=""
osReleaseVersionCodeName="CodeName"
osSystemPackage=""
osSystemMdPath=""
osSystemShell="bash"

function checkArchitecture(){
	# https://stackoverflow.com/questions/48678152/how-to-detect-386-amd64-arm-or-arm64-os-architecture-via-shell-bash

	case $(uname -m) in
		i386) osArchitecture="386" ;;
		i686) osArchitecture="386" ;;
		x86_64) osArchitecture="amd64" ;;
		arm) dpkg --print-architecture | grep -q "arm64" && osArchitecture="arm64" || osArchitecture="arm" ;;
		aarch64) dpkg --print-architecture | grep -q "arm64" && osArchitecture="arm64" || osArchitecture="arm" ;;
		* ) osArchitecture="arm" ;;
	esac
}

function checkCPU(){
	osCPUText=$(cat /proc/cpuinfo | grep vendor_id | uniq)
	if [[ $osCPUText =~ "GenuineIntel" ]]; then
		osCPU="intel"
    elif [[ $osCPUText =~ "AMD" ]]; then
        osCPU="amd"
    else
        echo
    fi

	# green "Status status display--Current CPU is: $osCPU"
}

# Detection system version number
getLinuxOSVersion(){
    if [[ -s /etc/redhat-release ]]; then
        osReleaseVersion=$(grep -oE '[0-9.]+' /etc/redhat-release)
    else
        osReleaseVersion=$(grep -oE '[0-9.]+' /etc/issue)
    fi

    # https://unix.stackexchange.com/questions/6345/how-can-i-get-distribution-name-and-version-number-in-a-simple-shell-script

    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        source /etc/os-release
        osInfo=$NAME
        osReleaseVersionNo=$VERSION_ID

        if [ -n "$VERSION_CODENAME" ]; then
            osReleaseVersionCodeName=$VERSION_CODENAME
        fi
    elif type lsb_release >/dev/null 2>&1; then
        #linuxbase.org
        osInfo=$(lsb_release -si)
        osReleaseVersionNo=$(lsb_release -sr)

    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        osInfo=$DISTRIB_ID
        osReleaseVersionNo=$DISTRIB_RELEASE

    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        osInfo=Debian
        osReleaseVersion=$(cat /etc/debian_version)
        osReleaseVersionNo=$(sed 's/\..*//' /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        osReleaseVersion=$(grep -oE '[0-9.]+' /etc/redhat-release)
    else
        # Fall back to uname, eg "Linux <version>", also works for BSD, etc.
        osInfo=$(uname -s)
        osReleaseVersionNo=$(uname -r)
    fi

    osReleaseVersionNoShort=$(echo $osReleaseVersionNo | sed 's/\..*//')
}


# Detection system release code
function getLinuxOSRelease(){
    if [[ -f /etc/redhat-release ]]; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
        osReleaseVersionCodeName=""
    elif cat /etc/issue | grep -Eqi "debian|raspbian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="buster"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="bionic"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
        osReleaseVersionCodeName=""
    elif cat /proc/version | grep -Eqi "debian|raspbian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="buster"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
        osReleaseVersionCodeName="bionic"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
        osReleaseVersionCodeName=""
    fi

    getLinuxOSVersion
    checkArchitecture
	checkCPU
    virt_check

    [[ -z $(echo $SHELL|grep zsh) ]] && osSystemShell="bash" || osSystemShell="zsh"

    echo "OS info: ${osInfo}, ${osRelease}, ${osReleaseVersion}, ${osReleaseVersionNo}, ${osReleaseVersionCodeName}, ${osSystemShell}, ${osSystemPackage}, ${osSystemMdPath}"
}


virt_check(){
	# if hash ifconfig 2>/dev/null; then
		#eth=$(ifconfig)
	#fi

	virtualx=$(dmesg) 2>/dev/null


    if [ "$(command -v dmidecode)" ]; then
		sys_manu=$(dmidecode -s system-manufacturer) 2>/dev/null
		sys_product=$(dmidecode -s system-product-name) 2>/dev/null
		sys_ver=$(dmidecode -s system-version) 2>/dev/null
	else
		sys_manu=""
		sys_product=""
		sys_ver=""
	fi

	if grep docker /proc/1/cgroup -qa; then
	    virtual="Docker"
	elif grep lxc /proc/1/cgroup -qa; then
		virtual="Lxc"
	elif grep -qa container=lxc /proc/1/environ; then
		virtual="Lxc"
	elif [[ -f /proc/user_beancounters ]]; then
		virtual="OpenVZ"
	elif [[ "$virtualx" == *kvm-clock* ]]; then
		virtual="KVM"
	elif [[ "$ename" == *KVM* ]]; then
		virtual="KVM"
	elif [[ "$ename" == *QEMU* ]]; then
		virtual="KVM"
	elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; then
		virtual="VMware"
	elif [[ "$virtualx" == *"Parallels Software International"* ]]; then
		virtual="Parallels"
	elif [[ "$virtualx" == *VirtualBox* ]]; then
		virtual="VirtualBox"
	elif [[ -e /proc/xen ]]; then
		virtual="Xen"
	elif [[ "$sys_manu" == *"Microsoft Corporation"* ]]; then
		if [[ "$sys_product" == *"Virtual Machine"* ]]; then
			if [[ "$sys_ver" == *"7.0"* || "$sys_ver" == *"Hyper-V" ]]; then
				virtual="Hyper-V"
			else
				virtual="Microsoft Virtual Machine"
			fi
		fi
	else
		virtual="Dedicated hen"
	fi
}






function installSoftDownload(){
	if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then

        PACKAGE_LIST=( "wget" "curl" "git" "unzip" "apt-transport-https" "cpu-checker" "bc" "cron" )

        # Check if all packages are installed
        for package in "${PACKAGE_LIST[@]}"; do
            if ! dpkg -l | grep -qw "$package"; then
                # green "$package is not installed. ${osSystemPackage} Installing..."
                ${osSystemPackage} install -y "$package"
            fi
        done

		if ! dpkg -l | grep -qw curl; then
			${osSystemPackage} -y install wget curl git

            if [[ "${osRelease}" == "debian" ]]; then
                echo "deb http://deb.debian.org/debian buster-backports main contrib non-free" > /etc/apt/sources.list.d/buster-backports.list
                echo "deb-src http://deb.debian.org/debian buster-backports main contrib non-free" >> /etc/apt/sources.list.d/buster-backports.list
                ${sudoCmd} apt update -y
            fi

		fi

        if ! dpkg -l | grep -qw ca-certificates; then
			${osSystemPackage} -y install ca-certificates dmidecode
            update-ca-certificates
		fi

	elif [[ "${osRelease}" == "centos" ]]; then

        PACKAGE_LIST_Centos=( "wget" "curl" "git" "unzip" "bc" )

        # Check if all packages are installed
        for package in "${PACKAGE_LIST_Centos[@]}"; do
            if ! rpm -qa | grep -qw "$package"; then
                # green "$package is not installed. ${osSystemPackage} Installing..."
                ${osSystemPackage} install -y "$package"
            fi
        done

        # Process ca certificate
        if ! rpm -qa | grep -qw ca-certificates; then
			${osSystemPackage} -y install ca-certificates dmidecode
            update-ca-trust force-enable
		fi
	fi

}










# Update this script
function upgradeScript(){
    wget -Nq --no-check-certificate -O ./install_kernel.sh "https://raw.githubusercontent.com/jinwyp/one_click_script/master/install_kernel.sh"
    green " Script upgrade successful. This script upgrade was successful! "
    chmod +x ./install_kernel.sh
    sleep 2s
    exec "./install_kernel.sh"
}









function rebootSystem(){

    if [ -z $1 ]; then

        red "Please check the above information to see if there is a new kernel version, and whether the old kernel version ${osKernelVersionBackup} has been uninstalled!"
        echo
        red "Please check if you have accidentally deleted and uninstalled the new kernel. If there is no new kernel ${linuxKernelToInstallVersionFull}, do not reboot. You can reinstall the kernel and then reboot!"

    fi

    echo
	read -p "Do you want to reboot now? Please enter [Y/n]?" isRebootInput
	isRebootInput=${isRebootInput:-Y}

	if [[ $isRebootInput == [Yy] ]]; then
		${sudoCmd} reboot
	else
		exit
	fi
}

function promptContinueOpeartion(){
	read -p "Do you want to continue the operation? Press Enter to continue the operation by default. Please enter [Y/n]:" isContinueInput
	isContinueInput=${isContinueInput:-Y}

	if [[ $isContinueInput == [Yy] ]]; then
		echo ""
	else
		exit 1
	fi
}

# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash
versionCompare() {
    if [[ $1 == $2 ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

versionCompareWithOp () {
    versionCompare $1 $2
    case $? in
        0) op='=';;
        1) op='>';;
        2) op='<';;
    esac
    if [[ $op != $3 ]]; then
        # echo "Version Number Compare Fail: Expected '$3', Actual '$op', Arg1 '$1', Arg2 '$2'"
        return 1
    else
        # echo "Version Number Compare Pass: '$1 $op $2'"
        return 0
    fi
}
















osKernelVersionFull=$(uname -r)
osKernelVersionBackup=$(uname -r | awk -F "-" '{print $1}')
osKernelVersionShort=$(uname -r | cut -d- -f1 | awk -F "." '{print $1"."$2}')
osKernelBBRStatus=""
systemBBRRunningStatus="no"
systemBBRRunningStatusText=""

function listAvailableLinuxKernel(){
    echo
    green " =================================================="
    green " Status display -- Currently available Linux kernels can be installed: "
    if [[ "${osRelease}" == "centos" ]]; then
		${sudoCmd} yum --disablerepo="*" --enablerepo="elrepo-kernel" list available | grep kernel
	else
        if [ -z $1 ]; then
            ${sudoCmd} apt-cache search linux-image
        else
            ${sudoCmd} apt-cache search linux-image | grep $1
        fi
	fi

    green " =================================================="
    echo
}

function listInstalledLinuxKernel(){
    echo
    green " =================================================="
    green " Status display -- Currently installed Linux kernel: "
    echo

	if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
        dpkg --get-selections | grep linux-
		# dpkg -l | grep linux-
        # dpkg-query -l | grep linux-
        # apt list --installed | grep linux-
        echo
        red "If you encounter kernel linux-image linux-headers version inconsistency when installing the kernel, please manually uninstall the installed kernel"
        red "Uninstall kernel command 1 apt remove -y --purge linux-xxx name"
        red "Uninstall kernel command 2 apt autoremove -y --purge linux-xxx name"

	elif [[ "${osRelease}" == "centos" ]]; then
        ${sudoCmd} rpm -qa | grep kernel
        echo
        red "If you encounter kernel kernel-headers kernel-devel version inconsistency when installing the kernel, please manually uninstall the installed kernel"
        red "Uninstall kernel command rpm --nodeps -e kernel-xxx name"
	fi
    green " =================================================="
    echo
}

function showLinuxKernelInfoNoDisplay(){

    isKernelSupportBBRVersion="4.9"

    if versionCompareWithOp "${isKernelSupportBBRVersion}" "${osKernelVersionShort}" ">"; then
        echo
    else
        osKernelBBRStatus="BBR"
    fi

    if [[ ${osKernelVersionFull} == *"bbrplus"* ]]; then
        osKernelBBRStatus="BBR Plus"
    elif [[ ${osKernelVersionFull} == *"xanmod"* ]]; then
        osKernelBBRStatus="BBR and BBR2"
    fi

	net_congestion_control=`cat /proc/sys/net/ipv4/tcp_congestion_control | awk '{print $1}'`
	net_qdisc=`cat /proc/sys/net/core/default_qdisc | awk '{print $1}'`
	net_een=`cat /proc/sys/net/ipv4/tcp_een | awk '{print $1}'`

    if [[ ${osKernelVersionBackup} == *"4.14.129"* ]]; then
        # isBBREnabled=$(grep "net.ipv4.tcp_congestion_control" /etc/sysctl.conf | awk -F "=" '{print $2}')
        # isBBREnabled=$(sysctl net.ipv4.tcp_available_congestion_control | awk -F "=" '{print $2}')

        isBBRTcpEnabled=$(lsmod | grep "bbr" | awk '{print $1}')
        isBBRPlusTcpEnabled=$(lsmod | grep "bbrplus" | awk '{print $1}')
        isBBR2TcpEnabled=$(lsmod | grep "bbr2" | awk '{print $1}')
    else
        isBBRTcpEnabled=$(sysctl net.ipv4.tcp_congestion_control | grep "bbr" | awk -F "=" '{print $2}' | awk '{$1=$1;print}')
        isBBRPlusTcpEnabled=$(sysctl net.ipv4.tcp_congestion_control | grep "bbrplus" | awk -F "=" '{print $2}' | awk '{$1=$1;print}')
        isBBR2TcpEnabled=$(sysctl net.ipv4.tcp_congestion_control | grep "bbr2" | awk -F "=" '{print $2}' | awk '{$1=$1;print}')
    fi

    if [[ ${net_een} == "1" ]]; then
        systemEenStatusText="Enabled"
    elif [[ ${net_een} == "0" ]]; then
        systemEenStatusText="Closed"
    elif [[ ${net_een} == "2" ]]; then
        systemEenStatusText="Only enabled for inbound requests (default value)"
    else
        systemEenStatusText=""
    fi

    if [[ ${net_congestion_control} == "bbr" ]]; then

        if [[ ${isBBRTcpEnabled} == *"bbr"* ]]; then
            systemBBRRunningStatus="bbr"
            systemBBRRunningStatusText="BBR has started successfully"
        else
            systemBBRRunningStatusText="BBR startup failed"
        fi

    elif [[ ${net_congestion_control} == "bbrplus" ]]; then

        if [[ ${isBBRPlusTcpEnabled} == *"bbrplus"* ]]; then
            systemBBRRunningStatus="bbrplus"
            systemBBRRunningStatusText="BBR Plus has started successfully"
        else
            systemBBRRunningStatusText="BBR Plus startup failed"
        fi

    elif [[ ${net_congestion_control} == "bbr2" ]]; then

        if [[ ${isBBR2TcpEnabled} == *"bbr2"* ]]; then
            systemBBRRunningStatus="bbr2"
            systemBBRRunningStatusText="BBR2 has started successfully"
        else
            systemBBRRunningStatusText="BBR2 startup failed"
        fi

    else
        systemBBRRunningStatusText="Acceleration module not started"
    fi

}

function showLinuxKernelInfo(){

    # https://stackoverflow.com/questions/8654051/how-to-compare-two-floating-point-numbers-in-bash
    # https://stackoverflow.com/questions/229551/how-to-check-if-a-string-contains-a-substring-in-bash

    isKernelSupportBBRVersion="4.9"

    green " =================================================="
    green " Status display--Current Linux kernel version: ${osKernelVersionShort}, $(uname -r) "

    if versionCompareWithOp "${isKernelSupportBBRVersion}" "${osKernelVersionShort}" ">"; then
        green "The current system kernel is lower than 4.9 and does not support BBR"
    else
        green "The current system kernel is higher than 4.9, and supports BBR, ${systemBBRRunningStatusText}"
    fi

    if [[ ${osKernelVersionFull} == *"xanmod"* ]]; then
        green "The current system kernel already supports enabling BBR2, ${systemBBRRunningStatusText}"
    else
        green "The current system kernel does not support enabling BBR2"
    fi

    if [[ ${osKernelVersionFull} == *"bbrplus"* ]]; then
        green "The current system kernel already supports BBR Plus, ${systemBBRRunningStatusText}"
    else
        green "The current system kernel does not support enabling BBR Plus"
    fi
    # sysctl net.ipv4.tcp_available_congestion_control return value net.ipv4.tcp_available_congestion_control = bbr cubic reno or reno cubic bbr
    # sysctl net.ipv4.tcp_congestion_control return value net.ipv4.tcp_congestion_control = bbr
    # sysctl net.core.default_qdisc return value net.core.default_qdisc = fq
    # lsmod | grep bbr The return value is tcp_bbr 20480 3 or tcp_bbr 20480 1 Note: Not all VPS will have this return value. If not, it is normal.

    # isFlagBbr=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')

    # if [[ (${isFlagBbr} == *"bbr"*) && (${isFlagBbr} != *"bbrplus"*) && (${isFlagBbr} != *"bbr2"*) ]]; then
    # green "Status display--Is BBR enabled: Enabled"
    # else
    # green "Status display--Is BBR enabled: Not enabled"
    #fi

    # if [[ ${isFlagBbr} == *"bbrplus"* ]]; then
    # green "Status display--Is BBR Plus enabled: Enabled"
    # else
    # green "Status display--Is BBR Plus enabled: Not enabled"
    #fi

    # if [[ ${isFlagBbr} == *"bbr2"* ]]; then
    # green "Status display--Is BBR2 enabled: Enabled"
    # else
    # green "Status display--Is BBR2 enabled: Not enabled"
    #fi

    green " =================================================="
    echo
}


function enableBBRSysctlConfig(){
    # https://hostloc.com/thread-644985-1-1.html
    # High-quality lines run more efficiently with 5.5+cake and original bbr bandwidth, but cake will not be as slow as original bbr even at peak times. It may be slower than plus, but the difference is not significant.
    # bbr plus is better for the US West Coast or some areas with high latency. Ruisu is very effective for high packet loss.
    # If the bandwidth is large, and the latency is low and there is no packet loss, 5.5+cake is better for me. If the latency is high, plus is better. If there is a lot of packet loss, sharp speed is the best. Generally, cake is good for less than 130ms, and plus is better for more than 130ms.

    # https://github.com/xanmod/linux/issues/26
    # To put it simply, bbrplus changes something, and then those changes are merged into the 5.1 kernel. The bbr that comes with the 5.1 kernel and above already includes the so-called bbrplus changes.
    # PS: bbr is constantly being modified. For example, the bbr of the 5.0 kernel, the bbr of the 4.15 kernel, and the bbr of the 4.9 kernel are actually different.

    # https://sysctl-explorer.net/net/ipv4/tcp_een/


    removeBbrSysctlConfig
    currentBBRText="bbr"
    currentQueueText="fq"
    currentEenValue="2"
    currentEenText=""

    if [ $1 = "bbrplus" ]; then
        currentBBRText="bbrplus"

    else
        echo
        echo "Please select (1) BBR or (2) BBR2 network acceleration"
        red "Select 1 BBR requires kernel 4.9 or above"
        red "Select 2 BBR2 requires the kernel to be XanMod"
        read -p "Please select? Press Enter by default 1 BBR is selected, please enter [1/2]:" BBRTcpInput
        BBRTcpInput=${BBRTcpInput:-1}
        if [[ $BBRTcpInput == [2] ]]; then
            if [[ ${osKernelVersionFull} == *"xanmod"* ]]; then
                currentBBRText="bbr2"

                echo
                echo "Please select whether to enable Een, (1) Disable (2) Enable (3) Enable only for inbound requests"
                red "Note: Enabling Een may cause network devices to become inaccessible"
                read -p "Please select? Press Enter by default, select 1 to disable Een, please enter [1/2]:" EenTcpInput
                EenTcpInput=${EenTcpInput:-1}
                if [[ $EenTcpInput == [2] ]]; then
                    currentEenValue="1"
                    currentEenText="+Een"
                elif [[ $EenTcpInput == [3] ]]; then
                    currentEenValue="2"
                else
                    currentEenValue="0"
                fi

            else
                echo
                red "The current system kernel does not have the XanMod kernel installed, so BBR2 cannot be enabled. Enable BBR instead."
                echo
                currentBBRText="bbr"
            fi

        else
            currentBBRText="bbr"
        fi
    fi

    echo
    echo "Please select a queue algorithm (1) FQ, (2) FQ-Codel, (3) FQ-PIE, (4) CAKE"
    red "Select 2 FQ-Codel queue algorithm requires kernel 4.13 or above"
    red "Selecting 3 FQ-PIE queue algorithm requires kernel 5.6 or above"
    red "Selecting 4 CAKE queue algorithm requires kernel 5.5 or above"
    read -p "Please select a queue algorithm? Press Enter by default 1 FQ is selected, please enter [1/2/3/4]:" BBRQueueInput
    BBRQueueInput=${BBRQueueInput:-1}

    if [[ $BBRQueueInput == [2] ]]; then
        currentQueueText="fq_codel"

    elif [[ $BBRQueueInput == [3] ]]; then
        currentQueueText="fq_pie"

    elif [[ $BBRQueueInput == [4] ]]; then
        currentQueueText="cake"

    else
        currentQueueText="fq"
    fi

    echo "net.core.default_qdisc=${currentQueueText}" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=${currentBBRText}" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_een=${currentEenValue}" >> /etc/sysctl.conf

    isSysctlText=$(sysctl -p 2>&1 | grep "No such file")

    echo
    if [[ -z "$isSysctlText" ]]; then
		green "${currentBBRText} + ${currentQueueText} ${currentEenText} has been successfully opened"
	else
        green "${currentBBRText} ${currentEenText} has been successfully opened"
        red "But the current kernel version is too low, and enabling the queue algorithm ${currentQueueText} failed! "
        red "Please re-run the script, select '2 Enable BBR acceleration', and then be sure to select (1) FQ queue algorithm!"
    fi
    echo


    read -p "Do you want to optimize the system network configuration? Press Enter to select default optimization. Please enter [Y/n]:" isOptimizingSystemInput
    isOptimizingSystemInput=${isOptimizingSystemInput:-Y}

    if [[ $isOptimizingSystemInput == [Yy] ]]; then
        addOptimizingSystemConfig "cancel"
    else
        echo
        echo "sysctl -p"
        echo
        sysctl -p
        echo
    fi

}

# Uninstall bbr+RuiSu configuration
function removeBbrSysctlConfig(){
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf

	sed -i '/net.ipv4.tcp_een/d' /etc/sysctl.conf

	if [[ -e /appex/bin/lotServer.sh ]]; then
		bash <(wget --no-check-certificate -qO- https://git.io/lotServerInstall.sh) uninstall
	fi
}


function removeOptimizingSystemConfig(){
    removeBbrSysctlConfig

    sed -i '/fs.file-max/d' /etc/sysctl.conf
	sed -i '/fs.inotify.max_user_instances/d' /etc/sysctl.conf

	sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
	sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
	sed -i '/net.ipv4.route.gc_timeout/d' /etc/sysctl.conf

	sed -i '/net.ipv4.tcp_syn_retries/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_synack_retries/d' /etc/sysctl.conf
	sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
	sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_timestamps/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_max_orphans/d' /etc/sysctl.conf

	# sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf


    sed -i '/1000000/d' /etc/security/limits.conf
    sed -i '/1000000/d' /etc/profile

    echo
    green "The current system's network optimization configuration has been deleted"
    echo
}

function addOptimizingSystemConfig(){

    # https://ustack.io/2019-11-21-Linux%E5%87%A0%E4%B8%AA%E9%87%8D%E8%A6%81%E7%9A%84%E5%86%85%E6%A0%B8%E9%85%8D%E7%BD%AE.html
    # https://www.enblogs.com/xkus/p/7463135.html

    # Optimize system configuration

    if grep -q "1000000" "/etc/profile"; then
        echo
        green "The system network configuration has been optimized and does not need to be optimized again"
        echo
        sysctl -p
        echo
        exit
    fi

    if [ -z $1 ]; then
        removeOptimizingSystemConfig
    fi



    echo
    green "Start preparing to optimize system network configuration"

    cat >> /etc/sysctl.conf <<-EOF

fs.file-max = 1000000
fs.inotify.max_user_instances = 8192

net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.route.gc_timeout = 100

net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 32768
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_max_orphans = 32768

# forward ipv4
#net.ipv4.ip_forward = 1


EOF



    cat >> /etc/security/limits.conf <<-EOF
* soft nofile 1000000
* hard nofile 1000000
EOF


	echo "ulimit -SHn 1000000" >> /etc/profile
    source /etc/profile


    echo
	sysctl -p

    echo
    green "Completed optimization of system network configuration"
    echo
    rebootSystem "noinfo"

}



function startIpv4(){

    cat >> /etc/sysctl.conf <<-EOF
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_slow_start_after_idle = 0

# forward ipv4

net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0

net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

EOF

}




function Enable_IPv6_Support() {
    if [[ $(sysctl -a | grep 'disable_ipv6.*=.*1') || $(cat /etc/sysctl.{conf,d/*} | grep 'disable_ipv6.*=.*1') ]]; then
        sed -i '/disable_ipv6/d' /etc/sysctl.{conf,d/*}
        echo 'net.ipv6.conf.all.disable_ipv6 = 0' >/etc/sysctl.d/ipv6.conf
        sysctl -w net.ipv6.conf.all.disable_ipv6=0
    fi
}
































isInstallFromRepo="no"
userHomePath="${HOME}/download_linux_kernel"
linuxKernelByUser="elrepo"
linuxKernelToBBRType=""
linuxKernelToInstallVersion="5.15"
linuxKernelToInstallVersionFull=""

elrepo_kernel_name="kernel-ml"
elrepo_kernel_version="5.4.110"

altarch_kernel_name="kernel"
altarch_kernel_version="5.4.105"



function downloadFile(){

    tempUrl=$1
    tempFilename=$(echo "${tempUrl##*/}")

    echo "${userHomePath}/${linuxKernelToInstallVersionFull}/${tempFilename}"
    if [ -f "${userHomePath}/${linuxKernelToInstallVersionFull}/${tempFilename}" ]; then
        green "The file already exists, no need to download, the original download address of the file: $1"
    else
        green "File downloading... Path: $1 "
        wget -N --no-check-certificate -P ${userHomePath}/${linuxKernelToInstallVersionFull} $1
        if [ $? -eq 0 ]; then
            green "File downloaded successfully. ${userHomePath}/${linuxKernelToInstallVersionFull}/${tempFilename}"
        else
            red "File download failed, please check the network or manually download the file to the directory ${userHomePath}/${linuxKernelToInstallVersionFull}"
            promptContinueOpeartion
        fi
    fi
    echo
}


function installKernel(){
    preferIPV4

    if [ "${linuxKernelToBBRType}" = "bbrplus" ]; then
        getVersionBBRPlus
    fi

	if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
        installDebianUbuntuKernel

	elif [[ "${osRelease}" == "centos" ]]; then
        rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

        if [ "${linuxKernelToBBRType}" = "xanmod" ]; then
            red "xanmod kernel does not support CentOS system installation"
            exit 255
        fi

        if [ "${isInstallFromRepo}" = "yes" ]; then
            getLatestCentosKernelVersion
            installCentosKernelFromRepo
        else
            if [ "${linuxKernelToBBRType}" = "bbrplus" ]; then
                echo
            else
                getLatestCentosKernelVersion "manual"
            fi

            installCentosKernelManual
        fi
	fi
}


function getVersionBBRPlus(){
    if [ "${linuxKernelToInstallVersion}" = "6.7" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-6.x_stable")

    elif [ "${linuxKernelToInstallVersion}" = "6.6" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-6.6")

    elif [ "${linuxKernelToInstallVersion}" = "6.1" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-6.1")

    elif [ "${linuxKernelToInstallVersion}" = "5.19" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-5.19")

    elif [ "${linuxKernelToInstallVersion}" = "5.15" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-5.15")

    elif [ "${linuxKernelToInstallVersion}" = "5.10" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-5.10")

    elif [ "${linuxKernelToInstallVersion}" = "5.4" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-5.4")

    elif [ "${linuxKernelToInstallVersion}" = "4.19" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-4.19")

    elif [ "${linuxKernelToInstallVersion}" = "4.14" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus")

    elif [ "${linuxKernelToInstallVersion}" = "4.9" ]; then
        bbrplusKernelVersion=$(getGithubLatestReleaseVersionBBRPlus "UJX6N/bbrplus-4.9")
    fi
    echo
    green "The Linux bbrplus kernel version number compiled by UJX6N is ${bbrplusKernelVersion}"
    echo

}

function getGithubLatestReleaseVersionBBRPlus(){
    wget --no-check-certificate -qO- https://api.github.com/repos/$1/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -d- -f1
    # wget --no-check-certificate -qO- https://api.github.com/repos/UJX6N/bbrplus-5.14/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -d- -f1
}


function getLatestCentosKernelVersion(){

    # https://stackoverflow.com/questions/4988155/is-there-a-bash-command-that-can-tell-the-size-of-a-shell-variable

    elrepo_kernel_version_lt_array=($(wget -qO- https://elrepo.org/linux/kernel/el8/x86_64/RPMS | awk -F'\"kernel-lt-' '/>kernel-lt-[4-9]./{print $2}' | cut -d- -f1 | sort -V))

    # echo ${elrepo_kernel_version_lt_array[@]}

    echo
    if [ ${#elrepo_kernel_version_lt_array[@]} -eq 0 ]; then
        red "Unable to obtain the latest Linux kernel kernel-lt version number from the Centos elrepo source"
    else
        # echo ${elrepo_kernel_version_lt_array[${#elrepo_kernel_version_lt_array[@]} - 1]}
        elrepo_kernel_version_lt=${elrepo_kernel_version_lt_array[${#elrepo_kernel_version_lt_array[@]} - 1]}
        green "The latest Linux kernel kernel-lt version number of the Centos elrepo source is ${elrepo_kernel_version_lt}"
    fi

    if [ -z $1 ]; then
        elrepo_kernel_version_ml_array=($(wget -qO- https://elrepo.org/linux/kernel/el8/x86_64/RPMS | awk -F'>kernel-ml-' '/>kernel-ml-[4-9]./{print $2}' | cut -d- -f1 | sort -V))

        if [ ${#elrepo_kernel_version_ml_array[@]} -eq 0 ]; then
            red "Unable to obtain the latest Linux kernel kernel-ml version number from the Centos elrepo source"
        else
            elrepo_kernel_version_ml=${elrepo_kernel_version_ml_array[-1]}
            green "The latest Linux kernel kernel-ml version number of the Centos elrepo source is ${elrepo_kernel_version_ml}"
        fi
    else
        elrepo_kernel_version_ml_teddysun_ftp_array=($(wget --no-check-certificate -qO- https://fr1.teddyvps.com/kernel/el8 | awk -F'>kernel-ml-' '/>kernel-ml-[4-9]./{print $2}' | cut -d- -f1 | sort -V))
        elrepo_kernel_version_ml_teddysun_ftp_array_lts=($(wget --no-check-certificate -qO- https://fr1.teddyvps.com/kernel/el8 | awk -F'>kernel-ml-' '/>kernel-ml-[4-9]./{print $2}' | grep -v "elrepo" | cut -d- -f1 | sort -V))

        if [ ${#elrepo_kernel_version_ml_teddysun_ftp_array_lts[@]} -eq 0 ]; then
            red "Unable to obtain the latest Linux 5.10 kernel kernel-ml version number of Centos compiled by Teddysun"
        else
            elrepo_kernel_version_ml=${elrepo_kernel_version_ml_teddysun_ftp_array[-1]}
            elrepo_kernel_version_ml_Teddysun_number_temp=$(echo ${elrepo_kernel_version_ml} | grep -oe "\.[0-9]*\." | grep -oe "[0-9]*" )
            elrepo_kernel_version_ml_Teddysun_number_temp_first=${elrepo_kernel_version_ml:0:1}

            if [[ ${elrepo_kernel_version_ml_Teddysun_number_temp_first} == "5" ]]; then
                elrepo_kernel_version_ml_Teddysun_latest_version_middle="19"
                elrepo_kernel_version_ml_Teddysun_latest_version="5.${elrepo_kernel_version_ml_Teddysun_latest_version_middle}"
            else
                elrepo_kernel_version_ml_Teddysun_latest_version_middle=$((elrepo_kernel_version_ml_Teddysun_number_temp-1))
                elrepo_kernel_version_ml_Teddysun_latest_version="6.${elrepo_kernel_version_ml_Teddysun_latest_version_middle}"
            fi




            # https://stackoverflow.com/questions/229551/how-to-check-if-a-string-contains-a-substring-in-bash
            for ver in "${elrepo_kernel_version_ml_teddysun_ftp_array_lts[@]}"; do

                if [[ ${ver} == *"5.10.222"* ]]; then
                    # echo "Linux 5.10 kernel version that matches the selected version: ${ver}"
                    elrepo_kernel_version_ml_Teddysun510=${ver}
                fi

                if [[ ${ver} == *"5.15.163"* ]]; then
                    # echo "Linux 5.15 kernel version that matches the selected version: ${ver}"
                    elrepo_kernel_version_ml_Teddysun515=${ver}
                fi

                if [[ ${ver} == *"6.1.100"* ]]; then
                    # echo "Linux 6.1 kernel version that matches the selected version: ${ver}"
                    elrepo_kernel_version_ml_Teddysun61=${ver}
                fi

                if [[ ${ver} == *"6.6.41"* ]]; then
                    # echo "Linux 6.1 kernel version that matches the selected version: ${ver}"
                    elrepo_kernel_version_ml_Teddysun66=${ver}
                fi

                if [[ ${ver} == *"${elrepo_kernel_version_ml_Teddysun_latest_version}"* ]]; then
                    # echo "Linux kernel version matching the selected version: ${ver}, ${elrepo_kernel_version_ml_Teddysun_latest_version}"
                    elrepo_kernel_version_ml_Teddysun_latest=${ver}
                fi

            done

            green "The latest Linux kernel kernel-ml version number of the Centos elrepo source is ${elrepo_kernel_version_ml}"
            green "The latest Linux 5.10 LTS kernel kernel-ml version number of Centos compiled by Teddysun is ${elrepo_kernel_version_ml_Teddysun510}"
            green "The latest Linux 5.15 LTS kernel kernel-ml version number of Centos compiled by Teddysun is ${elrepo_kernel_version_ml_Teddysun515}"
            green "The latest Linux 6.1 LTS kernel kernel-ml version number of Centos compiled by Teddysun is ${elrepo_kernel_version_ml_Teddysun61}"
            green "The latest Linux 6.6 LTS kernel kernel-ml version number of Centos compiled by Teddysun is ${elrepo_kernel_version_ml_Teddysun66}"
            green "The latest Linux 6.xx kernel kernel-ml version number for Centos compiled by Teddysun is ${elrepo_kernel_version_ml_Teddysun_latest}"

        fi
    fi
    echo
}


function installCentosKernelFromRepo(){

    green " =================================================="
    green "Start installing the Linux kernel through the elrepo source, does not support Centos6"
    green " =================================================="

    if [ -n "${osReleaseVersionNoShort}" ]; then

        if [ "${linuxKernelToInstallVersion}" = "5.4" ]; then
            elrepo_kernel_name="kernel-lt"
            elrepo_kernel_version=${elrepo_kernel_version_lt}

        else
            elrepo_kernel_name="kernel-ml"
            elrepo_kernel_version=${elrepo_kernel_version_ml}
        fi

        if [ "${osKernelVersionBackup}" = "${elrepo_kernel_version}" ]; then
            red "The current system kernel version is ${osKernelVersionBackup}, no need to install!"
            promptContinueOpeartion
        fi

        linuxKernelToInstallVersionFull=${elrepo_kernel_version}

        if [ "${osReleaseVersionNoShort}" -eq 7 ]; then
            # https://computingforgeeks.com/install-linux-kernel-5-on-centos-7/

            # https://elrepo.org/linux/kernel/
            # https://elrepo.org/linux/kernel/el7/x86_64/RPMS/

            ${sudoCmd} yum install -y yum-plugin-fastestmirror
            ${sudoCmd} yum install -y https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm

        elif [ "${osReleaseVersionNoShort}" -eq 8 ]; then
            # https://elrepo.org/linux/kernel/el8/x86_64/RPMS/

            ${sudoCmd} yum install -y yum-plugin-fastestmirror
            ${sudoCmd} yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm

        elif [ "${osReleaseVersionNoShort}" -eq 9 ]; then
            # https://elrepo.org/linux/kernel/el8/x86_64/RPMS/

            ${sudoCmd} yum install -y yum-plugin-fastestmirror
            ${sudoCmd} yum install -y https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm

        else
            green " =================================================="
            red "Installing the Linux kernel on versions other than CentOS 7, 8, 9 is not supported"
            green " =================================================="
            exit 255
        fi

        removeCentosKernelMulti
        listAvailableLinuxKernel
        echo
        green " =================================================="
        green "Start installing linux kernel version: ${linuxKernelToInstallVersionFull}"
        echo
        ${sudoCmd} yum -y --enablerepo=elrepo-kernel install ${elrepo_kernel_name}
        ${sudoCmd} yum -y --enablerepo=elrepo-kernel install ${elrepo_kernel_name}-{devel,headers,tools,tools-libs}

        green " =================================================="
        green "Installation of linux kernel ${linuxKernelToInstallVersionFull} succeeded!"
        red "Please check whether the new kernel is installed successfully according to the following information. Do not restart without a new kernel! "
        green " =================================================="
        echo

        showLinuxKernelInfo
        listInstalledLinuxKernel
        removeCentosKernelMulti "kernel"
        listInstalledLinuxKernel
        rebootSystem
    fi
}




function installCentosKernelManual(){

    green " =================================================="
    green "Start manually installing the Linux kernel, does not support Centos6"
    green " =================================================="
    echo

    yum install -y linux-firmware

    mkdir -p ${userHomePath}
    cd ${userHomePath}

    kernelVersionFirstletter=${linuxKernelToInstallVersion:0:1}

    echo
    if [ "${linuxKernelToBBRType}" = "bbrplus" ]; then
        linuxKernelByUser="UJX6N"
        if [ "${linuxKernelToInstallVersion}" = "4.14.129" ]; then
            linuxKernelByUser="cx9208"
        fi
        green "Prepare to download and install the bbrplus ${linuxKernelToInstallVersion} linux kernel from the ${linuxKernelByUser} github website"
    else
        linuxKernelByUserTeddysun=""

        if [[ "${kernelVersionFirstletter}" == "5" || "${kernelVersionFirstletter}" == "6" ]]; then
            linuxKernelByUser="elrepo"

            if [[ "${linuxKernelToInstallVersion}" == "5.10" || "${linuxKernelToInstallVersion}" == "5.15" || "${linuxKernelToInstallVersion}" == "5.19" ]]; then
                linuxKernelByUserTeddysun="Teddysun"
            fi
        else
            linuxKernelByUser="altarch"
        fi

        if [ "${linuxKernelByUserTeddysun}" = "Teddysun" ]; then
            green "Ready to download the linux ${linuxKernelByUser} kernel from the Teddysun website and install it"
        else
            green "Ready to download and install the Linux kernel from the ${linuxKernelByUser} website"
        fi

    fi
    echo

    if [ "${linuxKernelByUser}" = "elrepo" ]; then
        #elrepo

        if [ "${linuxKernelToInstallVersion}" = "5.4" ]; then
            elrepo_kernel_name="kernel-lt"
            elrepo_kernel_version=${elrepo_kernel_version_lt}
            elrepo_kernel_filename="elrepo."
            ELREPODownloadUrl="https://elrepo.org/linux/kernel/el${osReleaseVersionNoShort}/x86_64/RPMS"

            # https://elrepo.org/linux/kernel/el7/x86_64/RPMS/
            # https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-lt-5.4.105-1.el7.elrepo.x86_64.rpm
            # https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-lt-tools-5.4.109-1.el7.elrepo.x86_64.rpm
            # https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-lt-tools-libs-5.4.109-1.el7.elrepo.x86_64.rpm

        elif [ "${linuxKernelToInstallVersion}" = "5.10" ]; then
            elrepo_kernel_name="kernel-ml"
            elrepo_kernel_version=${elrepo_kernel_version_ml_Teddysun510}
            elrepo_kernel_filename=""
            ELREPODownloadUrl="https://dl.lamp.sh/kernel/el${osReleaseVersionNoShort}"

            # https://dl.lamp.sh/kernel/el7/kernel-ml-5.10.37-1.el7.x86_64.rpm
            # https://dl.lamp.sh/kernel/el8/kernel-ml-5.10.27-1.el8.x86_64.rpm

        elif [ "${linuxKernelToInstallVersion}" = "5.15" ]; then
            elrepo_kernel_name="kernel-ml"
            elrepo_kernel_version=${elrepo_kernel_version_ml_Teddysun515}
            elrepo_kernel_filename=""
            ELREPODownloadUrl="https://dl.lamp.sh/kernel/el${osReleaseVersionNoShort}"

        elif [ "${linuxKernelToInstallVersion}" = "6.1" ]; then
            elrepo_kernel_name="kernel-ml"
            elrepo_kernel_version=${elrepo_kernel_version_ml_Teddysun61}
            elrepo_kernel_filename=""
            ELREPODownloadUrl="https://dl.lamp.sh/kernel/el${osReleaseVersionNoShort}"

        elif [ "${linuxKernelToInstallVersion}" = "6.6" ]; then
            elrepo_kernel_name="kernel-ml"
            elrepo_kernel_version=${elrepo_kernel_version_ml_Teddysun66}
            elrepo_kernel_filename=""
            ELREPODownloadUrl="https://dl.lamp.sh/kernel/el${osReleaseVersionNoShort}"

        elif [ "${linuxKernelToInstallVersion}" = "${elrepo_kernel_version_ml_Teddysun_latest_version}" ]; then
            elrepo_kernel_name="kernel-ml"
            elrepo_kernel_version=${elrepo_kernel_version_ml_Teddysun_latest}
            elrepo_kernel_filename=""
            ELREPODownloadUrl="https://fr1.teddyvps.com/kernel/el${osReleaseVersionNoShort}"

            # https://fr1.teddyvps.com/kernel/el7/kernel-ml-5.12.14-1.el7.x86_64.rpm

        else
            elrepo_kernel_name="kernel-ml"
            elrepo_kernel_version=${elrepo_kernel_version_ml}
            elrepo_kernel_filename="elrepo."
            ELREPODownloadUrl="https://fr1.teddyvps.com/kernel/el${osReleaseVersionNoShort}"

            # https://fr1.teddyvps.com/kernel/el7/kernel-ml-5.13.0-1.el7.elrepo.x86_64.rpm
        fi

        linuxKernelToInstallVersionFull=${elrepo_kernel_version}

        mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
        cd ${userHomePath}/${linuxKernelToInstallVersionFull}

        echo
        echo "++++++++++++ elrepo_kernel_version ${elrepo_kernel_version}"
        echo

        if [ "${osReleaseVersionNoShort}" -eq 7 ]; then
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-${elrepo_kernel_version}-1.el7.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-devel-${elrepo_kernel_version}-1.el7.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-headers-${elrepo_kernel_version}-1.el7.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-tools-${elrepo_kernel_version}-1.el7.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-tools-libs-${elrepo_kernel_version}-1.el7.${elrepo_kernel_filename}x86_64.rpm

        elif [ "${osReleaseVersionNoShort}" -eq 8 ]; then

            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-devel-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-headers-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-core-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-modules-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-tools-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-tools-libs-${elrepo_kernel_version}-1.el8.${elrepo_kernel_filename}x86_64.rpm

        elif [ "${osReleaseVersionNoShort}" -eq 9 ]; then
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-${elrepo_kernel_version}-1.el9.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-devel-${elrepo_kernel_version}-1.el9.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-headers-${elrepo_kernel_version}-1.el9.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-core-${elrepo_kernel_version}-1.el9.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-modules-${elrepo_kernel_version}-1.el9.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-modules-extra-${elrepo_kernel_version}-1.el9.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-tools-${elrepo_kernel_version}-1.el9.${elrepo_kernel_filename}x86_64.rpm
            downloadFile ${ELREPODownloadUrl}/${elrepo_kernel_name}-tools-libs-${elrepo_kernel_version}-1.el9.${elrepo_kernel_filename}x86_64.rpm

            # https://fr1.teddyvps.com/kernel/el9/kernel-ml-6.1.0-1.el9.elrepo.x86_64.rpm
            # https://fr1.teddyvps.com/kernel/el9/kernel-ml-modules-extra-6.1.0-1.el9.elrepo.x86_64.rpm
            # https://fr1.teddyvps.com/kernel/el9/kernel-ml-tools-libs-devel-6.1.0-1.el9.elrepo.x86_64.rpm
        fi


        removeCentosKernelMulti
        echo
        green " =================================================="
        green "Start installing linux kernel version: ${linuxKernelToInstallVersionFull}"
        echo

        if [ "${osReleaseVersionNoShort}" -eq 8 ]; then
            rpm -ivh --force --nodeps ${elrepo_kernel_name}-core-${elrepo_kernel_version}-*.rpm
        fi

        rpm -ivh --force --nodeps ${elrepo_kernel_name}-${elrepo_kernel_version}-*.rpm
        rpm -ivh --force --nodeps ${elrepo_kernel_name}-*.rpm


    elif [ "${linuxKernelByUser}" = "altarch" ]; then
        #altarch

        if [ "${linuxKernelToInstallVersion}" = "4.14" ]; then
            altarch_kernel_version="4.14.119-200"
            altarchDownloadUrl="https://vault.centos.org/altarch/7.6.1810/kernel/x86_64/Packages"

            # https://vault.centos.org/altarch/7.6.1810/kernel/x86_64/Packages/kernel-4.14.119-200.el7.x86_64.rpm
        elif [ "${linuxKernelToInstallVersion}" = "4.19" ]; then
            altarch_kernel_version="4.19.113-300"
            altarchDownloadUrl="https://vault.centos.org/altarch/7.8.2003/kernel/x86_64/Packages"

            # https://vault.centos.org/altarch/7.8.2003/kernel/x86_64/Packages/kernel-4.19.113-300.el7.x86_64.rpm
        else
            altarch_kernel_version="5.4.105"
            altarchDownloadUrl="http://mirror.centos.org/altarch/7/kernel/x86_64/Packages"

            # http://mirror.centos.org/altarch/7/kernel/x86_64/Packages/kernel-5.4.96-200.el7.x86_64.rpm
        fi

        linuxKernelToInstallVersionFull=$(echo ${altarch_kernel_version} | cut -d- -f1)

        mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
        cd ${userHomePath}/${linuxKernelToInstallVersionFull}

        if [ "${osReleaseVersionNoShort}" -eq 7 ]; then

            if [ "$kernelVersionFirstletter" = "5" ]; then
                # http://mirror.centos.org/altarch/7/kernel/x86_64/Packages/

                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-${altarch_kernel_version}-200.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-core-${altarch_kernel_version}-200.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-devel-${altarch_kernel_version}-200.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-headers-${altarch_kernel_version}-200.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-modules-${altarch_kernel_version}-200.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-tools-${altarch_kernel_version}-200.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-tools-libs-${altarch_kernel_version}-200.el7.x86_64.rpm

            else
                # https://vault.centos.org/altarch/7.6.1810/kernel/x86_64/Packages/
                # https://vault.centos.org/altarch/7.6.1810/kernel/x86_64/Packages/kernel-4.14.119-200.el7.x86_64.rpm

                # https://vault.centos.org/altarch/7.8.2003/kernel/x86_64/Packages/
                # https://vault.centos.org/altarch/7.8.2003/kernel/i386/Packages/kernel-4.19.113-300.el7.i686.rpm
                # https://vault.centos.org/altarch/7.8.2003/kernel/x86_64/Packages/kernel-4.19.113-300.el7.x86_64.rpm
                # http://ftp.iij.ad.jp/pub/linux/centos-vault/altarch/7.8.2003/kernel/i386/Packages/kernel-4.19.113-300.el7.i686.rpm

                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-${altarch_kernel_version}.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-core-${altarch_kernel_version}.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-devel-${altarch_kernel_version}.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-headers-${altarch_kernel_version}.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-modules-${altarch_kernel_version}.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-tools-${altarch_kernel_version}.el7.x86_64.rpm
                downloadFile ${altarchDownloadUrl}/${altarch_kernel_name}-tools-libs-${altarch_kernel_version}.el7.x86_64.rpm

            fi

        else
            red "No ${linuxKernelToInstallVersion} Kernel found for Centos 8 from altarch repository"
            exit 255
        fi

        removeCentosKernelMulti
        echo
        green " =================================================="
        green "Start installing linux kernel version: ${linuxKernelToInstallVersionFull}"
        echo
        rpm -ivh --force --nodeps ${altarch_kernel_name}-core-${altarch_kernel_version}*
        rpm -ivh --force --nodeps ${altarch_kernel_name}-*
        # yum install -y kernel-*


    elif [ "${linuxKernelByUser}" = "cx9208" ]; then

        linuxKernelToInstallVersionFull="4.14.129-bbrplus"

        if [ "${osReleaseVersionNoShort}" -eq 7 ]; then
            mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
            cd ${userHomePath}/${linuxKernelToInstallVersionFull}

            # https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/bbrplus/centos/7/kernel-4.14.129-bbrplus.rpm
            # https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/bbrplus/centos/7/kernel-headers-4.14.129-bbrplus.rpm

            bbrplusDownloadUrl="https://raw.githubusercontent.com/cx9208/Linux-NetSpeed/master/bbrplus/centos/7"

            downloadFile ${bbrplusDownloadUrl}/kernel-${linuxKernelToInstallVersionFull}.rpm
            downloadFile ${bbrplusDownloadUrl}/kernel-headers-${linuxKernelToInstallVersionFull}.rpm

            removeCentosKernelMulti
            echo
            green " =================================================="
            green "Start installing linux kernel version: ${linuxKernelToInstallVersionFull}"
            echo
            rpm -ivh --force --nodeps kernel-${linuxKernelToInstallVersionFull}.rpm
            rpm -ivh --force --nodeps kernel-headers-${linuxKernelToInstallVersionFull}.rpm
        else
            red "No ${linuxKernelToInstallVersion} Kernel for Centos 8 was found from cx9208's github website"
            exit 255
        fi

    elif [ "${linuxKernelByUser}" = "UJX6N" ]; then

        linuxKernelToInstallVersionFull="${bbrplusKernelVersion}-bbrplus"

        mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
        cd ${userHomePath}/${linuxKernelToInstallVersionFull}


        if [ "${linuxKernelToInstallVersion}" = "6.7" ]; then
            bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/${linuxKernelToInstallVersionFull}"

        elif [ "${linuxKernelToInstallVersion}" = "4.14" ]; then
            bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus/releases/download/${linuxKernelToInstallVersionFull}"

        else
            bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus-${linuxKernelToInstallVersion}/releases/download/${linuxKernelToInstallVersionFull}"
        fi



        if [ "${osReleaseVersionNoShort}" -eq 7 ]; then

            # https://github.com/UJX6N/bbrplus-5.14/releases/download/5.14.15-bbrplus/CentOS-7_Required_kernel-bbrplus-5.14.15-1.bbrplus.el7.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.15/releases/download/5.15.86-bbrplus/CentOS-7_Required_kernel-5.15.86-bbrplus.el7.x86_64.rpm

            # https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/6.7.4-bbrplus/CentOS-7_Required_kernel-6.7.4-bbrplus.el7.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-6.1/releases/download/6.1.28-bbrplus/CentOS-7_Required_kernel-6.1.28-bbrplus.el7.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.76-bbrplus/CentOS-7_Required_kernel-bbrplus-5.10.76-1.bbrplus.el7.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.27-bbrplus/CentOS-7_Optional_kernel-bbrplus-devel-5.10.27-1.bbrplus.el7.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.27-bbrplus/CentOS-7_Optional_kernel-bbrplus-headers-5.10.27-1.bbrplus.el7.x86_64.rpm

            if [[ "${linuxKernelToInstallVersion}" == "5.10" || "${linuxKernelToInstallVersion}" == "5.15" || "${linuxKernelToInstallVersion}" == "6.1" || "${linuxKernelToInstallVersion}" == "6.6" || "${linuxKernelToInstallVersion}" == "6.7" ]]; then
                # https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/6.7.4-bbrplus/CentOS-7_Required_kernel-6.7.4-bbrplus.el7.x86_64.rpm
                # https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/6.7.4-bbrplus/CentOS-7_Optional_kernel-headers-6.7.4-bbrplus.el7.x86_64.rpm
                # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.16-bbrplus/CentOS-7_Required_kernel-5.10.162-bbrplus.el7.x86_64.rpm
                # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.162-bbrplus/CentOS-7_Optional_kernel-headers-5.10.162-bbrplus.el7.x86_64.rpm

                downloadFile ${bbrplusDownloadUrl}/CentOS-7_Required_kernel-${bbrplusKernelVersion}-bbrplus.el7.x86_64.rpm
                downloadFile ${bbrplusDownloadUrl}/CentOS-7_Optional_kernel-headers-${bbrplusKernelVersion}-bbrplus.el7.x86_64.rpm
            else
                # https://github.com/UJX6N/bbrplus-4.9/releases/download/4.9.337-bbrplus/CentOS-7_Optional_kernel-bbrplus-devel-4.9.337-1.bbrplus.el7.x86_64.rpm

                downloadFile ${bbrplusDownloadUrl}/CentOS-7_Required_kernel-bbrplus-${bbrplusKernelVersion}-1.bbrplus.el7.x86_64.rpm
                downloadFile ${bbrplusDownloadUrl}/CentOS-7_Optional_kernel-bbrplus-devel-${bbrplusKernelVersion}-1.bbrplus.el7.x86_64.rpm
                downloadFile ${bbrplusDownloadUrl}/CentOS-7_Optional_kernel-bbrplus-headers-${bbrplusKernelVersion}-1.bbrplus.el7.x86_64.rpm
            fi




            removeCentosKernelMulti
            echo
            green " =================================================="
            green "Start installing linux kernel version: ${linuxKernelToInstallVersionFull}"
            echo
            rpm -ivh --force --nodeps CentOS-7_Required_kernel-bbrplus-${bbrplusKernelVersion}-1.bbrplus.el7.x86_64.rpm
            rpm -ivh --force --nodeps *.rpm
        else

            if [[ "${kernelVersionFirstletter}" == "5" || "${kernelVersionFirstletter}" == "6" ]]; then
                echo
            else
                red "No ${linuxKernelToInstallVersion} Kernel for Centos 8 was found from UJX6N's github website"
                exit 255
            fi

            # https://github.com/UJX6N/bbrplus-5.14/releases/download/5.14.18-bbrplus/CentOS-8_Required_kernel-bbrplus-core-5.14.18-1.bbrplus.el8.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.14/releases/download/5.14.18-bbrplus/CentOS-8_Required_kernel-bbrplus-modules-5.14.18-1.bbrplus.el8.x86_64.rpm


            # https://github.com/UJX6N/bbrplus-5.14/releases/download/5.14.18-bbrplus/CentOS-8_Optional_kernel-bbrplus-5.14.18-1.bbrplus.el8.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.14/releases/download/5.14.18-bbrplus/CentOS-8_Optional_kernel-bbrplus-devel-5.14.18-1.bbrplus.el8.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.14/releases/download/5.14.18-bbrplus/CentOS-8_Optional_kernel-bbrplus-headers-5.14.18-1.bbrplus.el8.x86_64.rpm

            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.27-bbrplus/CentOS-8_Optional_kernel-bbrplus-modules-5.10.27-1.bbrplus.el8.x86_64.rpm
            # https://github.com/UJX6N/bbrplus-5.14/releases/download/5.14.18-bbrplus/CentOS-8_Optional_kernel-bbrplus-modules-extra-5.14.18-1.bbrplus.el8.x86_64.rpm


            if [[ "${linuxKernelToInstallVersion}" == "5.10" || "${linuxKernelToInstallVersion}" == "5.15" || "${linuxKernelToInstallVersion}" == "6.1" || "${linuxKernelToInstallVersion}" == "6.6" || "${linuxKernelToInstallVersion}" == "6.7" ]]; then
                # https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/6.7.4-bbrplus/CentOS-Stream-8_Required_kernel-6.7.4-bbrplus.el8.x86_64.rpm
                # https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/6.6.1-bbrplus/CentOS-Stream-8_Required_kernel-6.6.1-bbrplus.el8.x86_64.rpm
                # https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/6.4.3-bbrplus/CentOS-Stream-8_Required_kernel-6.4.3-bbrplus.el8.x86_64.rpm
                # https://github.com/UJX6N/bbrplus-6.1/releases/download/6.1.28-bbrplus/CentOS-Stream-8_Required_kernel-6.1.28-bbrplus.el8.x86_64.rpm
                # https://github.com/UJX6N/bbrplus-5.15/releases/download/5.15.86-bbrplus/CentOS-Stream-8_Required_kernel-5.15.86-bbrplus.el8.x86_64.rpm
                # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.162-bbrplus/CentOS-Stream-8_Optional_kernel-headers-5.10.162-bbrplus.el8.x86_64.rpm

                downloadFile ${bbrplusDownloadUrl}/CentOS-Stream-8_Required_kernel-${bbrplusKernelVersion}-bbrplus.el8.x86_64.rpm
                downloadFile ${bbrplusDownloadUrl}/CentOS-Stream-8_Optional_kernel-headers-${bbrplusKernelVersion}-bbrplus.el8.x86_64.rpm

            else
                # https://github.com/UJX6N/bbrplus-5.19/releases/download/5.19.17-bbrplus/CentOS-8_Required_kernel-bbrplus-core-5.19.17-1.bbrplus.el8.x86_64.rpm


                downloadFile ${bbrplusDownloadUrl}/CentOS-8_Required_kernel-bbrplus-core-${bbrplusKernelVersion}-1.bbrplus.el8.x86_64.rpm
                downloadFile ${bbrplusDownloadUrl}/CentOS-8_Required_kernel-bbrplus-modules-${bbrplusKernelVersion}-1.bbrplus.el8.x86_64.rpm

                downloadFile ${bbrplusDownloadUrl}/CentOS-8_Optional_kernel-bbrplus-${bbrplusKernelVersion}-1.bbrplus.el8.x86_64.rpm
                downloadFile ${bbrplusDownloadUrl}/CentOS-8_Optional_kernel-bbrplus-devel-${bbrplusKernelVersion}-1.bbrplus.el8.x86_64.rpm
                downloadFile ${bbrplusDownloadUrl}/CentOS-8_Optional_kernel-bbrplus-headers-${bbrplusKernelVersion}-1.bbrplus.el8.x86_64.rpm
                # downloadFile ${bbrplusDownloadUrl}/CentOS-8_Optional_kernel-bbrplus-modules-${bbrplusKernelVersion}-1.bbrplus.el8.x86_64.rpm
                downloadFile ${bbrplusDownloadUrl}/CentOS-8_Optional_kernel-bbrplus-modules-extra-${bbrplusKernelVersion}-1.bbrplus.el8.x86_64.rpm
            fi


            removeCentosKernelMulti
            echo
            green " =================================================="
            green "Start installing linux kernel version: ${linuxKernelToInstallVersionFull}"
            echo
            rpm -ivh --force --nodeps CentOS-8_Required_kernel-bbrplus-core-${bbrplusKernelVersion}-1.bbrplus.el8.x86_64.rpm
            rpm -ivh --force --nodeps *.rpm

        fi

    fi;

    updateGrubConfig

    green " =================================================="
    green "Installation of linux kernel ${linuxKernelToInstallVersionFull} succeeded!"
    red "Please check whether the new kernel is installed successfully according to the following information. Do not restart without a new kernel! "
    green " =================================================="
    echo

    showLinuxKernelInfo
    removeCentosKernelMulti "kernel"
    listInstalledLinuxKernel
    rebootSystem
}



function removeCentosKernelMulti(){
    listInstalledLinuxKernel

    if [ -z $1 ]; then
        red "Starting to delete kernel-header kernel-devel kernel-tools kernel-tools-libs kernel, recommended to delete"
    else
        red "Starting to delete the kernel, it is recommended to delete"
    fi

    red " Note: Deleting the kernel is risky and may cause the VPS to fail to boot, please make a backup first! "
    read -p "Do you want to delete the kernel? Press Enter to delete the kernel by default. Please enter [Y/n]:" isContinueDelKernelInput
	isContinueDelKernelInput=${isContinueDelKernelInput:-Y}

    echo

	if [[ $isContinueDelKernelInput == [Yy] ]]; then

        if [ -z $1 ]; then
            removeCentosKernel "kernel-devel"
            removeCentosKernel "kernel-header"
            removeCentosKernel "kernel-tools"

            removeCentosKernel "kernel-ml-devel"
            removeCentosKernel "kernel-ml-header"
            removeCentosKernel "kernel-ml-tools"

            removeCentosKernel "kernel-lt-devel"
            removeCentosKernel "kernel-lt-header"
            removeCentosKernel "kernel-lt-tools"

            removeCentosKernel "kernel-bbrplus-devel"
            removeCentosKernel "kernel-bbrplus-headers"
            removeCentosKernel "kernel-bbrplus-modules"
        else
            removeCentosKernel "kernel"
        fi
	fi
    echo
}

function removeCentosKernel(){

    # Yes, I used yum localinstall kernel-ml-* and then specified the order. I couldn't use the rpm -ivh package name because it said kernel-headers conflicted.
    # Enter rpm -e --nodeps kernel-headers and it will prompt that the package cannot be loaded.

    # At this time, you need to specify the complete rpm package name that has been installed.
    # rpm -qa | grep kernel
    # You can view it. For example: kernel-ml-headers-5.10.16-1.el7.elrepo.x86_64
    # If you want to delete it by force, the command is: rpm -e --nodeps kernel-ml-headers-5.10.16-1.el7.elrepo.x86_64

    # ${sudoCmd} yum remove kernel-ml kernel-ml-{devel,headers,perf}
    # ${sudoCmd} rpm -e --nodeps kernel-headers
    # ${sudoCmd} rpm -e --nodeps kernel-ml-headers-${elrepo_kernel_version}-1.el7.elrepo.x86_64

    removeKernelNameText="kernel"
    removeKernelNameText=$1
    grepExcludelinuxKernelVersion=$(echo ${linuxKernelToInstallVersionFull} | cut -d- -f1)


    # echo "rpm -qa | grep ${removeKernelNameText} | grep -v ${grepExcludelinuxKernelVersion} | grep -v noarch | wc -l"
    rpmOldKernelNumber=$(rpm -qa | grep "${removeKernelNameText}" | grep -v "${grepExcludelinuxKernelVersion}" | grep -v "noarch" | wc -l)
    rpmOLdKernelNameList=$(rpm -qa | grep "${removeKernelNameText}" | grep -v "${grepExcludelinuxKernelVersion}" | grep -v "noarch")
    # echo "${rpmOLdKernelNameList}"

    # https://stackoverflow.com/questions/29269259/extract-value-of-column-from-a-line-variable


    if [ "${rpmOldKernelNumber}" -gt "0" ]; then

        yellow "=========== Prepare to start deleting the old kernel ${removeKernelNameText} ${osKernelVersionBackup}, the new kernel version to be installed is: ${grepExcludelinuxKernelVersion}"
        red "The current system's old kernels ${removeKernelNameText} ${osKernelVersionBackup} have ${rpmOldKernelNumber} that need to be deleted"
        echo
        for((integer = 1; integer <= ${rpmOldKernelNumber}; integer++)); do
            rpmOLdKernelName=$(awk "NR==${integer}" <<< "${rpmOLdKernelNameList}")
            green "+++++ Starting to uninstall kernel number ${integer}: ${rpmOLdKernelName}. Command: rpm --nodeps -e ${rpmOLdKernelName}"
            rpm --nodeps -e ${rpmOLdKernelName}
            green "++++++ Uninstalled kernel ${integer} ${rpmOLdKernelName} +++++"
            echo
        done
        yellow "=========== A total of ${rpmOldKernelNumber} old kernels ${removeKernelNameText} ${osKernelVersionBackup} have been uninstalled"
        echo
    else
        red "The number of old system kernels ${removeKernelNameText} ${osKernelVersionBackup} that need to be uninstalled is 0!"
    fi

    echo
}



# Update the boot file grub.conf
updateGrubConfig(){
	if [[ "${osRelease}" == "centos" ]]; then

        # if [ ! -f "/boot/grub/grub.conf" ]; then
        # red "File '/boot/grub/grub.conf' not found, The file was not found"
        # else
        # sed -i 's/^default=.*/default=0/g' /boot/grub/grub.conf
        # grub2-set-default 0

        # awk -F\' '$1=="menuentry " {print i++ " : " $2}' /boot/grub2/grub.cfg
        # egrep ^menuentry /etc/grub2.cfg | cut -f 2 -d \'

        # grub2-editenv list
        #fi

        # https://blog.51cto.com/foxhound/2551477
        # Check if the latest 5.10.16 is ranked first, that is, 0th. If it is, execute: grub2-set-default 0, and then check again: grub2-editenv list

        green " =================================================="
        echo

        if [[ ${osReleaseVersionNoShort} = "6" ]]; then
            red "Not supported on CentOS 6"
            exit 255
        else
			if [ -f "/boot/grub2/grub.cfg" ]; then
				grub2-mkconfig -o /boot/grub2/grub.cfg
				grub2-set-default 0
			elif [ -f "/boot/efi/EFI/centos/grub.cfg" ]; then
				grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
				grub2-set-default 0
			elif [ -f "/boot/efi/EFI/redhat/grub.cfg" ]; then
				grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
				grub2-set-default 0
			else
				red "/boot/grub2/grub.cfg The file was not found, please check."
				exit
			fi

            echo
            green "Check the current grub menu boot item list and make sure the newly installed kernel ${linuxKernelToInstallVersionFull} is the first item"
            # grubby --info=ALL|awk -F= '$1=="kernel" {print i++ " : " $2}'
            awk -F\' '$1=="menuentry " {print i++ " : " $2}' /boot/grub2/grub.cfg

            echo
            green "Check whether the current grub boot order is set as the first item"
            echo "grub2-editenv list"
            grub2-editenv list
            green " =================================================="
            echo
        fi

    elif [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
        echo
        echo "/usr/sbin/update-grub"
        /usr/sbin/update-grub
    fi
}
































function getLatestUbuntuKernelVersion(){
    ubuntuKernelLatestVersionArray=($(wget -qO- https://kernel.ubuntu.com/~kernel-ppa/mainline/ | awk -F'\"v' '/v[4-9]\./{print $2}' | cut -d/ -f1 | grep -v - | sort -V))
    ubuntuKernelLatestVersion=${ubuntuKernelLatestVersionArray[${#ubuntuKernelLatestVersionArray[@]} - 1]}
    echo
    green "Ubuntu mainline latest Linux kernel kernel version number is ${ubuntuKernelLatestVersion}"

    for ver in "${ubuntuKernelLatestVersionArray[@]}"; do

        if [[ ${ver} == *"${linuxKernelToInstallVersion}"* ]]; then
            # echo "Linux kernel version that matches the selected version: ${ver}, the selected version is ${linuxKernelToInstallVersion}"
            ubuntuKernelVersion=${ver}
        fi
    done


    green "Kernel version to be installed: ${ubuntuKernelVersion}"
    ubuntuDownloadUrl="https://kernel.ubuntu.com/~kernel-ppa/mainline/v${ubuntuKernelVersion}/amd64"
    echo
    echo "wget â€‹â€‹-qO- ${ubuntuDownloadUrl} | awk -F'>' '/-[4-9]\./{print \$7}' | cut -d'<' -f1 | grep -v lowlatency"
    ubuntuKernelDownloadUrlArray=($(wget -qO- ${ubuntuDownloadUrl} | awk -F'>' '/-[4-9]\./{print $7}' | cut -d'<' -f1 | grep -v lowlatency ))

    # echo "${ubuntuKernelDownloadUrlArray[*]}"
    echo
}

function installDebianUbuntuKernel(){

    ${sudoCmd} apt-get clean
    ${sudoCmd} apt-get update
    ${sudoCmd} apt-get install -y dpkg

    # https://kernel.ubuntu.com/~kernel-ppa/mainline/

    # https://unix.stackexchange.com/questions/545601/how-to-upgrade-the-debian-10-kernel-from-backports-without-recompiling-it-from-s

    # https://askubuntu.com/questions/119080/how-to-update-kernel-to-the-latest-mainline-version-without-any-distro-upgrade

    # https://sypalo.com/how-to-upgrade-ubuntu

    if [ "${isInstallFromRepo}" = "yes" ]; then

        if [ "${linuxKernelToBBRType}" = "xanmod" ]; then

            green " =================================================="
            green "Start preparing to install the Linux kernel ${linuxKernelToInstallVersion} from the XanMod official source"
            green " =================================================="

            # https://xanmod.org/


            # echo 'deb http://deb.xanmod.org releases main' > /etc/apt/sources.list.d/xanmod-kernel.list
            # wget -qO - https://dl.xanmod.org/gpg.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/xanmod-kernel.gpg add -

            wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
            echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list

            ${sudoCmd} apt update -y

            listAvailableLinuxKernel "xanmod"

            linuxKernelToInstallVersionFull=${linuxKernelToInstallVersion}
            echo
            green " =================================================="
            green "Start installing the linux kernel version: XanMod ${linuxKernelToInstallVersionFull}"
            echo

            if [ "${linuxKernelToInstallVersion}" = "6.6" ]; then
                ${sudoCmd} apt install -y linux-xanmod-lts-x64v3
            elif [ "${linuxKernelToInstallVersion}" = "6.11" ]; then
                ${sudoCmd} apt install -y linux-xanmod-x64v3
            else
                ${sudoCmd} apt install -y linux-xanmod
            fi

            listInstalledLinuxKernel
            rebootSystem
        else

            if [ "${linuxKernelToInstallVersion}" = "5.10" ]; then
                debianKernelVersion="5.10.0-0"
                if [ "${osReleaseVersionNo}" = "11" ]; then
                    debianKernelVersion="5.10.0-16"
                fi
                # linux-image-5.10.0-0.bpo.15-amd64
            elif [ "${linuxKernelToInstallVersion}" = "5.19" ]; then
                debianKernelVersion="5.16.0-0"
                if [ "${osReleaseVersionNo}" = "11" ]; then
                    debianKernelVersion="5.19.0-0"
                fi

            elif [ "${linuxKernelToInstallVersion}" = "4.19" ]; then
                debianKernelVersion="4.19.0-21"

            elif [ "${linuxKernelToInstallVersion}" = "6.1" ]; then
                debianKernelVersion="6.1.0-0"
                if [ "${osReleaseVersionNo}" = "11" ]; then
                    debianKernelVersion="6.1.0-20"
                fi
                if [ "${osReleaseVersionNo}" = "12" ]; then
                    debianKernelVersion="6.1.0-25"
                fi
            else
                debianKernelVersion="6.6.0-0"
                if [ "${osReleaseVersionNo}" = "11" ]; then
                    debianKernelVersion="6.6.0-0"
                fi
                if [ "${osReleaseVersionNo}" = "12" ]; then
                    debianKernelVersion="6.6.0-0"
                fi
            fi



            green " =================================================="
            green "Start installing the Linux kernel ${debianKernelVersion} from the Debian official source"
            green " =================================================="

            if [ "${osKernelVersionBackup}" = "${debianKernelVersion}" ]; then
                red "The current system kernel version is ${osKernelVersionBackup}, no need to install!"
                promptContinueOpeartion
            fi

            linuxKernelToInstallVersionFull=${debianKernelVersion}

            echo "deb http://deb.debian.org/debian $osReleaseVersionCodeName-backports main contrib non-free" > /etc/apt/sources.list.d/$osReleaseVersionCodeName-backports.list
            echo "deb-src http://deb.debian.org/debian $osReleaseVersionCodeName-backports main contrib non-free" >> /etc/apt/sources.list.d/$osReleaseVersionCodeName-backports.list
            ${sudoCmd} apt update -y

            listAvailableLinuxKernel

            echo
            green " apt --fix-broken install"
            ${sudoCmd} apt --fix-broken install

            #green " apt install -y -t $osReleaseVersionCodeName-backports linux-image-amd64"
            #${sudoCmd} apt install -y -t $osReleaseVersionCodeName-backports linux-image-amd64

            #green " apt install -y -t $osReleaseVersionCodeName-backports firmware-linux firmware-linux-nonfree"
            #${sudoCmd} apt install -y -t $osReleaseVersionCodeName-backports firmware-linux firmware-linux-nonfree

            echo
            echo "dpkg --get-selections | grep linux-image-${debianKernelVersion} | awk '/linux-image-[4-9]./{print \$1}' | awk -F'linux-image-' '{print \$2}' "
            #debianKernelVersionPackageName=$(dpkg --get-selections | grep "${debianKernelVersion}" | awk '/linux-image-[4-9]./{print $1}' | awk -F'linux-image-' '{print $2}')
            echo "apt-cache search linux-image | grep ${debianKernelVersion} | awk '/linux-image-[4-9]\.[0-9]+\.[0-9]+/{print \$1}' | awk '/[0-9]+-amd64$/{print \$1}' | awk -F'linux-image-' '{print \$2}' | sort -V | tail -1"
            debianKernelVersionPackageName=$(apt-cache search linux-image | grep "${debianKernelVersion}" | awk '/linux-image-[4-9]\.[0-9]+\.[0-9]+/{print $1}' | awk '/[0-9]+-amd64$/{print $1}' | awk -F'linux-image-' '{print $2}' | sort -V | tail -1)


            echo
            green "Debian official source installation linux kernel version: ${debianKernelVersionPackageName}"
            echo

            green "Start installing linux-image. The command is: apt install -y linux-image-${debianKernelVersionPackageName}"
            ${sudoCmd} apt install -y linux-image-${debianKernelVersionPackageName}
            echo
            green "Start installing linux-headers. The command is: apt install -y linux-headers-${debianKernelVersionPackageName}"
            ${sudoCmd} apt install -y linux-headers-${debianKernelVersionPackageName}
            # ${sudoCmd} apt-get -y dist-upgrade

        fi

    else
        echo
        green " =================================================="
        green "Start manual installation of the Linux kernel"
        green " =================================================="
        echo

        mkdir -p ${userHomePath}
        cd ${userHomePath}

        linuxKernelByUser=""

        if [ "${linuxKernelToBBRType}" = "bbrplus" ]; then
            linuxKernelByUser="UJX6N"
            if [ "${linuxKernelToInstallVersion}" = "4.14.129" ]; then
                linuxKernelByUser="cx9208"
            fi
            green "Prepare to download and install the bbr plus linux kernel from the ${linuxKernelByUser} github website"
        else
            green "Ready to download and install the Linux kernel from the Ubuntu kernel-ppa mainline website"
        fi
        echo

        if [[ "${osRelease}" == "ubuntu" && ${osReleaseVersionNo} == "16.04" ]]; then

            if [ -f "${userHomePath}/libssl1.1_1.1.0g-2ubuntu4_amd64.deb" ]; then
                green "The file already exists, no need to download, the original download address of the file: http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb "
            else
                green "File downloading... Download address: http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb "
                wget -P ${userHomePath} http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb
            fi

            ${sudoCmd} dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb
        fi

        if [[ "${linuxKernelToInstallVersion}" == "5.19" || "${linuxKernelToInstallVersion}" == "5.10.118" || "${linuxKernelToInstallVersion}" == "5.15" ]]; then
            if [ -f "${userHomePath}/libssl3_3.0.2-0ubuntu1_amd64.deb" ]; then
                green "The file already exists, no need to download, the original download address of the file: http://mirrors.kernel.org/ubuntu/pool/main/o/openssl/libssl3_3.0.2-0ubuntu1_amd64.deb "
            else
                green "File downloading... Download address: http://mirrors.kernel.org/ubuntu/pool/main/o/openssl/libssl3_3.0.2-0ubuntu1_amd64.deb "
                wget -P ${userHomePath} http://mirrors.kernel.org/ubuntu/pool/main/o/openssl/libssl3_3.0.2-0ubuntu1_amd64.deb
            fi

            if [ -f "${userHomePath}/libc6_2.35-0ubuntu3_amd64.deb" ]; then
                green "The file already exists, no need to download, the original download address of the file: http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc6_2.35-0ubuntu3_amd64.deb "
            else
                green "File downloading... Download address: http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc6_2.35-0ubuntu3_amd64.deb "
                wget -P ${userHomePath} http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc6_2.35-0ubuntu3_amd64.deb
            fi

            if [ -f "${userHomePath}/locales_2.35-0ubuntu3_all.deb" ]; then
                green "The file already exists, no need to download, the original download address of the file: http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/locales_2.35-0ubuntu3_all.deb "
            else
                green "File downloading... Download address: http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/locales_2.35-0ubuntu3_all.deb"
                wget -P ${userHomePath} http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/locales_2.35-0ubuntu3_all.deb
            fi

            if [ -f "${userHomePath}/libc-bin_2.35-0ubuntu3_amd64.deb" ]; then
                green "The file already exists, no need to download, the original download address of the file: http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc-bin_2.35-0ubuntu3_amd64.deb "
            else
                green "File downloading... Download address: http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc-bin_2.35-0ubuntu3_amd64.deb "
                wget -P ${userHomePath} http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc-bin_2.35-0ubuntu3_amd64.deb
            fi

            ${sudoCmd} dpkg -i locales_2.35-0ubuntu3_all.deb
            ${sudoCmd} dpkg -i libc-bin_2.35-0ubuntu3_amd64.deb
            ${sudoCmd} dpkg -i libssl3_3.0.2-0ubuntu1_amd64.deb
            ${sudoCmd} dpkg -i libc6_2.35-0ubuntu3_amd64.deb

        fi



        if [ "${linuxKernelByUser}" = "" ]; then

            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.11.12/amd64/
            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.11.12/amd64/linux-image-unsigned-5.11.12-051112-generic_5.11.12-051112.202104071432_amd64.deb
            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.11.12/amd64/linux-modules-5.11.12-051112-generic_5.11.12-051112.202104071432_amd64.deb

            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19.17/
            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19.17/amd64/linux-image-unsigned-5.19.17-051917-generic_5.19.17-051917.202210240939_amd64.deb
            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19.17/amd64/linux-headers-5.19.17-051917-generic_5.19.17-051917.202210240939_amd64.deb
            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19.17/amd64/linux-modules-5.19.17-051917-generic_5.19.17-051917.202210240939_amd64.deb

            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19.17/arm64/linux-image-unsigned-5.19.17-051917-generic_5.19.17-051917.202210240939_arm64.deb
            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19.17/arm64/linux-headers-5.19.17-051917-generic_5.19.17-051917.202210240939_arm64.deb
            # https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.19.17/arm64/linux-modules-5.19.17-051917-generic_5.19.17-051917.202210240939_arm64.deb


            getLatestUbuntuKernelVersion

            linuxKernelToInstallVersionFull=${ubuntuKernelVersion}

            mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
            cd ${userHomePath}/${linuxKernelToInstallVersionFull}


            for file in "${ubuntuKernelDownloadUrlArray[@]}"; do
                downloadFile ${ubuntuDownloadUrl}/${file}
            done

        elif [ "${linuxKernelByUser}" = "cx9208" ]; then

            linuxKernelToInstallVersionFull="4.14.129-bbrplus"

            mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
            cd ${userHomePath}/${linuxKernelToInstallVersionFull}

            # https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/bbrplus/debian-ubuntu/x64/linux-headers-4.14.129-bbrplus.deb
            # https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/bbrplus/debian-ubuntu/x64/linux-image-4.14.129-bbrplus.deb

            # https://github.com/cx9208/Linux-NetSpeed/raw/master/bbrplus/debian-ubuntu/x64/linux-headers-4.14.129-bbrplus.deb
            # https://github.com/cx9208/Linux-NetSpeed/raw/master/bbrplus/debian-ubuntu/x64/linux-image-4.14.129-bbrplus.deb

            # https://raw.githubusercontent.com/cx9208/Linux-NetSpeed/master/bbrplus/debian-ubuntu/x64/linux-headers-4.14.129-bbrplus.deb
            # https://raw.githubusercontent.com/cx9208/Linux-NetSpeed/master/bbrplus/debian-ubuntu/x64/linux-image-4.14.129-bbrplus.deb

            bbrplusDownloadUrl="https://raw.githubusercontent.com/cx9208/Linux-NetSpeed/master/bbrplus/debian-ubuntu/x64"

            downloadFile ${bbrplusDownloadUrl}/linux-image-${linuxKernelToInstallVersionFull}.deb
            downloadFile ${bbrplusDownloadUrl}/linux-headers-${linuxKernelToInstallVersionFull}.deb

        elif [ "${linuxKernelByUser}" = "UJX6N" ]; then

            linuxKernelToInstallVersionFull="${bbrplusKernelVersion}-bbrplus"

            mkdir -p ${userHomePath}/${linuxKernelToInstallVersionFull}
            cd ${userHomePath}/${linuxKernelToInstallVersionFull}

            if [ "${linuxKernelToInstallVersion}" = "6.7" ]; then
                bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/${linuxKernelToInstallVersionFull}"

            elif [ "${linuxKernelToInstallVersion}" = "4.14" ]; then
                bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus/releases/download/${linuxKernelToInstallVersionFull}"

            else
                bbrplusDownloadUrl="https://github.com/UJX6N/bbrplus-${linuxKernelToInstallVersion}/releases/download/${linuxKernelToInstallVersionFull}"
            fi


            # https://github.com/UJX6N/bbrplus-5.9/releases/download/5.9.16-bbrplus/Debian-Ubuntu_Required_linux-image-5.9.16-bbrplus_5.9.16-bbrplus-1_amd64.deb
            # https://github.com/UJX6N/bbrplus-5.4/releases/download/5.4.228-bbrplus/Debian-Ubuntu_Required_linux-headers-5.4.228-bbrplus_5.4.228-bbrplus-1_amd64.deb
            # https://github.com/UJX6N/bbrplus-5.4/releases/download/5.4.228-bbrplus/Debian-Ubuntu_Required_linux-image-5.4.228-bbrplus_5.4.228-bbrplus-1_amd64.deb

            # https://github.com/UJX6N/bbrplus-4.19/releases/download/4.19.269-bbrplus/Debian-Ubuntu_Required_linux-image-4.19.269-bbrplus_4.19.269-bbrplus-1_amd64.deb
            # https://github.com/UJX6N/bbrplus/releases/download/4.14.302-bbrplus/Debian-Ubuntu_Required_linux-headers-4.14.302-bbrplus_4.14.302-bbrplus-1_amd64.deb
            # https://github.com/UJX6N/bbrplus-4.9/releases/download/4.9.337-bbrplus/Debian-Ubuntu_Required_linux-image-4.9.337-bbrplus_4.9.337-bbrplus-1_amd64.deb


            if [[ "${linuxKernelToInstallVersion}" == "5.10" || "${linuxKernelToInstallVersion}" == "5.15" || "${linuxKernelToInstallVersion}" == "6.1" || "${linuxKernelToInstallVersion}" == "6.6" || "${linuxKernelToInstallVersion}" == "6.7" ]]; then
            # https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/6.4.3-bbrplus/Debian-Ubuntu_Required_linux-image-6.4.3-bbrplus_6.4.3-1_amd64.deb
            # https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/6.4.3-bbrplus/Debian-Ubuntu_Optional_linux-headers-6.4.3-bbrplus_6.4.3-1_amd64.deb

            # https://github.com/UJX6N/bbrplus-6.1/releases/download/6.1.38-bbrplus/Debian-Ubuntu_Required_linux-image-6.1.38-bbrplus_6.1.38-bbrplus-1_amd64.deb

            # https://github.com/UJX6N/bbrplus-5.15/releases/download/5.15.120-bbrplus/Debian-Ubuntu_Required_linux-image-5.15.120-bbrplus_5.15.120-bbrplus-1_amd64.deb

            # https://github.com/UJX6N/bbrplus-5.10/releases/download/5.10.162-bbrplus/Debian-Ubuntu_Required_linux-image-5.10.162-bbrplus_5.10.162-bbrplus-1_amd64.deb
            # https://github.com/UJX6N/bbrplus-5.15/releases/download/5.15.86-bbrplus/Debian-Ubuntu_Optional_linux-headers-5.15.86-bbrplus_5.15.86-bbrplus-1_amd64.deb

                downloadFile ${bbrplusDownloadUrl}/Debian-Ubuntu_Required_linux-image-${bbrplusKernelVersion}-bbrplus_${bbrplusKernelVersion}-bbrplus-1_amd64.deb
                downloadFile ${bbrplusDownloadUrl}/Debian-Ubuntu_Optional_linux-headers-${bbrplusKernelVersion}-bbrplus_${bbrplusKernelVersion}-bbrplus-1_amd64.deb
            else
                downloadFile ${bbrplusDownloadUrl}/Debian-Ubuntu_Required_linux-image-${bbrplusKernelVersion}-bbrplus_${bbrplusKernelVersion}-1_amd64.deb
                downloadFile ${bbrplusDownloadUrl}/Debian-Ubuntu_Optional_linux-headers-${bbrplusKernelVersion}-bbrplus_${bbrplusKernelVersion}-1_amd64.deb
            fi

        fi


        removeDebianKernelMulti
        echo
        green " =================================================="
        green "Start installing linux kernel version: ${linuxKernelToInstallVersionFull}"
        echo
        ${sudoCmd} dpkg -i ./*.deb

        updateGrubConfig

    fi

    echo
    green " =================================================="
    green "Installation of linux kernel ${linuxKernelToInstallVersionFull} succeeded!"
    red "Please check whether the new kernel is installed successfully according to the following information. Do not restart without a new kernel! "
    green " =================================================="
    echo

    showLinuxKernelInfo
    removeDebianKernelMulti "linux-image"
    listInstalledLinuxKernel
    rebootSystem

}




function removeDebianKernelMulti(){
    listInstalledLinuxKernel

    echo
    if [ -z $1 ]; then
        red "===== Start to delete linux-headers linux-modules kernel, it is recommended to delete"
    else
        red "===== Start to delete the linux-image kernel, it is recommended to delete"
    fi

    red " Note: Deleting the kernel is risky and may cause the VPS to fail to boot, please make a backup first! "
    read -p "Do you want to delete the kernel? Press Enter to delete the kernel by default. Please enter [Y/n]:" isContinueDelKernelInput
	isContinueDelKernelInput=${isContinueDelKernelInput:-Y}
    echo

	if [[ $isContinueDelKernelInput == [Yy] ]]; then

        if [ -z $1 ]; then
            removeDebianKernel "linux-modules-extra"
            removeDebianKernel "linux-modules"
            removeDebianKernel "linux-headers"
            removeDebianKernel "linux-image"
            # removeDebianKernel "linux-kbuild"
            # removeDebianKernel "linux-compiler"
            # removeDebianKernel "linux-libc"
        else
            removeDebianKernel "linux-image"
            removeDebianKernel "linux-modules-extra"
            removeDebianKernel "linux-modules"
            removeDebianKernel "linux-headers"
            # ${sudoCmd} apt -y --purge autoremove
        fi

    fi
    echo
}

function removeDebianKernel(){

    removeKernelNameText="linux-image"
    removeKernelNameText=$1
    grepExcludelinuxKernelVersion=$(echo ${linuxKernelToInstallVersionFull} | cut -d- -f1)


    # echo "dpkg --get-selections | grep ${removeKernelNameText} | grep -Ev '${grepExcludelinuxKernelVersion}|${removeKernelNameText}-amd64' | awk '{print \$1}' "
    rpmOldKernelNumber=$(dpkg --get-selections | grep "${removeKernelNameText}" | grep -Ev "${grepExcludelinuxKernelVersion}|${removeKernelNameText}-amd64" | wc -l)
    rpmOLdKernelNameList=$(dpkg --get-selections | grep "${removeKernelNameText}" | grep -Ev "${grepExcludelinuxKernelVersion}|${removeKernelNameText}-amd64" | awk '{print $1}' )
    # echo "$rpmOLdKernelNameList"

    # https://stackoverflow.com/questions/16212656/grep-exclude-multiple-strings
    # https://stackoverflow.com/questions/29269259/extract-value-of-column-from-a-line-variable

    # https://askubuntu.com/questions/187888/what-is-the-correct-way-to-completely-remove-an-application

    if [ "${rpmOldKernelNumber}" -gt "0" ]; then
        yellow "=========== Prepare to start deleting the old kernel ${removeKernelNameText} ${osKernelVersionBackup}, the new kernel version to be installed is: ${grepExcludelinuxKernelVersion}"
        red "The current system's old kernels ${removeKernelNameText} ${osKernelVersionBackup} have ${rpmOldKernelNumber} that need to be deleted"
        echo
        for((integer = 1; integer <= ${rpmOldKernelNumber}; integer++)); do
            rpmOLdKernelName=$(awk "NR==${integer}" <<< "${rpmOLdKernelNameList}")
            green "+++++ Starting to uninstall kernel number ${integer}: ${rpmOLdKernelName}. Command: apt remove --purge ${rpmOLdKernelName}"
            ${sudoCmd} apt remove -y --purge ${rpmOLdKernelName}
            ${sudoCmd} apt autoremove -y ${rpmOLdKernelName}
            green "++++++ Uninstalled kernel ${integer} ${rpmOLdKernelName} +++++"
            echo
        done
        yellow "=========== A total of ${rpmOldKernelNumber} old kernels ${removeKernelNameText} ${osKernelVersionBackup} have been uninstalled"
        echo
    else
        red "The number of old system kernels ${removeKernelNameText} ${osKernelVersionBackup} that need to be uninstalled is 0!"
    fi

    echo
}






























function installWARP(){
    # wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/jinwyp/SimpleNetflix/dev/nf.sh && chmod +x ./nf.sh
	# wget -qN --no-check-certificate -O ./warp-go.sh https://raw.githubusercontent.com/fscarmen/warp/main/warp-go.sh && chmod +x ./warp-go.sh && ./warp-go.sh
    # wget -qN --no-check-certificate -O ./warp-go.sh https://gitlab.com/fscarmen/warp/-/raw/main/warp-go.sh && chmod +x ./warp-go.sh && ./warp-go.sh
    wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh
}

function installWARPGO(){
    # wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/jinwyp/SimpleNetflix/dev/nf.sh && chmod +x ./nf.sh
	# wget -qN --no-check-certificate -O ./warp-go.sh https://raw.githubusercontent.com/fscarmen/warp/main/warp-go.sh && chmod +x ./warp-go.sh && ./warp-go.sh
    wget -qN --no-check-certificate -O ./warp-go.sh https://gitlab.com/fscarmen/warp/-/raw/main/warp-go.sh && chmod +x ./warp-go.sh && ./warp-go.sh
}

function vps_netflix_auto(){
    # wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/jinwyp/SimpleNetflix/dev/nf.sh && chmod +x ./nf.sh
	# bash <(curl -sSL https://raw.githubusercontent.com/fscarmen/warp_unlock/main/unlock.sh)
    bash <(curl -sSL https://gitlab.com/fscarmen/warp_unlock/-/raw/main/unlock.sh)
}

function vps_netflix_jin(){
    # wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/jinwyp/SimpleNetflix/dev/nf.sh && chmod +x ./nf.sh
	wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/jinwyp/one_click_script/master/netflix_check.sh && chmod +x ./nf.sh && ./nf.sh
}

function vps_netflix_jin_auto(){
    # wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/jinwyp/SimpleNetflix/dev/nf.sh && chmod +x ./nf.sh
    cd ${HOME}
	wget -qN --no-check-certificate -O ./nf.sh https://raw.githubusercontent.com/jinwyp/one_click_script/master/netflix_check.sh && chmod +x ./nf.sh

    echo
    green " =================================================="
    green "Automatically check whether Netflix has unlocked non-self-made dramas every day through Cron scheduled tasks"
    green "If Netflix is â€‹â€‹not unlocked, it will automatically refresh the WARP IP. The default refresh attempt is 20 times."
    green "Refresh log in /root/warp_refresh.log"
    green " Auto refresh Cloudflare WARP IP to unlock Netflix non-self produced drama"
    green " =================================================="
    echo
    (crontab -l ; echo "10 5 * * 0,1,2,3,4,5,6 /root/nf.sh auto >> /root/warp_refresh.log ") | sort - | uniq - | crontab -
    echo

    ./nf.sh auto
}







































function getGithubLatestReleaseVersion(){
    # https://github.com/p4gefau1t/trojan-go/issues/63
    wget --no-check-certificate -qO- https://api.github.com/repos/$1/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -b 2-
}









# https://unix.stackexchange.com/questions/8656/usr-bin-vs-usr-local-bin-on-linux

versionWgcf="2.2.24"
downloadFilenameWgcf="wgcf_${versionWgcf}_linux_amd64"
configWgcfBinPath="/usr/local/bin"
configWgcfConfigFolderPath="${HOME}/wireguard"
configWgcfAccountFilePath="${configWgcfConfigFolderPath}/wgcf-account.toml"
configWgcfProfileFilePath="${configWgcfConfigFolderPath}/wgcf-profile.conf"
configWARPPortFilePath="${configWgcfConfigFolderPath}/warp-port"
configWireGuardConfigFileFolder="/etc/wireguard"
configWireGuardConfigFilePath="/etc/wireguard/wgcf.conf"
configWireGuardDNSBackupFilePath="/etc/resolv_warp_bak.conf"


configWarpPort="40000"



function installWARPClient(){

    # https://developers.cloudflare.com/warp-client/setting-up/linux

    echo
    green " =================================================="
    green " Prepare to install Cloudflare WARP Official client "
    green "Cloudflare WARP Official client only supports Debian 10/11, Ubuntu 20.04/16.04, CentOS 8"
    green " =================================================="
    echo

    if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
        ${sudoCmd} apt-key del 835b8acb
        ${sudoCmd} apt-key del 8e5f9a5d

        ${sudoCmd} apt install -y gnupg
        ${sudoCmd} apt install -y apt-transport-https

        # Add cloudflare gpg key
        sudo mkdir -p --mode=0755 /usr/share/keyrings
        curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

        # Add this repo to your apt repositories
        echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $osReleaseVersionCodeName main" | ${sudoCmd} tee /etc/apt/sources.list.d/cloudflared.list

        # install cloudflared

        ${sudoCmd} apt-get update
        ${sudoCmd} apt install -y cloudflare-warp
        ${sudoCmd} apt-get install cloudflared

    elif [[ "${osRelease}" == "centos" ]]; then
        ${sudoCmd} rpm -e gpg-pubkey-835b8acb-*
        ${sudoCmd} rpm -e gpg-pubkey-8e5f9a5d-*

        if [ "${osReleaseVersionNoShort}" -eq 7 ]; then
            # red "Cloudflare WARP Official client is not supported on Centos 7"

            # This requires yum config-manager
            ${sudoCmd} yum install yum-utils

            # Add cloudflared.repo to config-manager
            ${sudoCmd} yum-config-manager --add-repo https://pkg.cloudflare.com/cloudflared-ascii.repo

            # install cloudflared
            ${sudoCmd} yum install cloudflared
        else
            # This requires dnf config-manager
            # Add cloudflared.repo to config-manager
            ${sudoCmd} dnf config-manager --add-repo https://pkg.cloudflare.com/cloudflared-ascii.repo

            # install cloudflared
            ${sudoCmd} dnf install cloudflared
        fi

        ${sudoCmd} yum install -y cloudflare-warp
    fi

    if [[ ! -f "/bin/warp-cli" ]]; then
        green " =================================================="
        red " ${osInfo}${osReleaseVersionNoShort} ${osReleaseVersionCodeName} is not supported ! "
        green " =================================================="
        exit
    fi

    echo
    echo
    read -p "Do you want to generate a random WARP SOCKS5 port number? The default is a random port. Enter N to set a fixed port number of 40000. Please enter [Y/n]:" isWarpPortInput
    isWarpPortInput=${isWarpPortInput:-y}

    if [[ $isWarpPortInput == [Nn] ]]; then
        echo
    else
        configWarpPort="$(($RANDOM + 10000))"
    fi

    mkdir -p ${configWgcfConfigFolderPath}
    echo "${configWarpPort}" > "${configWARPPortFilePath}"

    ${sudoCmd} systemctl enable warp-svc

    yes | warp-cli register
    echo
    echo "warp-cli set-mode proxy"
    warp-cli set-mode proxy
    echo
    echo "warp-cli --accept-tos set-proxy-port ${configWarpPort}"
    warp-cli --accept-tos set-proxy-port ${configWarpPort}
    echo
    echo "warp-cli --accept-tos connect"
    warp-cli --accept-tos connect
    echo
    echo "warp-cli --accept-tos enable-always-on"
    warp-cli --accept-tos enable-always-on

    echo
    checkWarpClientStatus


    # (crontab -l ; echo "10 6 * * 0,1,2,3,4,5,6 warp-cli disable-always-on ") | sort - | uniq - | crontab -
    # (crontab -l ; echo "11 6 * * 0,1,2,3,4,5,6 warp-cli disconnect ") | sort - | uniq - | crontab -
    (crontab -l ; echo "12 6 * * 1,4 systemctl restart warp-svc ") | sort - | uniq - | crontab -
    # (crontab -l ; echo "16 6 * * 0,1,2,3,4,5,6 warp-cli connect ") | sort - | uniq - | crontab -
    # (crontab -l ; echo "17 6 * * 0,1,2,3,4,5,6 warp-cli enable-always-on ") | sort - | uniq - | crontab -



    echo
    green " ================================================== "
    green "Cloudflare official WARP Client installed successfully!"
    green "WARP SOCKS5 port number ${configWarpPort}"
    echo
    green "WARP stop command: warp-cli disconnect, stop Always-On command: warp-cli disable-always-on"
    green "WARP startup command: warp-cli connect , Enable Always-On command (keep WARP connected): warp-cli enable-always-on "
    green "WARP View log: journalctl -n 100 -u warp-svc"
    green "WARP View running status: warp-cli status"
    green "WARP View connection information: warp-cli warp-stats"
    green "WARP View settings information: warp-cli settings"
    green "WARP View account information: warp-cli account"
    echo
    green "Use this script to install v2ray or xray to choose whether to unlock Netflix restrictions and avoid pop-up Google reCAPTCHA human-machine verification!"
    echo
    green "Please replace the v2ray or xray configuration files installed by other scripts!"
    green " ================================================== "

}

function installWireguard(){



    if [[ -f "${configWireGuardConfigFilePath}" ]]; then
        green " =================================================="
        green "Wireguard has been installed. If you need to reinstall, you can choose to uninstall Wireguard and then reinstall it! "
        green " =================================================="
        exit
    fi


    green " =================================================="
    green "Ready to install WireGuard"
    echo
    red " Before installation, it is recommended to use this script to upgrade the Linux kernel to 5.6 or above, such as the 5.10 LTS kernel. You can also choose not to upgrade the kernel, see the following instructions for details"
    red "If it is a new, clean system that has not changed the kernel (for example, the BBR Plus kernel has not been installed), you can continue to install WireGuard without exiting to install other kernels."
    red "If you have installed other kernels (such as the BBR Plus kernel), it is recommended to install a kernel higher than 5.6 first. You can continue to install a kernel lower than 5.6, but there is a chance that WireGuard will not start."
    red "If WireGuard fails to start, it is recommended to reinstall the new system, upgrade the system to the 5.10 kernel, and then install WireGuard. Alternatively, do not replace other kernels after reinstalling the new system, and install WireGuard directly"
    green " =================================================="
    echo

    isKernelSupportWireGuardVersion="5.6"
    isKernelBuildInWireGuardModule="no"

    if versionCompareWithOp "${isKernelSupportWireGuardVersion}" "${osKernelVersionShort}" ">"; then
        red "The current system kernel is ${osKernelVersionShort}. System kernels lower than 5.6 do not have built-in WireGuard Module!"
        isKernelBuildInWireGuardModule="no"
    else
        green "The current system kernel is ${osKernelVersionShort}, and the system kernel has built-in WireGuard Module"
        isKernelBuildInWireGuardModule="yes"
    fi


	read -p "Do you want to continue? Please confirm that the Linux kernel has been installed correctly. Press Enter to continue by default. Please enter [Y/n]:" isContinueInput
	isContinueInput=${isContinueInput:-Y}

	if [[ ${isContinueInput} == [Yy] ]]; then
		echo
        green " =================================================="
        green "Start installing WireGuard"
        green " =================================================="
	else
        green "It is recommended to use this script to install the Linux kernel 5.6 or above first!"
		exit
	fi

    echo
    echo

    if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then
        ${sudoCmd} apt --fix-broken install -y
        ${sudoCmd} apt-get update
        ${sudoCmd} apt install -y openresolv
        # ${sudoCmd} apt install -y resolvconf
        ${sudoCmd} apt install -y net-tools iproute2 dnsutils
        echo
        if [[ ${isKernelBuildInWireGuardModule} == "yes" ]]; then
            green "The current system kernel version is higher than 5.6, directly install wireguard-tools"
            echo
            ${sudoCmd} apt install -y wireguard-tools
        else
            # After installing wireguard-dkms, Ubuntu 20 system will also install 5.4.0-71 kernel
            green "The current system kernel version is lower than 5.6, directly install wireguard wireguard"
            echo
            ${sudoCmd} apt install -y wireguard
            # ${sudoCmd} apt install -y wireguard-tools
        fi

        # if [[ ! -L "/usr/local/bin/resolvconf" ]]; then
        # ln -s /usr/bin/resolvectl /usr/local/bin/resolvconf
        #fi

        ${sudoCmd} systemctl enable systemd-resolved.service
        ${sudoCmd} systemctl start systemd-resolved.service

    elif [[ "${osRelease}" == "centos" ]]; then
        ${sudoCmd} yum install -y epel-release elrepo-release
        ${sudoCmd} yum install -y net-tools
        ${sudoCmd} yum install -y iproute

        echo
        if [[ ${isKernelBuildInWireGuardModule} == "yes" ]]; then

            green "The current system kernel version is higher than 5.6, directly install wireguard-tools"
            echo
            if [ "${osReleaseVersionNoShort}" -eq 7 ]; then
                ${sudoCmd} yum install -y yum-plugin-elrepo
            fi

            ${sudoCmd} yum install -y wireguard-tools
        else

            if [ "${osReleaseVersionNoShort}" -eq 7 ]; then
                if [[ ${osKernelVersionBackup} == *"3.10."* ]]; then
                    green "The current system kernel version is the original Centos 7 ${osKernelVersionBackup}, directly install kmod-wireguard"
                    ${sudoCmd} yum install -y yum-plugin-elrepo
                    ${sudoCmd} yum install -y kmod-wireguard wireguard-tools
                else
                    green "The current system kernel version is lower than 5.6, install wireguard-dkms"
                    ${sudoCmd} yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
                    ${sudoCmd} curl -o /etc/yum.repos.d/jdoss-wireguard-epel-7.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
                    ${sudoCmd} yum install -y wireguard-dkms wireguard-tools
                fi
            else
                if [[ ${osKernelVersionBackup} == *"4.18."* ]]; then
                    green "The current system kernel version is the original Centos 8 ${osKernelVersionBackup}, directly install kmod-wireguard"
                    ${sudoCmd} yum install -y kmod-wireguard wireguard-tools
                else
                    green "The current system kernel version is lower than 5.6, install wireguard-dkms"
                    ${sudoCmd} yum config-manager --set-enabled PowerTools
                    ${sudoCmd} yum copr enable jdoss/wireguard
                    ${sudoCmd} yum install -y wireguard-dkms wireguard-tools
                fi

            fi
        fi
    fi

    green " ================================================== "
    green "Wireguard installed successfully!"
    green " ================================================== "

    installWGCF
}

function installWGCF(){

    versionWgcf=$(getGithubLatestReleaseVersion "ViRb3/wgcf")
    downloadFilenameWgcf="wgcf_${versionWgcf}_linux_amd64"
    # https://github.com/ViRb3/wgcf/releases/download/v2.2.24/wgcf_2.2.24_linux_arm64

    if [[ ${osArchitecture} == "arm" || ${osArchitecture} == "arm64" ]] ; then
        downloadFilenameWgcf="wgcf_${versionWgcf}_linux_arm64"
    fi

    echo
    green " =================================================="
    green "Start installing the Cloudflare WARP command line tool Wgcf ${versionWgcf}"
    green " =================================================="
    echo

    mkdir -p ${configWgcfConfigFolderPath}
    mkdir -p ${configWgcfBinPath}
    mkdir -p ${configWireGuardConfigFileFolder}

    cd ${configWgcfConfigFolderPath}

    # https://github.com/ViRb3/wgcf/releases/download/v2.2.10/wgcf_2.2.10_linux_amd64
    wget -O ${configWgcfConfigFolderPath}/wgcf --no-check-certificate "https://github.com/ViRb3/wgcf/releases/download/v${versionWgcf}/${downloadFilenameWgcf}"


    if [[ -f ${configWgcfConfigFolderPath}/wgcf ]]; then
        green "Cloudflare WARP command line tool Wgcf ${versionWgcf} downloaded successfully!"
        echo
    else
        red "Wgcf ${versionWgcf} download failed!"
        exit 255
    fi

    ${sudoCmd} chmod +x ${configWgcfConfigFolderPath}/wgcf
    cp ${configWgcfConfigFolderPath}/wgcf ${configWgcfBinPath}

    # ${configWgcfConfigFolderPath}/wgcf register --config "${configWgcfAccountFilePath}"

    if [[ -f ${configWgcfAccountFilePath} ]]; then
        echo
    else
        yes | ${configWgcfConfigFolderPath}/wgcf register
    fi

    echo
    echo
    green " =================================================="
    yellow "If you have not purchased WARP+ subscription, please press enter to skip this step, Press enter to continue without WARP+"
    echo
    yellow "If you have purchased WARP+ subscription, you can fill in the license key to enable WARP+"
    green " View method: Open the Cloudflare 1.1.1.1 app on your phone, click the hamburger menu button on the top-right corner "
    green "Navigate to: Account > Key, select the key in the Account menu which is the license key"
    echo

    read -p "Please fill in the license key? Press Enter to skip this step by default. Please enter:" isWARPLicenseKeyInput
    isWARPLicenseKeyInput=${isWARPLicenseKeyInput:-n}

    if [[ ${isWARPLicenseKeyInput} == [Nn] ]]; then
        echo
    else
        sed -i "s/license_key =.*/license_key = \"${isWARPLicenseKeyInput}\"/g" ${configWgcfAccountFilePath}
        WGCF_LICENSE_KEY="${isWARPLicenseKeyInput}" wgcf update
    fi

    if [[ -f ${configWgcfProfileFilePath} ]]; then
        echo
    else
        yes | ${configWgcfConfigFolderPath}/wgcf generate
    fi


    cp ${configWgcfProfileFilePath} ${configWireGuardConfigFilePath}

    enableWireguardIPV6OrIPV4

    echo
    green "Start temporarily starting Wireguard to test whether it starts normally, run the command: wg-quick up wgcf"
    ${sudoCmd} wg-quick up wgcf

    echo
    green "Start to verify whether Wireguard is started normally and check whether Cloudflare's ipv6 access is used!"
    echo
    echo "curl -6 ip.p3terx.com"
    curl -6 ip.p3terx.com
    echo
    isWireguardIpv6Working=$(curl -6 ip.p3terx.com | grep CLOUDFLARENET )
    echo

    if [[ -n "$isWireguardIpv6Working" ]]; then
        green "Wireguard started normally, and has successfully accessed the Internet through IPv6 provided by Cloudflare WARP! "
    else
        green " ================================================== "
        red "Wireguard failed to detect IPV6 access using CLOUDFLARENET via curl -6 ip.p3terx.com"
        red "Please check whether the Linux kernel is installed correctly"
        red "The installation will continue, and it is possible that the installation was successful, but IPV6 was not used"
        red " Check whether WireGuard is started successfully. You can run the command to view the running status: systemctl status wg-quick@wgcf"
        red "If WireGuard fails to start, run the log command to find out why: journalctl -n 50 -u wg-quick@wgcf"
        red "If WireGuard fails to start, it is recommended that you install WireGuard directly without replacing other kernels after reinstalling the new system"
        green " ================================================== "
    fi

    echo
    green " Shut down the Wireguard that was temporarily started for testing, run the command: wg-quick down wgcf "
    ${sudoCmd} wg-quick down wgcf
    echo

    ${sudoCmd} systemctl daemon-reload

    # Set the boot
    ${sudoCmd} systemctl enable wg-quick@wgcf

    # Enable the daemon
    ${sudoCmd} systemctl start wg-quick@wgcf

    # (crontab -l ; echo "12 6 * * 1 systemctl restart wg-quick@wgcf ") | sort - | uniq - | crontab -

    checkWireguardBootStatus

    echo
    green " ================================================== "
    green "Wireguard and Cloudflare WARP command line tool Wgcf ${versionWgcf} installed successfully!"
    green "Account configuration file path requested by Cloudflare WARP: ${configWgcfAccountFilePath}"
    green " WireGuard configuration file path generated by Cloudflare WARP: ${configWireGuardConfigFilePath} "
    echo
    green "Wireguard stop command: systemctl stop wg-quick@wgcf start command: systemctl start wg-quick@wgcf restart command: systemctl restart wg-quick@wgcf"
    green "Wireguard view log: journalctl -n 50 -u wg-quick@wgcf"
    green "Wireguard View running status: systemctl status wg-quick@wgcf"
    echo
    green "Use this script to install v2ray or xray to choose whether to unlock Netflix restrictions and avoid pop-up Google reCAPTCHA human-machine verification!"
    echo
    green "Please replace the v2ray or xray configuration files installed by other scripts!"
    green " You can refer to the tutorial on how to use IPv6 to access Netflix https://ybfl.xyz/111.html or https://toutyrater.github.io/app/netflix.html"
    green " ================================================== "

}




function enableWireguardIPV6OrIPV4(){
    # https://p3terx.com/archives/use-cloudflare-warp-to-add-extra-ipv4-or-ipv6-network-support-to-vps-servers-for-free.html


    ${sudoCmd} systemctl stop wg-quick@wgcf

    cp /etc/resolv.conf ${configWireGuardDNSBackupFilePath}

    sed -i '/nameserver 2a00\:1098\:2b\:\:1/d' /etc/resolv.conf

    sed -i '/nameserver 8\.8/d' /etc/resolv.conf
    sed -i '/nameserver 9\.9/d' /etc/resolv.conf
    sed -i '/nameserver 1\.1\.1\.1/d' /etc/resolv.conf

    echo
    green " ================================================== "
    yellow "Please select whether to add IPv6 or IPv4 network support to the server: "
    echo
    green "1 Add IPv6 network (for unlocking Netflix restrictions and avoiding Google reCAPTCHA pop-up verification)"
    green "2 Add IPv4 network (used to add IPv4 network support to VPS hosts that only have IPv6)"
    echo
    read -p "Please select IPv6 or IPv4 network support? Press Enter to select 1 by default. Please enter [1/2]:" isAddNetworkIPv6Input
	isAddNetworkIPv6Input=${isAddNetworkIPv6Input:-1}

	if [[ ${isAddNetworkIPv6Input} == [2] ]]; then

        # Add IPv4 network support for IPv6 Only servers

        sed -i 's/^AllowedIPs = \:\:\/0/# AllowedIPs = \:\:\/0/g' ${configWireGuardConfigFilePath}
        sed -i 's/# AllowedIPs = 0\.0\.0\.0/AllowedIPs = 0\.0\.0\.0/g' ${configWireGuardConfigFilePath}

        sed -i 's/engage\.cloudflareclient\.com/\[2606\:4700\:d0\:\:a29f\:c001\]/g' ${configWireGuardConfigFilePath}
        sed -i 's/162\.159\.192\.1/\[2606\:4700\:d0\:\:a29f\:c001\]/g' ${configWireGuardConfigFilePath}

        sed -i 's/^DNS = 1\.1\.1\.1/DNS = 2620:fe\:\:10,2001\:4860\:4860\:\:8888,2606\:4700\:4700\:\:1111/g' ${configWireGuardConfigFilePath}
        sed -i 's/^DNS = 8\.8\.8\.8,8\.8\.4\.4,1\.1\.1\.1,9\.9\.9\.10/DNS = 2620:fe\:\:10,2001\:4860\:4860\:\:8888,2606\:4700\:4700\:\:1111/g' ${configWireGuardConfigFilePath}

        echo "nameserver 2a00:1098:2b::1" >> /etc/resolv.conf

        echo
        green "Wireguard has successfully switched to IPv4 network support for VPS servers"

    else

        # Add IPv6 network support for IPv4 Only servers
        sed -i 's/^AllowedIPs = 0\.0\.0\.0/# AllowedIPs = 0\.0\.0\.0/g' ${configWireGuardConfigFilePath}
        sed -i 's/# AllowedIPs = \:\:\/0/AllowedIPs = \:\:\/0/g' ${configWireGuardConfigFilePath}

        sed -i 's/engage\.cloudflareclient\.com/162\.159\.192\.1/g' ${configWireGuardConfigFilePath}
        sed -i 's/\[2606\:4700\:d0\:\:a29f\:c001\]/162\.159\.192\.1/g' ${configWireGuardConfigFilePath}

        sed -i 's/^DNS = 1\.1\.1\.1/DNS = 8\.8\.8\.8,8\.8\.4\.4,1\.1\.1\.1,9\.9\.9\.10/g' ${configWireGuardConfigFilePath}
        sed -i 's/^DNS = 2620:fe\:\:10,2001\:4860\:4860\:\:8888,2606\:4700\:4700\:\:1111/DNS = 8\.8\.8\.8,1\.1\.1\.1,9\.9\.9\.10/g' ${configWireGuardConfigFilePath}

        echo "nameserver 8.8.8.8" >> /etc/resolv.conf
        echo "nameserver 8.8.4.4" >> /etc/resolv.conf
        echo "nameserver 1.1.1.1" >> /etc/resolv.conf
        #echo "nameserver 9.9.9.9" >> /etc/resolv.conf
        echo "nameserver 9.9.9.10" >> /etc/resolv.conf

        echo
        green "Wireguard has successfully switched to IPv6 network support for VPS servers"
    fi

    green " ================================================== "
    echo
    green "Wireguard configuration information is as follows: ${configWireGuardConfigFilePath}"
    cat ${configWireGuardConfigFilePath}
    green " ================================================== "
    echo

    # -n is not empty
    if [[ -n $1 ]]; then
        ${sudoCmd} systemctl start wg-quick@wgcf
    else
        preferIPV4
    fi
}




function preferIPV4(){

    if [[ -f "/etc/gai.conf" ]]; then
        sed -i '/^precedence \:\:ffff\:0\:0/d' /etc/gai.conf
        sed -i '/^label 2002\:\:\/16/d' /etc/gai.conf
    fi

    # -z is empty
    if [[ -z $1 ]]; then

        echo "precedence ::ffff:0:0/96 100" >> /etc/gai.conf

        echo
        green "The VPS server has been successfully set up to prioritize IPv4 access to the network"

    else

        green " ================================================== "
        yellow "Please set IPv4 or IPv6 priority access for the server: "
        echo
        green "1 Prioritize IPv4 access to the network (used to add IPv4 network support to VPS hosts that only have IPv6)"
        green "2 Prioritize IPv6 access to the network (for unblocking Netflix restrictions and avoiding Google reCAPTCHA pop-ups)"
        green "3 Delete the settings for IPv4 or IPv6 priority access and restore to the system default configuration"
        echo
        red " Note: After selecting 2, using IPv6 first to access the network may result in inability to access certain websites that do not support IPv6! "
        red " Note: To unlock Netflix restrictions and avoid pop-up Google human-machine verification, you generally do not need to select 2 to set IPv6 priority access. You can set IPv6 access to Netfile and Google separately in the V2ray configuration."
        red "Note: Since Trojan or Trojan-go does not support the configuration of using IPv6 to access Netfile and Google first, you can choose 2 to enable server priority IPv6 access to solve the problem of Trojan-go unlocking Netfile and Google human-machine verification"
        echo
        read -p "Please select IPv4 or IPv6 priority? Press Enter by default 1 is selected, please enter [1/2/3]:" isPreferIPv4Input
        isPreferIPv4Input=${isPreferIPv4Input:-1}

        if [[ ${isPreferIPv4Input} == [2] ]]; then

            # Set IPv6 priority
            echo "label 2002::/16 2" >> /etc/gai.conf

            echo
            green "The VPS server has been successfully set up to prioritize IPv6 access to the network"
        elif [[ ${isPreferIPv4Input} == [3] ]]; then

            echo
            green "The VPS server has deleted the IPv4 or IPv6 priority access settings and restored to the system default configuration"
        else
            # Set IPv4 priority
            echo "precedence ::ffff:0:0/96 100" >> /etc/gai.conf

            echo
            green "The VPS server has been successfully set up to prioritize IPv4 access to the network"
        fi

        green " ================================================== "
        echo
        yellow "Verify IPv4 or IPv6 access network priority test, command: curl ip.p3terx.com "
        echo
        curl ip.p3terx.com
        echo
        green "The above information shows that if it is an IPv4 address, the VPS server has been set to IPv4 priority access. If it is an IPv6 address, it has been set to IPv6 priority access"
        green " ================================================== "

    fi
    echo

}

function removeWireguard(){
    green " ================================================== "
    red "Prepare to uninstall Wireguard and Cloudflare WARP command line tool Wgcf"
    green " ================================================== "

    if [[ -f "${configWgcfBinPath}/wgcf" || -f "${configWgcfConfigFolderPath}/wgcf" || -f "/wgcf" ]]; then
        ${sudoCmd} systemctl stop wg-quick@wgcf.service
        ${sudoCmd} systemctl disable wg-quick@wgcf.service

        ${sudoCmd} wg-quick down wgcf
        ${sudoCmd} wg-quick disable wgcf


        if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then

            $osSystemPackage -y remove wireguard-tools
            $osSystemPackage -y remove wireguard

        elif [[ "${osRelease}" == "centos" ]]; then
            $osSystemPackage -y remove kmod-wireguard
            $osSystemPackage -y remove wireguard-dkms
            $osSystemPackage -y remove wireguard-tools
        fi

        echo
        read -p "Whether to delete the account file applied by Wgcf, it is not deleted by default, so that you don't have to re-register in the future, please enter [y/N]:" isWgcfAccountFileRemoveInput
        isWgcfAccountFileRemoveInput=${isWgcfAccountFileRemoveInput:-n}

        echo
        if [[ $isWgcfAccountFileRemoveInput == [Yy] ]]; then
            rm -rf "${configWgcfConfigFolderPath}"
            green "The account information file ${configWgcfAccountFilePath} requested by Wgcf has been deleted!"

        else
            rm -f "${configWgcfProfileFilePath}"
            green "The account information file ${configWgcfAccountFilePath} requested by Wgcf has been reserved! "
        fi


        rm -f ${configWgcfBinPath}/wgcf
        rm -rf ${configWireGuardConfigFileFolder}
        rm -f ${osSystemMdPath} wg-quick@wgcf.service

        rm -f /usr/bin/wg
        rm -f /usr/bin/wg-quick
        rm -f /usr/share/man/man8/wg.8
        rm -f /usr/share/man/man8/wg-quick.8

        [ -d "/etc/wireguard" ] && ("rm -rf /etc/wireguard")


        sleep 2
        modprobe -r wireguard

        cp -f ${configWireGuardDNSBackupFilePath} /etc/resolv.conf

        green " ================================================== "
        green "Wireguard and Cloudflare WARP command line tool Wgcf uninstalled!"
        green " ================================================== "

    else
        red "Wireguard and Wgcf are not installed on the system, exit and uninstall"
        echo
    fi



}

function removeWARP(){
    green " ================================================== "
    red "Prepare to uninstall Cloudflare WARP official linux client"
    green " ================================================== "

    if [[ -f "/usr/bin/warp-cli" ]]; then
        ${sudoCmd} warp-cli disable-always-on
        ${sudoCmd} warp-cli disconnect
        ${sudoCmd} systemctl stop warp-svc
        sleep 5s

        if [[ "${osRelease}" == "debian" || "${osRelease}" == "ubuntu" ]]; then

            ${sudoCmd} apt purge -y cloudflare-warp
            rm -f /etc/apt/sources.list.d/cloudflare-client.list

        elif [[ "${osRelease}" == "centos" ]]; then
            yum remove -y cloudflare-warp
        fi

        rm -f ${configWARPPortFilePath}

        crontab -l | grep -v 'warp-cli' | crontab -
        crontab -l | grep -v 'warp-svc' | crontab -

        green " ================================================== "
        green "Cloudflare WARP linux client uninstalled!"
        green " ================================================== "
    else
        red "The system does not have Cloudflare WARP linux client installed, exit and uninstall"
        echo
    fi

}

function checkWireguardBootStatus(){
    echo
    green " ================================================== "
    isWireguardBootSuccess=$(systemctl status wg-quick@wgcf | grep -E "Active: active")
    if [[ -z "${isWireguardBootSuccess}" ]]; then
        green " Status display -- Wireguard started ${Red_font_prefix} failed ${Green_font_prefix}! Please check the Wireguard running log, find the error and restart Wireguard "
    else
        green " Status display -- Wireguard has started successfully! "
        echo
        echo "wgcf trace"
        echo
        wgcf trace
        echo
    fi
    green " ================================================== "
    echo
}

cloudflare_Trace_URL='https://www.cloudflare.com/cdn-cgi/trace'
function checkWarpClientStatus(){

    if [[ -f "${configWARPPortFilePath}" ]]; then
        configWarpPort=$(cat ${configWARPPortFilePath})
    fi

    echo
    green " ================================================== "
    sleep 2s
    isWarpClientBootSuccess=$(systemctl is-active warp-svc | grep -E "inactive")
    if [[ -z "${isWarpClientBootSuccess}" ]]; then
        green " Status display -- WARP has started successfully! "
        echo

        isWarpClientMode=$(curl -sx "socks5h://127.0.0.1:${configWarpPort}" ${cloudflare_Trace_URL} --connect-timeout 20 | grep warp | cut -d= -f2)
        sleep 3s
        case ${isWarpClientMode} in
        on)
            green "Status display--WARP SOCKS5 proxy has been started successfully, port number ${configWarpPort}! "
            ;;
        plus)
            green " Status display -- WARP+ SOCKS5 proxy has been started successfully, port number ${configWarpPort}! "
            ;;
        *)
            green " Status display -- WARP SOCKS5 proxy startup ${Red_font_prefix} failed ${Green_font_prefix}! "
            ;;
        esac

        green " ================================================== "
        echo
        echo "curl -x 'socks5h://127.0.0.1:${configWarpPort}' ${cloudflare_Trace_URL}"
        echo
        curl -x "socks5h://127.0.0.1:${configWarpPort}" ${cloudflare_Trace_URL}
    else
        green " Status display -- WARP has started ${Red_font_prefix} failed ${Green_font_prefix}! Please check the WARP operation log, find the error and restart WARP"
    fi
    green " ================================================== "
    echo
}


function restartWireguard(){
    echo
    echo "systemctl restart wg-quick@wgcf"
    systemctl restart wg-quick@wgcf
    green "Wireguard has restarted!"
    echo
}
function startWARP(){
    echo
    echo "systemctl start warp-svc"
    systemctl start warp-svc
    echo
    echo "warp-cli connect"
    warp-cli connect
    echo
    echo "warp-cli enable-always-on"
    warp-cli enable-always-on
    green "WARP SOCKS5 proxy started!"
}
function stopWARP(){
    echo
    echo "warp-cli disable-always-on"
    warp-cli disable-always-on
    echo
    echo "warp-cli disconnect"
    warp-cli disconnect
    echo
    echo "systemctl stop warp-svc"
    systemctl stop warp-svc
    green "WARP SOCKS5 Proxy Stopped!"
}
function restartWARP(){
    echo
    echo "warp-cli disable-always-on"
    warp-cli disable-always-on
    echo
    echo "warp-cli disconnect"
    warp-cli disconnect
    echo
    echo "systemctl restart warp-svc"
    systemctl restart warp-svc
    sleep 5s
    echo
    read -p "Press enter to continue"
    echo
    echo "warp-cli connect"
    warp-cli connect
    echo
    echo "warp-cli enable-always-on"
    warp-cli enable-always-on
    echo
    green "WARP SOCKS5 proxy restarted!"
    echo
}

function checkWireguard(){
    echo
    green " =================================================="
    echo
    green " 1. Check the current system kernel version to see if Wireguard startup fails because multiple kernel versions are installed"
    echo
    green " 2. Check the running status of Wireguard and WARP SOCKS5 proxy"
    echo
    green " 3. Check the Wireguard running log. If Wireguard fails to start, use this to find the problem."
    green " 4. Start Wireguard "
    green " 5. Stop Wireguard "
    green " 6. Restart Wireguard "
    green " 7. Check the running status of Wireguard and WARP wgcf status "
    green " 8. View the Wireguard configuration file ${configWireGuardConfigFilePath} "
    green " 9. Use VI to edit the Wireguard configuration file ${configWireGuardConfigFilePath} "
    echo
    green " 11. Check the WARP SOCKS5 operation log. If WARP fails to start, use this to find the problem."
    green " 12. Start WARP SOCKS5 proxy"
    green " 13. Stop WARP SOCKS5 proxy"
    green " 14. Restart WARP SOCKS5 Proxy"
    echo
    green " 15. Check the running status of WARP SOCKS5 warp-cli status"
    green " 16. View WARP SOCKS5 connection information warp-cli warp-stats"
    green " 17. View WARP SOCKS5 settings information warp-cli settings"
    green " 18. View WARP SOCKS5 account information warp-cli account"

    green " =================================================="
    green "0. Exit script"
    echo
    read -p "Please enter a number:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            showLinuxKernelInfo
            listInstalledLinuxKernel
        ;;
        2 )
            echo
            #echo "systemctl status wg-quick@wgcf"
            #systemctl status wg-quick@wgcf
            #red "Please check the Active: line above. If the text is green, the startup is normal, otherwise the startup fails."
            checkWireguardBootStatus
            checkWarpClientStatus
        ;;
        3 )
            echo
            echo "journalctl -n 100 -u wg-quick@wgcf"
            journalctl -n 100 -u wg-quick@wgcf
            red "Please check the line containing Error above to find the reason for the startup failure"
        ;;
        4 )
            echo
            echo "systemctl start wg-quick@wgcf"
            systemctl start wg-quick@wgcf
            echo
            green "Wireguard is enabled!"
            checkWireguardBootStatus
        ;;
        5 )
            echo
            echo "systemctl stop wg-quick@wgcf"
            systemctl stop wg-quick@wgcf
            echo
            green "Wireguard has stopped!"
            checkWireguardBootStatus
        ;;
        6 )
            restartWireguard
            checkWireguardBootStatus
        ;;
        7 )
            echo
            green "Running command 'wgcf status' to check device status :"
            echo
            wgcf status
            echo
            echo
            green "Running command 'wgcf trace' to verify WARP/WARP+ works :"
            echo
            wgcf trace
            echo
        ;;
        8 )
            echo
            echo "cat ${configWireGuardConfigFilePath}"
            cat ${configWireGuardConfigFilePath}
        ;;
        9 )
            echo
            echo "vi ${configWireGuardConfigFilePath}"
            vi ${configWireGuardConfigFilePath}
        ;;
        11 )
            echo
            echo "journalctl --no-pager -u warp-svc "
            journalctl --no-pager -u warp-svc
            red "Please check the line containing Error above to find the reason for the startup failure"
        ;;
        12 )
            startWARP
            checkWarpClientStatus
        ;;
        13 )
            stopWARP
            checkWarpClientStatus
        ;;
        14 )
            restartWARP
            checkWarpClientStatus
        ;;
        15 )
            echo
            echo "warp-cli status"
            warp-cli status
        ;;
        16 )
            echo
            echo "warp-cli warp-stats"
            warp-cli warp-stats
        ;;
        17 )
            echo
            echo "warp-cli settings"
            warp-cli settings
        ;;
        18 )
            echo
            echo "warp-cli account"
            warp-cli account
        ;;
        0 )
            exit 1
        ;;
        * )
            clear
            red "Please enter a correct number!"
            sleep 2s
            checkWireguard
        ;;
    esac


}











































function start_menu(){
    clear

    if [[ $1 == "first" ]] ; then
        getLinuxOSRelease
        installSoftDownload
    fi
    showLinuxKernelInfoNoDisplay

    if [[ ${configLanguage} == "en" ]] ; then
    green " =================================================="
    green "Linux kernel one-click installation script | 2024-09-25 | System support: centos7+ / debian10+ / ubuntu16.04+"
    green "Linux kernel 4.9 and above all support BBR. If you want to enable BBR Plus, you need to install a kernel that supports BBR Plus."
    red "Please use this script with caution in any production environment. Upgrading the kernel is risky. Please make a backup! On some VPS, it may cause failure to boot!"
    green " =================================================="
    if [[ -z ${osKernelBBRStatus} ]]; then
        echo -e "Current system kernel: ${osKernelVersionBackup} (${virtual}) ${Red_font_prefix} BBR or BBR Plus ${Font_color_suffix} acceleration kernel is not installed, please install kernel 4.9 or above first"
    else
        if [ ${systemBBRRunningStatus} = "no" ]; then
            echo -e "Current system kernel: ${osKernelVersionBackup} (${virtual}) ${Green_font_prefix} has been installed ${osKernelBBRStatus}${Font_color_suffix} acceleration kernel, ${Red_font_prefix}${systemBBRRunningStatusText}${Font_color_suffix} "
        else
            echo -e "Current system kernel: ${osKernelVersionBackup} (${virtual}) ${Green_font_prefix} has been installed ${osKernelBBRStatus}${Font_color_suffix} acceleration kernel, ${Green_font_prefix}${systemBBRRunningStatusText}${Font_color_suffix} "
        fi
    fi
    echo -e "Current congestion control algorithm: ${Green_font_prefix}${net_congestion_control}${Font_color_suffix} Een: ${Green_font_prefix}${systemEenStatusText}${Font_color_suffix} Current queue algorithm: ${Green_font_prefix}${net_qdisc}${Font_color_suffix} "

    echo
    green " 1. Check the current system kernel version and whether it supports BBR / BBR2 / BBR Plus"
    green " 2. Enable BBR or BBR2 acceleration. Enabling BBR2 requires installing the XanMod kernel"
    green " 3. Enable BBR Plus acceleration"
    green "4. Optimize system network configuration"
    red "5. Delete system network optimization configuration"
    echo
    green " 6. Check the running status of Wireguard"
    green " 7. Restart Wireguard "
    green " 8. Check the running status of WARP SOCKS5 proxy"
    green " 9. Restart WARP SOCKS5"
    green " 10. Check the running status and error log of WireGuard and WARP SOCKS5. If WireGuard fails to start, please select this option to troubleshoot the error."
    echo
    green " 11. Install the official Cloudflare WARP Client to start the SOCKS5 proxy to unlock Netflix restrictions"
    green " 12. Install WireGuard and Cloudflare WARP tool Wgcf, enable IPv4 or IPv6, to avoid pop-up Google human-machine verification"
    green " 13. Installing the official Cloudflare WARP Client, WireGuard and command line tool Wgcf at the same time is not recommended"
    red " 14. Uninstall WireGuard and Cloudflare WARP linux client"
    green " 15. Switch WireGuard to support IPv6 and IPv4 networks for VPS servers"
    green " 16. Set the VPS server IPv4 or IPv6 network priority access"

    green "21. Install warp script by fscarmen"
    green "22. Install warp-go script by fscarmen"
    green " 23. Automatically refresh WARP IP until Netflix non-self-made dramas are supported to be unlocked"
    # green " 22. Test whether VPS supports Netflix non-self-made drama unlocking Support WARP SOCKS5 test Highly recommended"

    echo

    if [[ "${osRelease}" == "centos" ]]; then
    green "31. Install the latest version of kernel 6.1, install through elrepo source"
    green "32. Install LTS kernel 5.4 LTS, install through elrepo source"
    green "33. Install kernel 4.14 LTS, download and install from the altarch website"
    green "34. Install kernel 4.19 LTS, download and install from the altarch website"
    green "35. Install kernel 5.4 LTS, download and install from elrepo website"
    echo
    green "36. Install kernel 5.10 LTS, Teddysun compilation recommended installation"
    green "37. Install kernel 5.15 LTS, Teddysun compilation recommended installation"
    green " 38. Install kernel 6.1 LTS, compile, download and install with Teddysun. "
    green " 39. Install kernel 6.6 LTS, compile, download and install with Teddysun. "
    green " 40. Install kernel 6.11, elrepo official compilation. "

    else
        if [[ "${osRelease}" == "debian" ]]; then

            if [[ "${osReleaseVersion}" == "10" ]]; then
                green " 41. Install LTS kernel 5.10 LTS, install through Debian official source"
            fi
            if [[ "${osReleaseVersion}" == "11" ]]; then
                green " 41. Install LTS kernel 5.10 LTS, install through Debian official source"
                green "42. Install kernel 5.19, install through Debian official source"
                green " 43. Install the latest kernel version 6.1 or higher, install from the Debian official source"
            fi
            if [[ "${osReleaseVersion}" == "12" ]]; then
                green " 43. Install LTS kernel 6.1 LTS, install through Debian official source"
            fi
            echo
        fi

        green "44. Install kernel 4.19 LTS, install via Ubuntu kernel mainline"
        green "45. Install kernel 5.4 LTS, install via Ubuntu kernel mainline"
        green "46. Install kernel 5.10 LTS, install via Ubuntu kernel mainline"
        green "47. Install kernel 5.15, install via Ubuntu kernel mainline"
        green "48. Install kernel 5.19, install via Ubuntu kernel mainline"
        green " 49. Install the latest version of the kernel 6.1, install through the Ubuntu kernel mainline"
        echo
        green "51. Install XanMod Kernel 6.6 LTS, official source installation"
        green "52. Install XanMod Kernel 6.11, official source installation"

    fi

    echo
    green " 61. Install BBR Plus kernel 4.14.129 LTS, cx9208 compiled dog250 original version, recommended to use"
    green "62. Install BBR Plus kernel 4.14 LTS, UJX6N compilation"
    green "63. Install BBR Plus kernel 4.19 LTS, UJX6N compilation"
    green "64. Install BBR Plus kernel 5.10 LTS, UJX6N compilation"
    green "65. Install BBR Plus kernel 5.15 LTS, UJX6N compilation"
    green "66. Install BBR Plus kernel 6.1 LTS, UJX6N compilation"
    green "67. Install BBR Plus kernel 6.6 LTS, UJX6N compilation"
    green " 68. Install BBR Plus latest kernel 6.7 or higher, UJX6N compile"

    echo
    green "0. Exit script"


    else

    green " =================================================="
    green "Linux kernel install script | 2024-09-25 | OS support: centos7+ / debian10+ / ubuntu16.04+"
    green " Enable bbr require linux kernel higher than 4.9. Enable bbr plus require special bbr plus kernel "
    red " Please use this script with caution in production. Backup your data first! Upgrade linux kernel will cause VPS unable to boot sometimes."
    green " =================================================="
    if [[ -z ${osKernelBBRStatus} ]]; then
        echo -e "Current Kernel: ${osKernelVersionBackup} (${virtual}) ${Red_font_prefix}Not install BBR / BBR Plus ${Font_color_suffix} , Please install kernel which is higher than 4.9"
    else
        if [ ${systemBBRRunningStatus} = "no" ]; then
            echo -e " Current Kernel: ${osKernelVersionBackup} (${virtual}) ${Green_font_prefix}installed ${osKernelBBRStatus}${Font_color_suffix} kernel, ${Red_font_prefix}${systemBBRRunningStatusText}${Font_color_suffix} "
        else
            echo -e " Current Kernel: ${osKernelVersionBackup} (${virtual}) ${Green_font_prefix}installed ${osKernelBBRStatus}${Font_color_suffix} kernel, ${Green_font_prefix}${systemBBRRunningStatusText}${Font_color_suffix} "
        fi
    fi
    echo -e " Congestion Control Algorithm: ${Green_font_prefix}${net_congestion_control}${Font_color_suffix} Een: ${Green_font_prefix}${systemEenStatusText}${Font_color_suffix} Network Queue Algorithm: ${Green_font_prefix}${net_qdisc}${Font_color_suffix} "

    echo
    green " 1. Show current linux kernel version, check supoort BBR / BBR2 / BBR Plus or not"
    green " 2. enable bbr / bbr2 acceleration, (bbr2 require XanMod kernel)"
    green " 3. enable bbr plus acceleration"
    green " 4. Optimize system network configuration"
    red " 5. Remove system network optimization configuration"
    echo
    green " 6. Show Wireguard working status"
    green " 7. restart Wireguard "
    green " 8. Show WARP SOCKS5 proxy working status"
    green " 9. restart WARP SOCKS5 proxy"
    green " 10. Show WireGuard and WARP SOCKS5 working status, error log, etc."
    echo
    green " 11. Install official Cloudflare WARP linux client SOCKS5 proxy, in order to unlock Netflix geo restriction "
    green " 12. Install WireGuard and Cloudflare WARP tool Wgcf, enable IPv4 or IPv6, avoid Google reCAPTCHA"
    green " 13. Install official Cloudflare WARP linux client, WireGuard and WARP toll Wgcf, not recommended "
    red " 14. Remove WireGuard and Cloudflare WARP linux client"
    green " 15. Switch WireGuard using IPv6 or IPv4 for your VPS"
    green " 16. Set VPS using IPv4 or IPv6 first to access network"

    green " 21. Install warp by fscarmen. Enable IPv6, avoid Google reCAPTCHA and unlock Netflix geo restriction "
    green " 22. Install warp-go by fscarmen. Enable IPv6, avoid Google reCAPTCHA and unlock Netflix geo restriction "
    green " 23. Auto refresh Cloudflare WARP IP to unlock Netflix non-self produced drama"
    echo

    if [[ "${osRelease}" == "centos" ]]; then
    green " 31. Install latest linux kernel, 6.1, from elrepo yum repository"
    green " 32. Install LTS linux kernel, 5.4 LTS, from elrepo yum repository"
    green " 33. Install linux kernel 4.14 LTS, download and install from altarch website"
    green " 34. Install linux kernel 4.19 LTS, download and install from altarch website"
    green " 35. Install linux kernel 5.4 LTS, download and install from elrepo website"
    echo
    green " 36. Install linux kernel 5.10 LTS, compile by Teddysun. Recommended"
    green " 37. Install linux kernel 5.15 LTS, compile by Teddysun. Recommended"
    green " 38. Install linux kernel 6.1 LTS compile by Teddysun. Recommended"
    green " 39. Install linux kernel 6.6 LTS compile by Teddysun. Recommended"
    green " 40. Install linux kernel 6.11, compile by elrepo "
    else
        if [[ "${osRelease}" == "debian" ]]; then
            if [[ "${osReleaseVersion}" == "10" ]]; then
                green " 41. Install LTS linux kernel, 5.10 LTS, from Debian repository source"
            fi

            if [[ "${osReleaseVersion}" == "11" ]]; then
                green " 41. Install LTS linux kernel, 5.10 LTS, from Debian repository source"
                green " 42. Install linux kernel, 5.19, from Debian repository source"
                green " 43. Install latest linux kernel, 6.1 or higher, from Debian repository source"
            fi
            if [[ "${osReleaseVersion}" == "12" ]]; then
                green " 43. Install LTS linux kernel, 6.1 LTS, from Debian repository source"
            fi
            echo
        fi

    green " 44. Install linux kernel 4.19 LTS, download and install from Ubuntu kernel mainline"
    green " 45. Install linux kernel 5.4 LTS, download and install from Ubuntu kernel mainline"
    green " 46. Install linux kernel 5.10 LTS, download and install from Ubuntu kernel mainline"
    green " 47. Install linux kernel 5.15, download and install from Ubuntu kernel mainline"
    green " 48. Install linux kernel 5.19, download and install from Ubuntu kernel mainline"
    green " 49. Install latest linux kernel 6.1, download and install from Ubuntu kernel mainline"
    echo
    green " 51. Install XanMod kernel 6.6 LTS, from XanMod repository source "
    green " 52. Install XanMod kernel 6.11, from XanMod repository source "
    fi

    echo
    green " 61. Install BBR Plus kernel 4.14.129 LTS, compile by cx9208 from original dog250 source code. Recommended"
    green " 62. Install BBR Plus kernel 4.14 LTS, compile by UJX6N"
    green " 63. Install BBR Plus kernel 4.19 LTS, compile by UJX6N"
    green " 64. Install BBR Plus kernel 5.10 LTS, compile by UJX6N"
    green " 65. Install BBR Plus kernel 5.15 LTS, compile by UJX6N"
    green " 66. Install BBR Plus kernel 6.1 LTS, compile by UJX6N"
    green " 67. Install BBR Plus kernel 6.6 LTS, compile by UJX6N"
    green " 68. Install BBR Plus latest kernel 6.7 or higher, compile by UJX6N"
    echo
    green " 0. exit"

    fi

    echo
    read -r -p "Please input number:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            showLinuxKernelInfo
            listInstalledLinuxKernel
        ;;
        2 )
            enableBBRSysctlConfig "bbr"
        ;;
        3 )
            enableBBRSysctlConfig "bbrplus"
        ;;
        4 )
            addOptimizingSystemConfig
        ;;
        5 )
            removeOptimizingSystemConfig
            sysctl -p
        ;;
        6 )
            checkWireguardBootStatus
        ;;
        7 )
            restartWireguard
            checkWireguardBootStatus
        ;;
        8 )
            checkWarpClientStatus
        ;;
        9 )
            restartWARP
            checkWarpClientStatus
        ;;
        10 )
           checkWireguard
        ;;
        11 )
           installWARPClient
        ;;
        12 )
           installWireguard
        ;;
        13 )
           installWireguard
           installWARPClient
        ;;
        14 )
           removeWireguard
           removeWARP
        ;;
        15 )
           enableWireguardIPV6OrIPV4 "redo"
        ;;
        16 )
           preferIPV4 "redo"
        ;;

        twenty one )
           installWARP
        ;;
        twenty two )
           installWARPGO
        ;;
        twenty three )
           vps_netflix_auto
        ;;
        twenty four )
           vps_netflix_jin
        ;;
        25 )
           vps_netflix_jin_auto
        ;;
        31 )
            linuxKernelToInstallVersion="5.19"
            isInstallFromRepo="yes"
            installKernel
        ;;
        32 )
            linuxKernelToInstallVersion="5.4"
            isInstallFromRepo="yes"
            installKernel
        ;;
        33 )
            linuxKernelToInstallVersion="4.14"
            installKernel
        ;;
        34 )
            linuxKernelToInstallVersion="4.19"
            installKernel
        ;;
        35 )
            linuxKernelToInstallVersion="5.4"
            installKernel
        ;;
        36 )
            linuxKernelToInstallVersion="5.10"
            installKernel
        ;;
        37 )
            linuxKernelToInstallVersion="5.15"
            installKernel
        ;;
        38 )
            linuxKernelToInstallVersion="6.1"
            installKernel
        ;;
        39 )
            linuxKernelToInstallVersion="6.6"
            installKernel
        ;;
        40 )
            linuxKernelToInstallVersion="6.11"
            installKernel
        ;;
        41 )
            linuxKernelToInstallVersion="5.10"
            isInstallFromRepo="yes"
            installKernel
        ;;
        42 )
            linuxKernelToInstallVersion="5.19"
            isInstallFromRepo="yes"
            installKernel
        ;;
        43 )
            linuxKernelToInstallVersion="6.1"
            isInstallFromRepo="yes"
            installKernel
        ;;
        44 )
            linuxKernelToInstallVersion="4.19"
            installKernel
        ;;
        45 )
            linuxKernelToInstallVersion="5.4"
            installKernel
        ;;
        46 )
            linuxKernelToInstallVersion="5.10.118"
            installKernel
        ;;
        47 )
            linuxKernelToInstallVersion="5.15"
            installKernel
        ;;
        48 )
            linuxKernelToInstallVersion="5.19"
            installKernel
        ;;
        49 )
            linuxKernelToInstallVersion="6.1"
            installKernel
        ;;
        51 )
            linuxKernelToInstallVersion="6.6"
            linuxKernelToBBRType="xanmod"
            isInstallFromRepo="yes"
            installKernel
        ;;
        52 )
            linuxKernelToInstallVersion="6.11"
            linuxKernelToBBRType="xanmod"
            isInstallFromRepo="yes"
            installKernel
        ;;
        61 )
            linuxKernelToInstallVersion="4.14.129"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        62 )
            linuxKernelToInstallVersion="4.14"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        63 )
            linuxKernelToInstallVersion="4.19"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        64 )
            linuxKernelToInstallVersion="5.10"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        65 )
            linuxKernelToInstallVersion="5.15"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        66 )
            linuxKernelToInstallVersion="6.1"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        67 )
            linuxKernelToInstallVersion="6.6"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        68 )
            linuxKernelToInstallVersion="6.7"
            linuxKernelToBBRType="bbrplus"
            installKernel
        ;;
        87 )
            getLatestUbuntuKernelVersion
            getLatestCentosKernelVersion
            getLatestCentosKernelVersion "manual"
        ;;
        88 )
            upgradeScript
        ;;
        89 )
            virt_check
        ;;

        0 )
            exit 1
        ;;
        * )
            clear
            red "Please enter a correct number!"
            sleep 2s
            start_menu
        ;;
    esac
}



function setLanguage(){
    echo
    green " =================================================="
    green "Please choose your language"
    green " 1. English"
    green " 2. Chinese"
    echo
    read -r -p "Please input your language:" languageInput

    case "${languageInput}" in
        1 )
            echo "en" > ${configLanguageFilePath}
            showMenu
        ;;
        2 )
            echo "en" > ${configLanguageFilePath}
            showMenu
        ;;
        * )
            red " Please input the correct number !"
            setLanguage
        ;;
    esac
}

configLanguageFilePath="${HOME}/language_setting_v2ray_trojan.md"
configLanguage="en"

function showMenu(){

    if [ -f "${configLanguageFilePath}" ]; then
        configLanguage=$(cat ${configLanguageFilePath})

        case "${configLanguage}" in
        en )
            start_menu "first"
        ;;
        en )
            start_menu "first"
        ;;
        * )
            setLanguage
        ;;
        esac
    else
        setLanguage
    fi
}

showMenu
