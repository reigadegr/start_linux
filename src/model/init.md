# Linux下玩大模型

## 工具准备
需要安装uv，可以去这里下载uv,本人自己写的高性能构建系统，开了各种优化

```txt
https://github.com/reigadegr/uv_action/actions
```

## 获取Zhipu 9B模型

- 创建环境:

```bash
uv init download_zhipu_model
cd download_zhipu_model
uv add modelscope
```

- 编写python代码以便下载（直接复制到main.py就ok）

```python
from modelscope import snapshot_download
def main():
    snapshot_download('ZhipuAI/AutoGLM-Phone-9B', cache_dir='./')

if __name__ == "__main__":
    main()
```
这个大概18G,等吧。操作会把 https://modelscope.cn/models/ZhipuAI/AutoGLM-Phone-9B 全部文件下载
下载完毕后，记得校验sha256
```bash
sha256sum *safetensors
```
