# CaseReplay Remotion + ffmpeg render image for GPU pods (ep08: graphics with render.mjs, edit with build.py).
# Everything a render needs is baked in, so a pod never runs apt, pip, npm or a browser download at boot (FEILREGISTER D14).
# No secrets, no project code, no media: Node, Remotion's npm packages (from ep08/graphics/package-lock.json), Chrome Headless
# Shell, ffmpeg 8.1.3 static (BtbN, GPL, NVENC), Python packages for build.py, runpodctl and croc.
FROM nvidia/cuda:12.8.1-base-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    NVIDIA_DRIVER_CAPABILITIES=all \
    NVIDIA_VISIBLE_DEVICES=all \
    LANG=C.UTF-8 \
    PATH=/opt/node/bin:/opt/cr/venv/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

# Chrome Headless Shell libraries (Remotion's Linux list for Ubuntu 24.04), GL/EGL/glvnd for --gl=angle-egl, fonts, python
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl xz-utils procps rsync python3 python3-venv libsndfile1 \
      libnss3 libdbus-1-3 libatk1.0-0t64 libatk-bridge2.0-0t64 libgbm1 libasound2t64 libxrandr2 libxkbcommon0 libxfixes3 \
      libxcomposite1 libxdamage1 libpango-1.0-0 libcairo2 libcups2t64 libdrm2 libxshmfence1 libx11-6 libx11-xcb1 libxext6 \
      libxcb1 libexpat1 libglib2.0-0t64 libnspr4 \
      libglvnd0 libegl1 libgl1 libgles2 libopengl0 libvulkan1 \
      fonts-dejavu-core fonts-liberation fonts-noto-color-emoji \
 && rm -rf /var/lib/apt/lists/*

# NVIDIA glvnd/Vulkan vendor files: the container toolkit does not inject them in legacy mode (nvidia-container-toolkit #2128)
RUN mkdir -p /usr/share/glvnd/egl_vendor.d /usr/share/vulkan/icd.d /etc/vulkan/icd.d \
 && printf '{"file_format_version":"1.0.0","ICD":{"library_path":"libEGL_nvidia.so.0"}}\n' > /usr/share/glvnd/egl_vendor.d/10_nvidia.json \
 && printf '{"file_format_version":"1.0.0","ICD":{"library_path":"libGLX_nvidia.so.0","api_version":"1.3.0"}}\n' > /usr/share/vulkan/icd.d/nvidia_icd.json \
 && cp /usr/share/vulkan/icd.d/nvidia_icd.json /etc/vulkan/icd.d/nvidia_icd.json

# ffmpeg/ffprobe 8.1.3, static GPL build with libx264, prores_ks, h264_nvenc/hevc_nvenc. Not 9.0 (the Mac has 9.0.2): BtbN builds
# 9.x against nv-codec-headers 13.1, and RunPod hosts run driver 580, which refused it ("Driver does not support the required
# nvenc API version", 4090 and 5090 pods 18.10). BtbN builds <= 8.1 with the sdk/13.0 headers, which driver 570+ supports.
ARG FF_URL=https://github.com/BtbN/FFmpeg-Builds/releases/download/autobuild-2026-09-30-13-08/ffmpeg-n8.1.3-9-g29e619e767-linux64-gpl-8.1.tar.xz
ARG FF_SHA=97ce978979194b5cf7e06a5e68020dbdaa7a4f3294c5452b6a1bc347100dbb79
RUN curl -fsSL --retry 3 -o /tmp/ff.tar.xz "$FF_URL" && echo "$FF_SHA  /tmp/ff.tar.xz" | sha256sum -c - \
 && tar xJf /tmp/ff.tar.xz -C /tmp && cp /tmp/ffmpeg-*/bin/ffmpeg /tmp/ffmpeg-*/bin/ffprobe /usr/local/bin/ && rm -rf /tmp/ff* \
 && ffmpeg -hide_banner -encoders | grep -E "libx264|prores_ks|h264_nvenc|hevc_nvenc"

# Node 24 LTS
ARG NODE_V=v24.21.0
ARG NODE_SHA=fd8e59d5a511510f6a298afb548f18c7d2b1be404d8b4a27d94fbe49f56cb2d6
RUN curl -fsSL --retry 3 -o /tmp/node.tar.xz "https://nodejs.org/dist/$NODE_V/node-$NODE_V-linux-x64.tar.xz" \
 && echo "$NODE_SHA  /tmp/node.tar.xz" | sha256sum -c - \
 && mkdir -p /opt/node && tar xJf /tmp/node.tar.xz -C /opt/node --strip-components=1 && rm /tmp/node.tar.xz && node --version

# Remotion: exactly ep08/graphics/package-lock.json, plus Chrome Headless Shell inside node_modules/.remotion.
# On the pod: <graphics>/node_modules -> /opt/remotion/node_modules (pod_job.sh checks the lockfile hash first).
COPY remotion/package.json remotion/package-lock.json /opt/remotion/
RUN cd /opt/remotion && npm ci --no-audit --no-fund --loglevel=error \
 && npx remotion browser ensure \
 && ls -d node_modules/.remotion/chrome-headless-shell/*/* \
 && sha256sum package-lock.json | cut -d' ' -f1 > /opt/remotion/LOCK_SHA256

# Python for build.py (uv export of its inline script dependencies, hashes checked)
COPY requirements.txt /opt/cr/requirements.txt
RUN python3 -m venv /opt/cr/venv && /opt/cr/venv/bin/pip install --no-cache-dir -q --upgrade pip \
 && /opt/cr/venv/bin/pip install --no-cache-dir -q -r /opt/cr/requirements.txt \
 && /opt/cr/venv/bin/python -c "import numpy, scipy, cv2, soundfile, pyloudnorm, soxr, mido, matplotlib, PIL; print('PY_OK', numpy.__version__, cv2.__version__)"

# runpodctl 3.0.1 and croc 11.5.4, pinned by sha256 (same as the cr-blender image)
ARG RPC_SHA=b66d11eca8cacbf18a2de6943c6e18a79ffbdc8a3c30aa13a49dc6cfc15d4239
ARG CROC_SHA=577f2c4170fac3f8ab244e325cdeea5644788e1cd7620f592a5d365ee349d556
RUN curl -fsSL --retry 3 -o /usr/local/bin/runpodctl https://github.com/runpod/runpodctl/releases/download/v3.0.1/runpodctl-linux-amd64 \
 && echo "$RPC_SHA  /usr/local/bin/runpodctl" | sha256sum -c - && chmod +x /usr/local/bin/runpodctl \
 && curl -fsSL --retry 3 -o /tmp/croc.tgz https://github.com/schollz/croc/releases/download/v11.5.4/croc_v11.5.4_Linux-64bit.tar.gz \
 && echo "$CROC_SHA  /tmp/croc.tgz" | sha256sum -c - && tar xzf /tmp/croc.tgz -C /usr/local/bin croc && rm /tmp/croc.tgz \
 && runpodctl --version && croc --version

# smoke test (CI and pod): node /opt/cr/smoke/smoke.mjs <out> [swangle|angle-egl|vulkan]
COPY smoke/ /opt/cr/smoke/
RUN ln -s /opt/remotion/node_modules /opt/cr/smoke/node_modules

ARG TAG=4.0.528-2
RUN printf '{"image":"cr-remotion","tag":"%s","remotion":"4.0.528","node":"%s","ffmpeg":"8.1.3 BtbN autobuild-2026-09-30","lock_sha256":"%s","runpodctl":"3.0.1","croc":"11.5.4"}\n' \
      "$TAG" "$NODE_V" "$(cat /opt/remotion/LOCK_SHA256)" > /opt/cr/image.json && cat /opt/cr/image.json

LABEL org.opencontainers.image.title="cr-remotion" \
      org.opencontainers.image.description="Remotion 4.0.528 + Chrome Headless Shell, Node 24, ffmpeg 8.1.3 (NVENC), Python for build.py, runpodctl, croc"

WORKDIR /workspace
CMD ["sleep", "infinity"]
