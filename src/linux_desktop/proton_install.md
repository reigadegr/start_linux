# flatpak安装proton


## 1：确保用户级flatpak能读系统整书
```sh
flatpak override --user --filesystem=/etc/ssl/certs:ro
```

## 2. 添加 flathub-beta 仓库,忽略SSL错误
```sh
flatpak remote-add --user --if-not-exists --no-gpg-verify flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo

flatpak remote-add --user --if-not-exists --no-gpg-verify flathub https://mirrors.ustc.edu.cn/flathub
```

## 3：验证仓库连通性（无报错就是成功）

```sh
flatpak update --user
```

## 4. 强制卸载无用软件及残留旧运行时
flatpak uninstall --user -y net.lutris.Lutris
flatpak uninstall --user --unused -y

## 5 安装 Lutris beta 版（基于 GNOME 49 + 新运行时)
flatpak install --user flathub-beta net.lutris.Lutris -y
flatpak install --user flathub com.vysp3r.ProtonPlus -y
 
## 6：清理无用运行时
```sh
flatpak uninstall --user --unused -y
```
 
## 7：给Lutris补全游戏权限（Steam/Proton都能读）
```sh
mkdir -p ~/Games ~/Downloads

flatpak override --user \
--filesystem=xdg-data/Steam:ro \
--filesystem=~/Games:rw \
--filesystem=~/Downloads:rw \
--socket=wayland --socket=x11 --socket=pulseaudio \
--device=all \
net.lutris.Lutris

 flatpak override --user \
--filesystem=xdg-data/Steam:rw \
--filesystem=~/Games:rw \
--filesystem=~/Downloads:rw \
--filesystem=~/.var/app/net.lutris.Lutris:rw \
--socket=wayland --socket=x11 --socket=pulseaudio \
--device=dri \
com.vysp3r.ProtonPlus
```
