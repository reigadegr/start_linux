# 安卓内核编译
使用镜像站

## 初始化环境

1，下载repo

```shell
curl https://mirrors.tuna.tsinghua.edu.cn/git/git-repo -o repo
```

2，给权限

```shell
chmod +x repo
```

- 小贴士，可以拷贝到PATH

-  ```shell
   sudo cat ./repo > $(which repo)
   ```

```sh
export REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/git/git-repo'
```

也可以把119行的（可能不一定是119行，灵活变通）

```txt
REPO_URL = "https://gerrit.googlesource.com/git-repo"
```

替换：

```txt
REPO_URL = "https://mirrors.tuna.tsinghua.edu.cn/git/git-repo"
```

## 初始化repo仓库

```she
repo init --depth 1 -u https://mirrors.bfsu.edu.cn/git/AOSP/kernel/manifest -b common-android15-6.6-lts
```

## 同步源码

```shell
repo sync -c -j$(nproc --all) --no-tags --no-clone-bundle --force-sync
```

## 编译内核

```shell
tools/bazel run --config=fast --config=stamp --lto=thin //common:kernel_aarch64_dist -- --dist_dir=dist
```

### fast buikd

```shell
tools/bazel run --allow_undeclared_modules --config=fast --config=stamp --verbose_failures //common:kernel_aarch64_dist -- --dist_dir=dist
```

### fast buikd

```shell
tools/bazel run --allow_undeclared_modules --config=fast --config=stamp  //common:kernel_aarch64_dist -- --dist_dir=dist
```

```she
find out/ -name "*hmbird*" -exec rm {} \;
```

## 内存不足（方案，swap开成16G）

```shell
sudo swapoff -a
sudo dd if=/dev/zero of=/var/swapfile bs=1M count=15258
sudo mkswap /var/swapfile
sudo swapon /var/swapfile
free -m
```

