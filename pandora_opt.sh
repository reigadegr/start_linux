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
