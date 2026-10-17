# Headless Blender 5.2.2 (EEVEE on NVIDIA through EGL) for GPU pods.
# No secrets, no project code, no media: Blender (GPL), open libraries, D-DIN (SIL OFL), runpodctl and croc.
FROM nvidia/cuda:12.8.1-base-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    NVIDIA_DRIVER_CAPABILITIES=all \
    NVIDIA_VISIBLE_DEVICES=all \
    LANG=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl xz-utils rsync procps ffmpeg python3 python3-numpy python3-pil \
      fonts-dejavu-core fonts-dejavu-extra fonts-liberation \
      libglvnd0 libegl1 libgl1 libglx0 libopengl0 libgles2 libvulkan1 vulkan-tools mesa-utils \
      libx11-6 libxi6 libxxf86vm1 libxfixes3 libxrender1 libxext6 libxkbcommon0 libxkbcommon-x11-0 \
      libsm6 libice6 libwayland-client0 libwayland-cursor0 libwayland-egl1 libdecor-0-0 \
      libdbus-1-3 libxcursor1 libxinerama1 libxrandr2 libgomp1 libxshmfence1 \
 && rm -rf /var/lib/apt/lists/*

# NVIDIA glvnd/Vulkan vendor files: the container toolkit does not inject them in legacy mode (nvidia-container-toolkit #2128)
RUN mkdir -p /usr/share/glvnd/egl_vendor.d /usr/share/vulkan/icd.d /etc/vulkan/icd.d \
 && printf '{"file_format_version":"1.0.0","ICD":{"library_path":"libEGL_nvidia.so.0"}}\n' > /usr/share/glvnd/egl_vendor.d/10_nvidia.json \
 && printf '{"file_format_version":"1.0.0","ICD":{"library_path":"libGLX_nvidia.so.0","api_version":"1.3.0"}}\n' > /usr/share/vulkan/icd.d/nvidia_icd.json \
 && cp /usr/share/vulkan/icd.d/nvidia_icd.json /etc/vulkan/icd.d/nvidia_icd.json

# Blender 5.2.2 Linux x64: sha256 and build hash checked
ARG BL_URL=https://download.blender.org/release/Blender5.2/blender-5.2.2-linux-x64.tar.xz
ARG BL_SHA=84098912789dc450e95697c4184fb8a90acbe5111c2ba4aede3fecb57806a168
ARG BL_HASH=d13f752e3b9c
RUN curl -fsSL --retry 3 -o /tmp/b.tar.xz "$BL_URL" \
 && echo "$BL_SHA  /tmp/b.tar.xz" | sha256sum -c - \
 && mkdir -p /opt/blender && tar xf /tmp/b.tar.xz -C /opt/blender --strip-components=1 && rm /tmp/b.tar.xz \
 && /opt/blender/blender --version | tee /dev/stderr | grep -q "$BL_HASH" \
 && /opt/blender/blender -b --factory-startup --python-expr "import bpy, numpy; print('BPY_OK', bpy.app.version_string)" | grep -q BPY_OK

# runpodctl 3.0.1 and croc 11.5.4, pinned by sha256
ARG RPC_SHA=b66d11eca8cacbf18a2de6943c6e18a79ffbdc8a3c30aa13a49dc6cfc15d4239
ARG CROC_SHA=577f2c4170fac3f8ab244e325cdeea5644788e1cd7620f592a5d365ee349d556
RUN curl -fsSL --retry 3 -o /usr/local/bin/runpodctl https://github.com/runpod/runpodctl/releases/download/v3.0.1/runpodctl-linux-amd64 \
 && echo "$RPC_SHA  /usr/local/bin/runpodctl" | sha256sum -c - && chmod +x /usr/local/bin/runpodctl \
 && curl -fsSL --retry 3 -o /tmp/croc.tgz https://github.com/schollz/croc/releases/download/v11.5.4/croc_v11.5.4_Linux-64bit.tar.gz \
 && echo "$CROC_SHA  /tmp/croc.tgz" | sha256sum -c - && tar xzf /tmp/croc.tgz -C /usr/local/bin croc && rm /tmp/croc.tgz \
 && runpodctl --version && croc --version

# D-DIN (SIL OFL 1.1) and the DejaVu stand-ins for the Apple font names 2D/QA tools ask for
COPY fonts/d-din/ /opt/cr/fonts/d-din/
RUN mkdir -p /usr/share/fonts/opentype/d-din /System/Library/Fonts/Supplemental /workspace \
 && cp /opt/cr/fonts/d-din/*.otf /usr/share/fonts/opentype/d-din/ \
 && ln -sf /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf /System/Library/Fonts/Menlo.ttc \
 && ln -sf /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf "/System/Library/Fonts/Avenir Next.ttc" \
 && (cd /opt/cr/fonts/d-din && sha256sum *.otf > SHA256SUMS)

# marker read by the pod setup: everything apt/Blender would install is already here
RUN printf '{"image":"cr-blender","tag":"5.2.2-1","blender":"5.2.2","hash":"%s","runpodctl":"3.0.1","croc":"11.5.4"}\n' "$BL_HASH" > /opt/cr/image.json

LABEL org.opencontainers.image.title="cr-blender" \
      org.opencontainers.image.description="Headless Blender 5.2.2 with NVIDIA EGL/Vulkan vendor files, ffmpeg, numpy, PIL, D-DIN, runpodctl, croc" \
      cr.blender=5.2.2 cr.hash=d13f752e3b9c

WORKDIR /workspace
CMD ["sleep", "infinity"]
