# Fedora安装NVIDIA驱动 开Wayland.md
## 引言
AMD CPU的机器安装linux后，可能亮度无法调节，卡开机等，以下是解决方案。强制CPU渲染或者安装好英伟达驱动后，亮度可以调节

## 开机进不去系统(常见于AMD CPU)
grub菜单把启动的内核选中按e，出现linux的那行末尾追加 
```txt
nomodeset rd.driver.blacklist=nouveau modprobe.blacklist=nouveau
```

## 进入系统后

由于是临时追加，重启丢失，推荐写入grub。
**/etc/default/grub**找到**GRUB_CMDLINE_LINUX**行，追加:
```txt
nomodeset rd.driver.blacklist=nouveau modprobe.blacklist=nouveau
```

随后，执行以下命令更新grub配置。
重启后，会强制全局使用CPU渲染，风扇吵，安装完英伟达驱动后务必移除刚才的参数并再次执行下面的命令。
```sh
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

### 前期准备
- 安装一些工具链，等下安装英伟达驱动时，编译内核模块需要
```sh
sudo dnf update -y
sudo dnf install @base-x kernel-devel kernel-headers gcc make dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig xorg-x11-server-Xwayland libxcb egl-wayland
```

### 写一些配置
- 彻底禁用nouveau
```sh
echo -e "blacklist nouveau\noptions nouveau modeset=0" | sudo tee /etc/modprobe.d/nouveau_blacklist.conf
```

- 优化NVIDIA显卡配置
```sh
sudo tee /etc/modprobe.d/nvidia.conf <<EOF
options nvidia-drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF
```

- **令刚才的修改生效(必做)**
```sh
sudo dracut --force
```


## 开始安装驱动
### 安装(方法1，不是很推荐)
- 快速去英伟达官网下载驱动，尽可能别放中文路径的目录 
https://www.nvidia.com/zh-cn/drivers
- 执行以下代码，重启，随后会进入纯命令行
```sh
sudo systemctl set-default multi-user.target && reboot
```

- 输入su，以超级用户身份执行命令，避免后续每次都输入sudo

- 设置环境变量
```sh
export CC="gcc -std=gnu17"
```

- 找到你下载的英伟达驱动，**NVIDIAxxxx.run**，chmod +x /path/to/nvidia_driver.run; ./path/to/nvidia_driver.run
选择英伟达私有驱动，一路选Yes，rebuild initramfs，运行nvidia-xconfig

- 完成之后，查看是否安装成功:
```sh
systemctl set-default graphical.target && reboot
```

- 给/etc/dkms/framework.conf 加点变量
```sh
sudo cp /etc/dkms/framework.conf  /etc/dkms/framework.conf.bak
sudo sed -i '6iCC="gcc -std=gnu17"' /etc/dkms/framework.conf
```

- 重新登录
- 启动守护进程
```sh
systemctl enable nvidia-suspend.service
systemctl enable nvidia-hibernate.service
systemctl enable nvidia-resume.service
```

## 安装方法2(推荐，直接拉mirror.rpmfusion)
- 添加rpmfusion源
```sh
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```
- 安装软件包
```sh
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda
```
然后等一会akmod编译内核模块，30s-3min。

- 查看编译日志:
```sh
journalctl -u akmods.service -f
```

- 检查akmod编译完毕，有东西则编译完成
```sh
ls /lib/modules/$(uname -r)/extra/nvidia/
```

- 如果有编译完成的内核模块，执行以下命令，启动守护进程:
```sh
systemctl enable nvidia-suspend.service
systemctl enable nvidia-hibernate.service
systemctl enable nvidia-resume.service
```

- 随后，输入nvidia-smi，有可能提示版本不匹配等其他问题，重启电脑即可

## 最后(必做)
- 移除第一步加的命令行参数(/etc/default/grub)
```sh
sed -i 's/nomodeset rd.driver.blacklist=nouveau modprobe.blacklist=nouveau//g' /etc/default/grub && sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```
这条命令未经测试，理论无问题，执行后手动查看一下是否修改成功。失败需手动修改

- 重新生成initramfs
```sh
sudo dracut --force
```

## 其他优化(可选，推荐)
```sh
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo dnf group install multimedia -y
```
- linux桌面通用，优化耗电
```sh
sudo dnf install tlp -y
sudo systemctl enable tlp
```
