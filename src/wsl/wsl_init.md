# wsl相关
本节介绍与wsl相关的内容，以wsl2解释

## 安装wsl
本教程于Ubuntu-22.04，Arch版本成功，理论上其他版本也可以

### 开启hyper-v

```bat
pushd "%~dp0"

dir /b %SystemRoot%\servicing\Packages\*Hyper-V*.mum >hyper-v.txt

for /f %%i in ('findstr /i . hyper-v.txt 2^>nul') do dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i"

del hyper-v.txt

Dism /online /enable-feature /featurename:Microsoft-Hyper-V-All /LimitAccess /ALL
```

- 非win专业版系统。需要把这个写进一个bat，例如`Enable-hyper-v.bat`。执行，需要使用管理员权限执行。

- 之后，管理员权限一条一条执行：（powershell）

  ```powershell
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
  Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
  ```
  

- 保险起见，cmd执行(管理员)：

```cmd
cmd /c bcdedit /set hypervisorlaunchtype auto
```

然后去微软商店下载wsl Ubuntu-22.04。其他版本也可以，用这个做事例

```txt
1.查看WSL发行版本
在Windows PowerShell中输入命令:

wsl -l -v

2.导出分发版为tar文件到d盘
wsl --export Ubuntu-22.04 E:\wsl\wsl.tar

3.注销当前分发版
wsl --unregister Ubuntu-22.04

4.重新导入并安装WSL在d:\wsl-ubuntu20.04（可以修改成其他的目录）
wsl --import Ubuntu-22.04 E:\wsl_file E:\wsl\wsl.tar

5.设置默认登陆用户为安装时用户名
ubuntu2204 config --default-user reigadegr

6.设置默认wsl系统
wsl --setdefault Arch
```

## 设置默认发行版

```shell
wsl --setdefault Ubuntu-22.04
```

## 换源

```sh
# 1. 备份
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%F)

# 2. 整体替换为清华源
sudo sed -i 's|http://archive.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list
sudo sed -i 's|http://security.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list

# 3. 更新软件列表
sudo apt update
sudo apt upgrade
```

## ArchLinux

```txt
1.查看WSL发行版本
在Windows PowerShell中输入命令:

wsl -l -v

2.导出分发版为tar文件到d盘
wsl --export Arch E:\wsl\wsl.tar

3.注销当前分发版
wsl --unregister Arch

4.重新导入并安装WSL（可以修改成你自己想要的目录）
wsl --import Arch E:\wsl_file E:\wsl\wsl.tar


5.设置默认登陆用户为安装时用户名
arch config --default-user reigadegr

6.设置默认wsl系统
wsl --setdefault Arch
```

## 换源

```sh
sudo sed -i '1iServer = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist
```



## 修复wsl2联网

按照以上操作执行之后，进行 ping www.baidu.com。

- 如果可以正常通信，则不需要进行以下步骤。
- 如果可以正常通信，则不需要进行以下步骤。
- 如果可以正常通信，则不需要进行以下步骤。
- 如果可以正常通信，则不需要进行以下步骤。


```txt
https://github.com/sakai135/wsl-vpnkit
```

下载.gz包

同级目录打开powershell（不需要admin)

```powershell
wsl --import wsl-vpnkit $env:USERPROFILE\wsl-vpnkit wsl-vpnkit.tar.gz --version 2
wsl -d wsl-vpnkit
wsl.exe -d wsl-vpnkit service wsl-vpnkit start

可以做成开机自启动
```

登录后再提权su，存在不明bug无法直接su登录
