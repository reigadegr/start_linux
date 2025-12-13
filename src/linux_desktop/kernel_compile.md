# 内核编译(Ubuntu通用)
## 准备工作
```bash
mkdir -p "$HOME/kernel_workspace/llvm_clang

sudo apt update
sudo apt upgrade -y
sudo apt install -y llvm clang make cmake python3 git curl ccache libelf-dev build-essential flex bison libssl-dev libncurses-dev liblz4-tool zlib1g-dev libxml2-utils rsync zip unzip gawk lsb-release pahole automake zlib1g-dev make openssl bc device-tree-compiler python3-telethon python-is-python3 zstd libzstd-dev pigz asciidoc dos2unix lz4 fakeroot gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi gcc-arm-linux-gnueabihf libc6-dev-armel-cross libc6-dev-armhf-cross libc6-dev-arm64-cross selinux-policy-dev
```
不知道是否齐全。如果有的包不存在，那就把它删掉重新执行对应命令

随后:
- 获取内核源码
- 进入内核源码目录
- 获取当前defconfig

```bash
cat /boot/config-`uname -r` > ./arch/x86/configs/ubuntu_defconfig
```

## 使用系统工具链编译(native build)

- 执行命令:
接上一步的ubuntu_defconfig。系统默认使用自带的gcc编译。这里使用了ccache。ccache前面已经安装过

```bash
#!/bin/bash
export RUSTC="rustc"
export PATH="/usr/lib/ccache:$PATH"
ccache --zero-stats

make -j$(nproc --all) O=out ARCH=x86 ubuntu_defconfig \
KCFLAGS+="-Wno-error" \
LD=ld.lld HOSTLD=ld.lld CC="ccache gcc-15" \
bindeb-pkg 2>&1 | tee build_log.txt

ccache -s
```

我的机子是51分钟编译完成(R7-4800H，8c16t)
如果因为编译过程中缺失依赖，缺啥装啥，当时装的比较乱没有记录。
如果不太明白，可以把报错信息发给ai。推荐浏览器输入`chat.z.ai`，智谱的这个*glm4.6*非常好用，功能齐全，PPT也可以做

## 使用自定义工具链编译内核
> 用系统自带工具链编译确实非常方便快捷，但是有个缺陷，我不太清楚怎么开启LTO(链接时优化)。于是请clang出山

下载(直链):
```bash
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-21.1.7/LLVM-21.1.7-Linux-X64.tar.xz
```

网络环境不佳，可以在开头添加`https://ghfast.top/`，如下:

```bash
wget https://ghfast.top/https://github.com/llvm/llvm-project/releases/download/llvmorg-21.1.7/LLVM-21.1.7-Linux-X64.tar.xz
```

解压缩:
```bash
tar -xvf LLVM-21.1.7-Linux-X64.tar.xz -C "$HOME/kernel_workspace/llvm_clang"

mv "$HOME/kernel_workspace/llvm_clang/LLVM-21.1.7-Linux-X64/*" "$HOME/kernel_workspace/llvm_clang/"

rm -r "$HOME/kernel_workspace/llvm_clang/LLVM-21.1.7-Linux-X64"
```

pahole可装可不装，系统有自带的。不过这里有个小工具包:
```txt
https://github.com/cctv18/oneplus_sm8650_toolchain/releases/download/LLVM-Clang20-r547379/build-tools.zip
```

随后执行以下脚本即可编译，也差不多50多分钟编译完毕
```bash
#!/bin/bash

llvm_clang="$HOME/kernel_workspace/llvm_clang/bin"
cust_pahole="$HOME/kernel_workspace/llvm_clang/build-tools/bin"
export PATH="$llvm_clang:$cust_pahole:$PATH"
export RUSTC="rustc"

export PATH="/usr/lib/ccache:$PATH"
ccache --zero-stats

make -j$(nproc --all) O=out ARCH=x86 ubuntu_defconfig \
KCFLAGS+="-Wno-error" \
CC="ccache clang" \
LD=ld.lld LD_R=ld.lld HOSTLD=ld.lld LLVM=1 LLVM_IAS=1 \
bindeb-pkg 2>&1 | tee build_log.txt

ccache -s
```

## 有关clang开启LTO说明

- 需要在ubuntu_defconfig追加以下内容:

```txt
CONFIG_OBJTOOL_WERROR=n
CONFIG_LTO_NONE=n
CONFIG_LTO_CLANG_FULL=n
CONFIG_LTO_CLANG_THIN=y
```

注意，尽可能不要开full模式进行全量lto，一个是显著增加编译时间 还有就是可能导致无法开机。当然你在有备份的情况下可以尝试。objtool会把警告识别为错误，需要禁用

尽可能按照以下补丁的逻辑去修改你的源码，禁用奇怪的设置

```diff
diff --git a/Makefile b/Makefile
index 827a513e4407bc..bd6569f7764542 100644
--- a/Makefile
+++ b/Makefile
@@ -1026,8 +1026,7 @@ KBUILD_LDFLAGS += -mllvm -import-instr-limit=5
 endif

 ifdef CONFIG_LTO
-KBUILD_CFLAGS  += -fno-lto $(CC_FLAGS_LTO)
-KBUILD_AFLAGS  += -fno-lto
+KBUILD_CFLAGS  += $(CC_FLAGS_LTO)
 export CC_FLAGS_LTO
 endif
```

### 如果你的是英伟达显卡
- 需要把dkms编译英伟达内核模块的链接器从bfd换成lld
文件位置: 

```txt
/usr/src/nvidia-580.95.05/dkms.conf
```
第三级目录的版本号灵活变通一下，不要照抄我的。可以使用vscode打开文件，Ctrl+F搜索bfd 改成lld即可，然后安装三个deb包。注意，不要安装带有dbg字符串的包，除非你知道自己在干什么。先安装linux-headers-开头的deb，其他的两个linux-image-开头的和linux-libc开头的deb包安装顺序无所谓。

## 推荐一些仓库

第一个是我自己的:
https://github.com/reigadegr/linux

cachyOS的:
https://github.com/CachyOS/linux-cachyos

cachyOS补丁仓库:
https://github.com/CachyOS/kernel-patches

安卓玩机圈内核作者 破星sm8750仓库(6.6版本):
https://github.com/TheGeniusClub/android_kernel_common_oneplus_sm8750
