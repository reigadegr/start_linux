# 量化模型
## 环境准备
- 安装cmake等依赖

```bash
sudo apt update
sudo apt install -y cmake clang llvm
```

- 随后进入llama.cpp项目目录
- 可能需要安装一些curl依赖
```bash
sudo apt install -y libcurl4-openssl-dev
```

```bash
mkdir build; cd build
cmake  ..
cmake --build . --config Release -j$(nproc)
```
构建完毕后，目前还在build目录下，那么`bin/llama-quantize`是我们需要的

## 开始量化
```bash
bin/llama-quantize \
$HOME/project/download_model_scope/ZhipuAI/zp.gguf \
$HOME/project/download_model_scope/ZhipuAI/zp_quantize.gguf q4_0
```
