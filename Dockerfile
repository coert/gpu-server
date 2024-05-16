FROM nvidia/cuda:12.4.1-devel-ubuntu22.04 as module
LABEL maintainer="coert.vangemeren@hu.nl"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y && apt install -y --no-install-recommends \
    software-properties-common apt-utils sudo unzip xz-utils screen \
    curl wget bash-completion cmake build-essential git htop nano \
    ffmpeg libopencv-dev \
    && apt clean && rm -rf /var/lib/apt/lists/*

RUN groupadd -r spyne \
    && useradd --no-log-init -r -g spyne -ms /bin/bash spyne
RUN usermod -aG sudo spyne && echo "spyne ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# set environment varibles
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV CLOUDSDK_PYTHON=/usr/bin/python3
ENV GCSFUSE_VERSION=1.2.1
ENV LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:/usr/local/lib:/usr/local/cuda/lib64:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}"
ENV PYTHONPATH="/usr/src/app:/usr/local/lib/python3.11/site-packages:${PYTHONPATH}"
ENV PATH="/usr/local/cuda/bin:/usr/local/nvidia/bin:${PATH}"

# set work directory
WORKDIR /root

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
    | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add -\
    && curl -LJO "https://github.com/GoogleCloudPlatform/gcsfuse/releases/download/v${GCSFUSE_VERSION}/gcsfuse_${GCSFUSE_VERSION}_amd64.deb"

# Install system dependencies
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt update && apt upgrade -y && \
    apt install -y --no-install-recommends python3-minimal ipython3 python3-setuptools \
    python3-dev python3.11 python3.11-dev python3-pip \
    google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin fuse \
    && dpkg -i "gcsfuse_${GCSFUSE_VERSION}_amd64.deb" \
    && rm "gcsfuse_${GCSFUSE_VERSION}_amd64.deb" \
    && apt clean && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 10 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 10 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 11

# # Install Python dependencies
# COPY requirements.txt /usr/src/app/requirements.txt
# RUN pip3 install -U pip && pip3 install --no-cache-dir -r /usr/src/app/requirements.txt
# RUN output=$(gsutil version -l |grep crcmod); if [[ $output != "compiled crcmod: True" ]]; then exit 1; fi

# # Install CUDA Profiling Tools Interface (CUPTI)
# ENV CUPTI_VER=2019.1.1.1
# COPY repo/cupti-linux-2019.1.1.1.tar.gz /root/repo/cupti.tar.gz
# RUN ls -1 /root/repo/cupti.tar.gz && tar -xvf /root/repo/cupti.tar.gz \
#     && rm /root/repo/cupti.tar.gz \
#     && cp -r cupti-linux-${CUPTI_VER}/include/* /usr/local/cuda/include \
#     && cp cupti-linux-${CUPTI_VER}/lib64/libcupti*10.1.59 /usr/local/cuda/lib64 \
#     && cd /usr/local/cuda/lib64 \
#     && find -type f -name "libcupti*10.1.59" -exec sh -c 'ln -sf "$(basename "{}")" "$(basename "{}" .10.1.59)".10.1' \; \
#     && find -name "libcupti*10.1" -exec sh -c 'ln -sf "$(basename "{}")" "$(basename "{}" .10.1)"' \; \
#     && cd - \
#     && cp cupti-linux-${CUPTI_VER}/lib64/libnvperf* /usr/local/cuda/lib64 \
#     && chmod a+r /usr/local/cuda/include/*.h /usr/local/cuda/lib64/libcupti* /usr/local/cuda/lib64/libnvperf* \
#     && rm -rf cupti-linux-${CUPTI_VER}

# # Install cuDNN
# ENV CUDNN_VER=8.9.7.29
# COPY repo/cudnn-linux-x86_64-8.9.7.29_cuda12-archive.tar.xz /root/repo/cudnn.tar.xz
# RUN tar -xvf /root/repo/cudnn.tar.xz \
#     && rm /root/repo/cudnn.tar.xz \
#     && find "cudnn-linux-x86_64-${CUDNN_VER}_cuda12-archive/include/" -type f -exec cp -P {} /usr/local/cuda/include/ \; \
#     && find "cudnn-linux-x86_64-${CUDNN_VER}_cuda12-archive/lib/" -type f -exec cp -P {} /usr/local/cuda/lib64/ \; \
#     && find -L "cudnn-linux-x86_64-${CUDNN_VER}_cuda12-archive/lib/" -xtype l -exec cp -P {} /usr/local/cuda/lib64/ \; \
#     && chmod a+r /usr/local/cuda/include/*.h /usr/local/cuda/lib64/libcudnn* \
#     && rm -rf cudnn-linux-x86_64-${CUDNN_VER}_cuda12-archive

# # Install TensorRT
# ENV TRT_VER=8.6.1.6
# COPY repo/TensorRT-8.6.1.6.Linux.x86_64-gnu.cuda-12.0.tar.gz /root/repo/TensorRT.tar.gz
ENV TRT_VER=10.0.0.6
COPY repo/TensorRT-10.0.0.6.Linux.x86_64-gnu.cuda-12.4.tar.gz /root/repo/TensorRT.tar.gz
RUN tar -xvf /root/repo/TensorRT.tar.gz \
    && rm /root/repo/TensorRT.tar.gz \
    && find "TensorRT-${TRT_VER}/include/" -type f -exec cp -P {} /usr/local/cuda/include/ \; \
    && find "TensorRT-${TRT_VER}/lib/" -type f -exec cp -P {} /usr/local/cuda/lib64/ \; \
    && find -L "TensorRT-${TRT_VER}/lib/" -xtype l -exec cp -P {} /usr/local/cuda/lib64/ \; \
    && chmod a+r /usr/local/cuda/include/*.h /usr/local/cuda/lib64/* \
    && rm -rf TensorRT-${TRT_VER} \
    && rm -rf /root/repo

RUN TENSORRT_VERSION=$(python3 -c "import tensorflow.compiler as tf_cc; print('.'.join(map(str, tf_cc.tf2tensorrt._pywrap_py_utils.get_linked_tensorrt_version())))" 2> /dev/null) \
    && TENSORRT_FILE=$(python3 -c "import tensorrt; print(tensorrt.__file__)" 2>/dev/null) \
    && TENSORRT_DIR=$(dirname "$TENSORRT_FILE") \
    && TENSORRT_LIBS_FILE=$(python3 -c "import tensorrt_libs; print(tensorrt_libs.__file__)" 2>/dev/null) \
    && TENSORRT_LIBS_DIR=$(dirname "$TENSORRT_LIBS_FILE") \
    && ln -srf "${TENSORRT_LIBS_DIR}/libnvinfer.so.8" "${TENSORRT_DIR}/libnvinfer.so.${TENSORRT_VERSION}" \
    && ln -srf "${TENSORRT_LIBS_DIR}/libnvinfer_plugin.so.8" "${TENSORRT_DIR}/libnvinfer_plugin.so.${TENSORRT_VERSION}"

# # Build and install FFmpeg prerequisites
# COPY repo/Video_Codec_SDK_12.0.16.zip /root/repo/Video_Codec_SDK.zip
# RUN cd /root/repo \
#     && unzip Video_Codec_SDK.zip \
#     && rm Video_Codec_SDK.zip \
#     && cp /root/repo/Video_Codec_SDK_*/Interface/* /usr/local/include/ \
#     && git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git \
#     && cd nv-codec-headers \
#     && make && make install

# # Build and install FFmpeg
# RUN git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg_src
# RUN cd ffmpeg_src \
#     && ./configure \
#     --pkg-config-flags="--static" \
#     --extra-cflags=-I/usr/local/cuda/include \
#     --extra-ldflags=-L/usr/local/cuda/lib64 \
#     --extra-libs="-lpthread -lm" \
#     --ld="g++" \
#     --enable-cuda-nvcc --enable-cuvid --enable-nvdec --enable-nvenc --enable-libnpp \
#     --enable-gpl --enable-gnutls --enable-libfreetype \
#     --enable-libass --enable-libfdk-aac --enable-libmp3lame --enable-libopus \
#     --enable-libdav1d --enable-libvorbis --enable-libvpx \
#     --enable-libx264 --enable-libx265 \
#     --enable-nonfree --disable-static --enable-shared --enable-optimizations \
#     > configure.log 2>&1 || (cat configure.log && exit 1)
# RUN cd ffmpeg_src \
#     && make -j$(nproc) && make install \
#     && cd - \
#     && rm -rf nv-codec-headers \
#     && rm -rf ffmpeg_src \
#     && rm -rf "Video_Codec_SDK_*"

# Put Workdir at /usr/src/app for the rest of the build
WORKDIR /usr/src/app

RUN chown spyne:spyne /usr/src/app

USER spyne

ENV LOGO="\\\\e[1m\\\\033[38;2;255;255;228m-------- \\\\e[0m\\\\033[38;2;174;2;0m.d888888P d88888888b. Y888\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0md88P 888b\\\\e[1m\\\\033[38;2;255;255;228m--- \\\\e[0m\\\\033[38;2;174;2;0m888 d88888888888 \\\\n\\\\e[1m\\\\033[38;2;255;255;228m------ \\\\e[0m\\\\033[38;2;174;2;0md88P\\\\e[1m\\\\033[38;2;255;255;228m- \\\\e[0m\\\\033[38;2;174;2;0mY88P A8888888888b Y888bd88P\\\\e[1m\\\\033[38;2;255;255;228m- \\\\e[0m\\\\033[38;2;174;2;0m8888b\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0m888 A88888888888 \\\\n\\\\n\\\\e[1m\\\\033[38;2;255;255;228m----- \\\\e[0m\\\\033[38;2;174;2;0m\\\"Y888b.\\\\e[1m\\\\033[38;2;255;255;228m---- \\\\e[0m\\\\033[38;2;174;2;0m888888888P\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0m8888P\\\\e[1m\\\\033[38;2;255;255;228m--- \\\\e[0m\\\\033[38;2;174;2;0m888Y88b \\\\e[0m\\\\033[38;2;174;2;0m888\\\\e[1m\\\\033[38;2;255;255;228m- \\\\e[0m\\\\033[38;2;174;2;0m888888 \\\\n\\\\e[1m\\\\033[38;2;255;255;228m------ \\\\e[0m\\\\033[38;2;174;2;0m\\\"Y888b.\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0m8888888P\\\"\\\\e[1m\\\\033[38;2;255;255;228m--- \\\\e[0m\\\\033[38;2;174;2;0m8888\\\\e[1m\\\\033[38;2;255;255;228m---- \\\\e[0m\\\\033[38;2;174;2;0m888 Y88b888 \\\\e[1m\\\\033[38;2;255;255;228m- \\\\e[0m\\\\033[38;2;174;2;0m888888 \\\\n\\\\e[1m\\\\033[38;2;255;255;228m------- \\\\e[0m\\\\033[38;2;174;2;0md8888\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0m888\\\\e[1m\\\\033[38;2;255;255;228m--------- \\\\e[0m\\\\033[38;2;174;2;0m8888\\\\e[1m\\\\033[38;2;255;255;228m---- \\\\e[0m\\\\033[38;2;174;2;0m888\\\\e[1m\\\\033[38;2;255;255;228m- \\\\e[0m\\\\033[38;2;174;2;0mY88888\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0m888 \\\\n\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0m88888888P\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0m888\\\\e[1m\\\\033[38;2;255;255;228m--------- \\\\e[0m\\\\033[38;2;174;2;0m8888\\\\e[1m\\\\033[38;2;255;255;228m---- \\\\e[0m\\\\033[38;2;174;2;0m888\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0mY8888 \\\\e[1m\\\\033[38;2;255;255;228m- \\\\e[0m\\\\033[38;2;174;2;0m8888888888 \\\\n\\\\e[1m\\\\033[38;2;255;255;228m- \\\\e[0m\\\\033[38;2;174;2;0m8Y8888P\\\"\\\\e[1m\\\\033[38;2;255;255;228m--- \\\\e[0m\\\\033[38;2;174;2;0m888\\\\e[1m\\\\033[38;2;255;255;228m--------- \\\\e[0m\\\\033[38;2;174;2;0m8888\\\\e[1m\\\\033[38;2;255;255;228m---- \\\\e[0m\\\\033[38;2;174;2;0m888\\\\e[1m\\\\033[38;2;255;255;228m--- \\\\e[0m\\\\033[38;2;174;2;0mY888\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0m888888888\\e[1m\\033[38;2;12;255;12mGPU \\\\n"

RUN echo "echo -e \"${LOGO}\"\n$(cat /home/spyne/.bashrc)" > /home/spyne/.bashrc \
    && sed -i "s/\#force_color_prompt=yes/force_color_prompt=yes/g" /home/spyne/.bashrc

ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
