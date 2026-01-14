## 安装GreatSQL

# 1. 解压到 /opt

[ ! -d /opt ] && sudo mkdir -p /opt

cd /opt

wget "https://product.greatdb.com/GreatSQL-8.4.4-4/GreatSQL-8.4.4-4-Linux-glibc2.28-x86_64-minimal.tar.xz"
 
tar xf GreatSQL-8.4.4-4-Linux-glibc2.28-x86_64-minimal.tar.xz

sudo rm -rf ./greatsql/
sudo mv ./GreatSQL-8.4.4-4-Linux-glibc2.28-x86_64-minimal/ ./greatsql/

# 3. 安装依赖（Ubuntu/Debian）
sudo apt update; sudo apt install -y numactl openssl libjemalloc2 libaio-dev

# 4. 创建数据目录
sudo rm -rf ~/.greatsql
mkdir -p ~/.greatsql/{data,log,tmp}

# 5. 创建极简配置（5行搞定）
echo -e "[mysqld]\nbasedir=/opt/greatsql\ndatadir=/home/reigadegr/.greatsql/data\nsocket=/tmp/mysql.sock\nport=3306\n\n[client]\nsocket=/tmp/mysql.sock\nport=3306" | sudo tee /etc/my.cnf


# 6. 初始化数据库（无密码）
> 小插曲，解决so不存在: 
> sudo cp -af /usr/lib/x86_64-linux-gnu/libaio.so /usr/lib/x86_64-linux-gnu/libaio.so.1

/opt/greatsql/bin/mysqld --initialize-insecure --user=root

# 7. 启动服务
/opt/greatsql/bin/mysqld_safe --defaults-file=/etc/my.cnf &

# 8. 验证启动
sleep 3 && ps aux | grep mysqld | grep -v grep

# 9. 配置环境变量
echo 'export PATH=/opt/greatsql/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 10. 登录测试（无密码）
mysql -u root

## 11. 改密码

ALTER USER 'root'@'localhost' IDENTIFIED BY '1234';

FLUSH PRIVILEGES;

# 12.开机自启
echo "[Unit]
Description=GreatSQL Server
After=network.target

[Service]
User=reigadegr
ExecStart=/opt/greatsql/bin/mysqld_safe --defaults-file=/etc/my.cnf
Restart=always

[Install]
WantedBy=multi-user.target
" | sudo tee /etc/systemd/system/greatsql.service

sudo systemctl daemon-reload
sudo systemctl enable greatsql --now
