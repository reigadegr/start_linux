## 安装lvorySQL

### 安装依赖
```sh
sudo apt -y install pkg-config libreadline-dev libicu-dev libldap2-dev uuid-dev tcl-dev libperl-dev python3-dev bison flex openssl libssl-dev libpam-dev libxml2-dev libxslt-dev libossp-uuid-dev libselinux-dev gettext
```

### 下载
```sh
wget https://github.com/IvorySQL/IvorySQL/releases/download/IvorySQL_5.1/IvorySQL-5.1-62069c2-20251211.amd64.deb
 ```
 - 也可以使用国内镜像
```sh
wget https://ghfast.top/https://github.com/IvorySQL/IvorySQL/releases/download/IvorySQL_5.1/IvorySQL-5.1-62069c2-20251211.amd64.deb
 ```
### 安装
```sh
sudo dpkg -i IvorySQL-5.1-62069c2-20251211.amd64.deb
```

### 配置
```sh
sudo chown -R ivorysql:ivorysql /usr/ivory-5/

echo "export PATH=/usr/ivory-5/bin:$PATH" >> ~/.bashrc
echo "export PGDATA=~/.ivory-5/data" >> ~/.bashrc

source ~/.bashrc
mkdir -p ~/.ivory-5/data
initdb -D ~/.ivory-5/data
```
### 启动
```sh
pg_ctl -D ~/.ivory-5/data -l ~/.ivory-5/data/lvory_logfile.txt start
ps -ef | grep postgre
```

默认监听端口为5432，继承postgreSQL。也监听1521，为oracle默认端口
### 改密码
```sh
psql -U $(whoami) -d postgres
```
随后输入: \password
再输入两次密码即可，建议1234

### 禁止无密码登录
vim ~/.ivory-5/data/pg_hba.conf

这3行找到，trust都改成scram-sha-256
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust

重启: 

pg_ctl -D ~/.ivory-5/data restart
