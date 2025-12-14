# 合并safetensors
## 下载llama.cpp

```bash
git clone --depth 1 https://github.com/ggml-org/llama.cpp llama_cpp
cd llama_cpp
```
## 准备虚拟环境
他自带的pyproject不是适配uv的，把他移除
```bash
mv pyproject.toml pyproject.toml.bak
uv init
```

- 这是我处理好的pyproject.toml,可以直接覆盖
```toml
[project]
name = "llama-cpp"
version = "0.1.0"
description = "Add your description here"
readme = "README.md"
requires-python = ">=3.13"
dependencies = [
    "transformers>=4.57.3",
    "torch>=2.9.1",
    "torchvision>=0.24.1",
]

# 添加这个部分来配置额外的包索引
[[tool.uv.index]]
name = "pytorch-cu130"
url = "https://download.pytorch.org/whl/cu130"
```
- 随后，执行uv sync

## 开始转化

```bash
uv run convert_hf_to_gguf.py "$HOME/桌面/project/download_model_scope/ZhipuAI/AutoGLM-Phone-9B" --outtype f16 --outfile "$HOME/桌面/project/download_model_scope/ZhipuAI/zp.gguf"
```
这会把"$HOME/桌面/project/download_model_scope/ZhipuAI/AutoGLM-Phone-9B" 目录下全部*safetensors合并为一份zp.gguf
这个命令是将智谱AI的AutoGLM-Phone-9B模型从Hugging Face格式转换为GGUF格式，并指定输出精度为f16，输出文件名为zp.gguf。
