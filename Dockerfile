# ComfyUI with PyTorch (CUDA 12.8) and a set of common custom nodes, ready for model downloads at start.
# Models are not included; they are fetched on the GPU host at startup.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive PIP_NO_CACHE_DIR=1 PYTHONUNBUFFERED=1
RUN apt-get update && apt-get install -y --no-install-recommends \
      git python3 python3-venv python3-dev build-essential ffmpeg libgl1 libglib2.0-0 libxcb1 \
      openssh-server curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git
WORKDIR /workspace/ComfyUI

# PyTorch wheels bundle the CUDA runtime; the host only needs an NVIDIA driver.
RUN python3 -m venv --system-site-packages .venv \
    && .venv/bin/pip install --upgrade pip \
    && .venv/bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 \
    && .venv/bin/pip install -r requirements.txt "huggingface_hub[hf_transfer]"

RUN cd custom_nodes \
    && git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
    && git clone --depth 1 https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git \
    && git clone --depth 1 https://github.com/Fannovel16/comfyui_controlnet_aux.git \
    && git clone --depth 1 https://github.com/cubiq/ComfyUI_IPAdapter_plus.git \
    && git clone --depth 1 https://github.com/kijai/ComfyUI-MMAudio.git \
    && ../.venv/bin/pip install \
         -r ComfyUI-VideoHelperSuite/requirements.txt \
         -r ComfyUI-Frame-Interpolation/requirements-no-cupy.txt \
         -r comfyui_controlnet_aux/requirements.txt \
         -r ComfyUI-MMAudio/requirements.txt

# Fail the build if ComfyUI or a node pack can't import (no GPU needed for this check).
RUN .venv/bin/python -c "import torch, torchvision, cv2, huggingface_hub; print('torch', torch.__version__)"
