# AnduinOS
> 这个是我目前最喜欢的一个发行版。对比ZorinOS，它的工具链更新，内核更新，外观仿win11也更符合我的审美。最主要的是不需要花费过多精力倒腾桌面主题美化，全部开箱即用，遇到小问题最少的。同时，由于砍掉了很多无用的工具，如snap，内存占用低，流畅度也很高

## 桌面变成gnome默认样式
- 原因是扩展被关闭了，但具体成因未知。只需要在设置里搜索 扩展，打开总开关即可

- 搜索 优化，可以改一些样式，如光标指针

## 有英伟达显卡的进行一些优化
- 安装闭源驱动

```bash
sudo apt install nvidia-drivers-580 nvidia-dkms-580 -y
```
> 如果有更新的版本号，也可以安装

- 安装好英伟达闭源驱动后，执行以下内容:
```bash
sudo tee /etc/modprobe.d/nvidia.conf <<EOF
options nvidia-drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF

echo -e "blacklist nouveau\noptions nouveau modeset=0" | sudo tee /etc/modprobe.d/nouveau_blacklist.conf

systemctl enable nvidia-suspend.service
systemctl enable nvidia-hibernate.service
systemctl enable nvidia-resume.service

sudo dracut --force
```

## 设置开机自启动脚本
- 先把脚本放到`/opt/pandora/pandora_opt.sh`
- 给予执行权限(x): 
```bash
sudo chmod +x /opt/pandora/pandora_opt.sh
```
- 编写service文件，放到`/etc/systemd/system/pandora.service`
其中，文件命名以`*.service`即可，不要忘记
```txt
[Unit]
Description=Optimize linux system
# 确保在图形会话启动后启动
After=graphical-session.target

[Service]
Type=simple
# 直接以root身份运行，无需sudo
ExecStart=/opt/pandora/pandora_opt.sh
# WorkingDirectory=/path/to/working/directory  # 可选
# Restart=on-failure
# RestartSec=5

# 如果程序需要环境变量
# Environment="VAR1=value1"
# Environment="VAR2=value2"

# 以root身份运行
User=root
Group=root

[Install]
WantedBy=graphical.target
```
由于我的是一次性脚本，就没有添加挂了再拉起的机制(守护进程)。以上脚本，用户登入后才开始执行

 | `WantedBy` 目标 | 启动时机 | 适用场景 | 风险 |
 | :--- | :--- | :--- | :--- |
 | `multi-user.target` | **标准**（网络已就绪） | **几乎所有后台服务** | **低（推荐）** |
 | `graphical.target` | 桌面环境完全启动后 | 依赖图形界面的程序 | 低 |
 | `basic.target` | **非常早**（基础服务后） | 核心系统工具 | **高（谨慎）** |
 | `rescue.target` | 救援模式 | 系统修复工具 | **极高（不推荐）** |


- 完成后，执行以下命令:
```bash
sudo systemctl daemon-reload
sudo systemctl enable pandora.service
sudo systemctl start pandora.service
sudo systemctl status pandora.service
```

## 分享一下脚本优化内容:
- 方案来源于安卓玩机圈 Pandora内核团队

```sh
#!/bin/bash
set -x

[ "$(whoami)" != "root" ] && echo "非root用户无法执行" &&  exit 1

mkdir -p /dev/mount_masks

# $1:value $2:path
lock_val() {
    find "$2" -type f | while read -r file; do
        file="$(realpath "$file")"
        umount "$file"
        chown root:root "$file"
        chmod 0644 "$file"
        echo "$1" >"$file"
        chmod 0444 "$file"
    done
}

# $1:value $2:path
mask_val() {
    find "$2" -type f | while read -r file; do
        file="$(realpath "$file")"
        lock_val "$1" "$file"

        TIME="$(date "+%s%N")"
        echo "$1" >"/dev/mount_masks/mount_mask_$TIME"
        mount --bind "/dev/mount_masks/mount_mask_$TIME" "$file"
        restorecon -R -F "$file" >/dev/null 2>&1
    done
}

init_blk() {
    for sd in /sys/block/loop*; do
        lock_val "none" "$sd/queue/scheduler"
        lock_val "0" "$sd/queue/iostats"
        lock_val "2" "$sd/queue/nomerges"
        lock_val "128" "$sd/queue/read_ahead_kb"
        lock_val "128" "$sd/bdi/read_ahead_kb"
    done

    for sd in /sys/block/nvme*; do
        lock_val "adios" "$sd/queue/scheduler"
        lock_val "1" "$sd/queue/iostats"
        lock_val "0" "$sd/queue/nomerges"
        lock_val "8192" "$sd/queue/read_ahead_kb"
        lock_val "8192" "$sd/bdi/read_ahead_kb"
    done

    for sd in /sys/block/nvme*; do
        cat "$sd/queue/scheduler"
        cat "$sd/queue/iostats"
        cat "$sd/queue/nomerges"
        cat "$sd/queue/read_ahead_kb"
        cat "$sd/bdi/read_ahead_kb"
    done
}

init_thp() {
    lock_val "madvise" /sys/kernel/mm/transparent_hugepage/enabled
    lock_val "always" /sys/kernel/mm/transparent_hugepage/defrag
    lock_val "within_size" /sys/kernel/mm/transparent_hugepage/shmem_enabled
    for size in 16 32 64 128 256 512 1024 2048; do
        lock_val "inherit" /sys/kernel/mm/transparent_hugepage/hugepages-"$size"kB/enabled
    done
    # Oryon Page Translation supports 4K and 64K but no 16K, but never mind
    # if [ "$(getprop ro.soc.model)" = "SM8750" ]; then
    #     for size in 16 32; do
    #         lock_val "pdr_never" /sys/kernel/mm/transparent_hugepage/hugepages-"$size"kB/enabled
    #     done
    # fi
    lock_val "1" /sys/kernel/mm/transparent_hugepage/use_zero_page
    lock_val "-1" /sys/kernel/mm/transparent_hugepage/khugepaged/alloc_sleep_millisecs
    lock_val "0" /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
    lock_val "8" /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none
    lock_val "64" /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_swap
    lock_val "511" /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_shared
    lock_val "65536" /sys/kernel/mm/transparent_hugepage/khugepaged/pages_to_scan

    # sleep 30s
    lock_val "100" /sys/kernel/mm/transparent_hugepage/khugepaged/scan_sleep_millisecs
    # while [ "$(cat /sys/kernel/mm/transparent_hugepage/khugepaged/full_scans)" -lt "3" ]; do
    #     sleep 1s
    # done
    # lock_val "6000" /sys/kernel/mm/transparent_hugepage/khugepaged/scan_sleep_millisecs
}

init_network() {
    lock_val "1" /proc/sys/net/ipv4/tcp_shrink_window
    lock_val "10" /proc/sys/net/ipv4/tcp_reordering
    lock_val "1000" /proc/sys/net/ipv4/tcp_max_reordering
    lock_val "1" /proc/sys/net/ipv4/tcp_thin_linear_timeouts
    lock_val "1048576" /proc/sys/net/core/rmem_default
    lock_val "16777216" /proc/sys/net/core/rmem_max
    lock_val "65536 1048576 16777216" /proc/sys/net/ipv4/tcp_rmem
    lock_val "1048576" /proc/sys/net/core/wmem_default
    lock_val "16777216" /proc/sys/net/core/wmem_max
    lock_val "65536 1048576 16777216" /proc/sys/net/ipv4/tcp_wmem
}

init_zram_per() {
    swapoff "/dev/zram$1"
    lock_val "1" "/sys/class/block/zram$1/reset"
    lock_val "0" "/sys/class/block/zram$1/mem_limit"
    lock_val "$2" "/sys/class/block/zram$1/comp_algorithm"
    lock_val "$(awk 'NR==1{print $2*2048}' </proc/meminfo)" "/sys/class/block/zram$1/disksize"
    mkswap "/dev/zram$1"
    swapon "/dev/zram$1"
    # rm "/dev/zram$1"
    # touch "/dev/zram$1"
}

init_zram() {
    grep -q zram /proc/swaps && return

    init_zram_per "0" "zstd"
}

init_mem() {
    lock_val "1" /proc/sys/vm/swappiness
    lock_val "20" /proc/sys/vm/compaction_proactiveness
    lock_val "0" /proc/sys/vm/page-cluster
    lock_val "32768" /proc/sys/vm/min_free_kbytes
    lock_val "150" /proc/sys/vm/watermark_scale_factor
    lock_val "15000" /proc/sys/vm/watermark_boost_factor
    lock_val "1" /proc/sys/vm/overcommit_memory
    lock_val "5" /proc/sys/vm/dirty_ratio
    lock_val "2" /proc/sys/vm/dirty_background_ratio
    lock_val "60" /proc/sys/vm/dirtytime_expire_seconds

    lock_val "1000" /sys/kernel/mm/lru_gen/min_ttl_ms
    lock_val "Y" /sys/kernel/mm/lru_gen/enabled
}

init_zram
init_blk
init_thp
init_network
init_mem

```