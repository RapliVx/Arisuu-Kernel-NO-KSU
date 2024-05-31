#!/bin/sh
# Compile script for Nakano kernel
# Copyright (c) RapliVx Aka Rafi Aditya

# Setup
PHONE="beryllium"
ARCH="arm64"
SUBARCH="arm64"
DEFCONFIG=lethal_defconfig
CLANG="Proton Clang"
COMPILER=clang
LINKER=""
COMPILERDIR="/workspace/Arisuu-Kernel-NO-KSU/proton-clang"
export KBUILD_BUILD_USER=Rapli
export KBUILD_BUILD_HOST=PotatoServer

# Header
cyan="\033[96m"
green="\033[92m"
red="\033[91m"
blue="\033[94m"
yellow="\033[93m"

echo -e "$cyan===========================\033[0m"
echo -e "$cyan= START COMPILING KERNEL  =\033[0m"
echo -e "$cyan===========================\033[0m"

echo -e "$blue...KSABAR...\033[0m"

echo -e -ne "$green== (10%)\r"
sleep 0.7
echo -e -ne "$green=====                     (33%)\r"
sleep 0.7
echo -e -ne "$green=============             (66%)\r"
sleep 0.7
echo -e -ne "$green=======================   (100%)\r"
echo -ne "\n"

echo -e -n "$yellow\033[104mPRESS ENTER TO CONTINUE\033[0m"
read P
echo  $P

# Clean
function clean() {
    echo -e "\n"
    echo -e "$red [!] CLEANING UP \\033[0m"
    echo -e "\n"
    rm -rf out
    make mrproper
}

clean

# Outputs
function outputs() {
    echo -e "\n"
    echo -e "$red [!] MAKE OUT DIR \\033[0m"
    echo -e "\n"
    mkdir out
    mkdir out/outputs
    mkdir out/outputs/${PHONE}
    mkdir out/outputs/${PHONE}/OLD-DRIVER-SE
    mkdir out/outputs/${PHONE}/OLD-DRIVER-NSE
    mkdir out/outputs/${PHONE}/NEW-DRIVER-SE
    mkdir out/outputs/${PHONE}/NEW-DRIVER-NSE
}

outputs

# Speed up build process
MAKE="./makeparallel"

# Basic build function
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

Build () {
PATH="${COMPILERDIR}/bin:${PATH}" \
make -j$(nproc --all) O=out \
ARCH=${ARCH} \
CC=${COMPILER} \
CROSS_COMPILE=${COMPILERDIR}/bin/aarch64-linux-gnu- \
CROSS_COMPILE_ARM32=${COMPILERDIR}/bin/arm-linux-gnueabi- \
LD_LIBRARY_PATH=${COMPILERDIR}/lib
}

Build_lld () {
PATH="${COMPILERDIR}/bin:${PATH}" \
make -j$(nproc --all) O=out \
ARCH=${ARCH} \
CC=${COMPILER} \
CROSS_COMPILE=${COMPILERDIR}/bin/aarch64-linux-gnu- \
CROSS_COMPILE_ARM32=${COMPILERDIR}/bin/arm-linux-gnueabi- \
LD=ld.${LINKER} \
AR=llvm-ar \
NM=llvm-nm \
OBJCOPY=llvm-objcopy \
OBJDUMP=llvm-objdump \
STRIP=llvm-strip \
ld-name=${LINKER} \
KBUILD_COMPILER_STRING=${CLANG}
}

# Make defconfig

make O=out ARCH=${ARCH} ${DEFCONFIG}
if [ $? -ne 0 ]
then
    echo -e "\n"
    echo -e "$red [!] BUILD FAILED \033[0m"
    echo -e "\n"
else
    echo -e "\n"
    echo -e "$green==================================\033[0m"
    echo -e "$green= [!] START BUILD ${DEFCONFIG}\033[0m"
    echo -e "$green==================================\033[0m"
    echo -e "\n"
fi

# Build starts here
if [ -z ${LINKER} ]
then
    #Start with 9.1.24-SE
    cp firmware/touch_fw_variant/9.1.24/* firmware/
    cp arch/arm64/boot/dts/qcom/SE_NSE/SE/* arch/arm64/boot/dts/qcom/
    Build
else
    Build_lld
fi

if [ $? -ne 0 ]
then
    echo -e "$red [!] BUILD FAILED \033[0m"
    rm -rf out/outputs/${PHONE}/*
else
    echo -e "$green [!] BUILD SUCCES \033[0m"
    cp out/arch/arm64/boot/Image.gz-dtb out/outputs/${PHONE}/OLD-DRIVER-SE/Image.gz-dtb
    
    #9.1.24-NSE
    cp arch/arm64/boot/dts/qcom/SE_NSE/NSE/* arch/arm64/boot/dts/qcom/
    Build
    if [ $? -ne 0 ]
    then
        echo -e "$red [!] BUILD FAILED \033[0m"
        rm -rf out/outputs/${PHONE}/9.1.24-NSE/*
    else
        echo -e "$green [!] BUILD SUCCES \033[0m"
        cp out/arch/arm64/boot/Image.gz-dtb out/outputs/${PHONE}/OLD-DRIVER-NSE/Image.gz-dtb

        #10.3.7-SE
        cp firmware/touch_fw_variant/10.3.7/* firmware/
        cp arch/arm64/boot/dts/qcom/SE_NSE/SE/* arch/arm64/boot/dts/qcom/
        Build
        if [ $? -ne 0 ]
        then
            echo -e "$red [!] BUILD FAILED \033[0m"
            rm -rf out/outputs/${PHONE}/10.3.7-SE/*
        else
            echo -e "$green [!] BUILD SUCCES \033[0m"
            cp out/arch/arm64/boot/Image.gz-dtb out/outputs/${PHONE}/NEW-DRIVER-SE/Image.gz-dtb

            #10.3.7-NSE
            cp arch/arm64/boot/dts/qcom/SE_NSE/NSE/* arch/arm64/boot/dts/qcom/
            Build
            if [ $? -ne 0 ]
            then
                echo -e "$red [!] BUILD FAILED !\033[0m"
                rm -rf out/outputs/${PHONE}/10.3.7-NSE/*
            else
                echo -e "$green [!] BUILD SUCCES !\033[0m"
                cp out/arch/arm64/boot/Image.gz-dtb out/outputs/${PHONE}/NEW-DRIVER-NSE/Image.gz-dtb
            fi
        fi
    fi
fi

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
if [ -f out/outputs/${PHONE}/NEW-DRIVER-NSE/Image.gz-dtb ] && [ -f out/outputs/${PHONE}/NEW-DRIVER-SE/Image.gz-dtb ] && [ -f out/outputs/${PHONE}/OLD-DRIVER-NSE/Image.gz-dtb ] && [ -f out/outputs/${PHONE}/OLD-DRIVER-SE/Image.gz-dtb ] ; then
    echo -e "$green===========================\033[0m"
    echo -e "$green=  SUCCESS COMPILE KERNEL \033[0m"
    echo -e "$green=  Device    : $PHONE \033[0m"
    echo -e "$green=  Defconfig : $DEFCONFIG \033[0m"
    echo -e "$green=  Toolchain : $CLANG \033[0m"
    echo -e "$green=  Completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) \033[0m "
    echo -e "$green=  Have A Brick Day Nihahahah \033[0m"
    echo -e "$green===========================\033[0m"
else
echo -e "$red [!] FIX YOUR KERNEL SOURCE BRUH !?\033[0m"
fi
