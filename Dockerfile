# pull official base image
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu20.04
LABEL maintainer="Coert van Gemeren <coert.vangemeren@hu.nl>"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y \
    && apt install -y --no-install-recommends sudo curl wget nano \
    software-properties-common apt-utils && \
    add-apt-repository -y ppa:graphics-drivers/ppa

RUN groupadd -r spyne \
    && useradd --no-log-init -r -g spyne -ms /bin/bash spyne
RUN usermod -aG sudo spyne && echo "spyne ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# set environment varibles
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV CLOUDSDK_PYTHON=python3

# set work directory
WORKDIR /root

RUN add-apt-repository -y ppa:deadsnakes/ppa && \
    apt update && apt upgrade -y && \
    apt install -y --no-install-recommends python3 ipython3 \
    python2-minimal python2.7 python2.7-dev \
    python3.10 python3.10-dev python3-apt python3.10-distutils python3.10-venv \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.10 10 \
    && update-alternatives --install /usr/bin/python2 python2 /usr/bin/python2.7 2 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 8 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 10 \
    && update-alternatives --set python3 /usr/bin/python3.8 \
    && apt update -y && apt install -y --no-install-recommends \
    gnupg autoconf bash-completion build-essential caca-utils flite1-dev gcc gfortran \
    git ladspa-sdk lame libasound2-dev libatlas-base-dev libavcodec-dev libavformat-dev \
    libbluray-dev libbs2b-dev libc6 libc6-dev libcaca-dev libcdio-cdda-dev libcdio-dev \
    libcdio-paranoia-dev libcodec2-dev libegl1-mesa-dev libfdkaac-ocaml-dev \
    libflite1 libgles2-mesa-dev libglew-dev libgme-dev libgnutls28-dev libgsm1-dev libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev libgtk-3-dev libibus-1.0-dev libjack-jackd2-dev libjpeg-dev liblilv-dev \
    libmp3lame-ocaml-dev libmysofa-dev libnuma1 libnuma-dev libopenal-dev libhdf5-dev \
    libopenexr-dev libopenmpt-dev libpng-dev libqt5svg5-dev librubberband-dev libsamplerate-ocaml-dev \
    libshine-dev libshine-ocaml-dev libsndfile1-dev libsndio-dev libsoxr-dev libspeex-dev \
    libssh-dev libswscale-dev libtbb2 libtbb-dev libtiff-dev libtool libtwolame-dev libunistring-dev libv4l-dev \
    libwavpack-dev libwebp-dev libxml2-dev libxvidcore-dev \
    libzmq3-dev libzvbi-dev lv2-dev opencl-headers openexr pkg-config qttools5-dev qttools5-dev-tools \
    screen unzip wget yasm libeigen3-dev liblapack-dev cmake libopencv-dev htop \
    apt-transport-https ca-certificates \
    cuda-libraries-11-8 cuda-tools-11-8 cuda-toolkit-11-8 \
    libmp3lame-dev libfdk-aac-dev libopus-dev libflac-dev libx264-dev libx265-dev libvpx-dev libass-dev libvorbis-dev \
    automake git-core libfreetype6-dev meson ninja-build texinfo zlib1g-dev nasm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/repo \
    && cd /root/repo \
    && wget https://storage.googleapis.com/docker_resources/cupti-linux-2019.1.1.1.tar.gz \
    && tar -xvzf cupti-linux-2019.1.1.1.tar.gz \
    && rm cupti-linux-2019.1.1.1.tar.gz \
    && find "cupti-linux-2019.1.1.1/include/" -type f -exec cp -P {} /usr/local/cuda/include/ \; \
    && find "cupti-linux-2019.1.1.1/lib64/" -type f -exec cp -P {} /usr/local/cuda/lib64/ \; \
    && find -L "cupti-linux-2019.1.1.1/lib64/" -xtype l -exec cp -P {} /usr/local/cuda/lib64/ \; \
    && cd /usr/local/cuda/lib64 \
    && find -type f -name "libcupti*10.1.59" -exec sh -c 'ln -sf "$(basename "{}")" "$(basename "{}" .10.1.59)".10.1' \; \
    && find -name "libcupti*10.1" -exec sh -c 'ln -sf "$(basename "{}")" "$(basename "{}" .10.1)"' \; \
    && cd - \
    && cp cupti-linux-2019.1.1.1/lib64/libnvperf* /usr/local/cuda/lib64 \
    && chmod a+r /usr/local/cuda/include/*.h /usr/local/cuda/lib64/libcupti* /usr/local/cuda/lib64/libnvperf* \
    && rm -rf /root/repo/cupti-linux-2019.1.1.1

RUN cd /root/repo \
    && wget https://storage.googleapis.com/docker_resources/cudnn-linux-x86_64-8.9.5.29_cuda11-archive.tar.xz \
    && tar -xvxf cudnn-linux-x86_64-8.9.5.29_cuda11-archive.tar.xz \
    && rm cudnn-linux-x86_64-8.9.5.29_cuda11-archive.tar.xz \
    && find "cudnn-linux-x86_64-8.9.5.29_cuda11-archive/include/" -type f -exec cp -P {} /usr/local/cuda/include/ \; \
    && find "cudnn-linux-x86_64-8.9.5.29_cuda11-archive/lib/" -type f -exec cp -P {} /usr/local/cuda/lib64/ \; \
    && find -L "cudnn-linux-x86_64-8.9.5.29_cuda11-archive/lib/" -xtype l -exec cp -P {} /usr/local/cuda/lib64/ \; \
    && cd - \
    && chmod a+r /usr/local/cuda/include/*.h /usr/local/cuda/lib64/libcudnn* \
    && rm -rf /root/repo/cudnn-linux-x86_64-8.9.5.29_cuda11-archive

RUN cd /root/repo \
    && wget https://storage.googleapis.com/docker_resources/TensorRT-8.6.1.6.Linux.x86_64-gnu.cuda-11.8.tar.gz \
    && tar -xvxf TensorRT-8.6.1.6.Linux.x86_64-gnu.cuda-11.8.tar.gz \
    && rm TensorRT-8.6.1.6.Linux.x86_64-gnu.cuda-11.8.tar.gz \
    && find "TensorRT-8.6.1.6/include/" -type f -exec cp -P {} /usr/local/cuda/include/ \; \
    && find "TensorRT-8.6.1.6/lib/" -type f -exec cp -P {} /usr/local/cuda/lib64/ \; \
    && find -L "TensorRT-8.6.1.6/lib/" -xtype l -exec cp -P {} /usr/local/cuda/lib64/ \; \
    && find "TensorRT-8.6.1.6/bin/" -type f -exec cp -P {} /usr/local/cuda/bin/ \; \
    && cd - \
    && chmod a+r /usr/local/cuda/include/*.h /usr/local/cuda/lib64/* \
    && rm -rf /root/repo/TensorRT-8.6.1.6

RUN lsb_release_codename=$(lsb_release -c -s) && export RELEASE="$lsb_release_codename"
ENV GCSFUSE_REPO="gcsfuse-$RELEASE"
RUN lsb_release_codename=$(lsb_release -c -s) && export GCSFUSE_REPO="gcsfuse-$lsb_release_codename" \
    && echo "deb https://packages.cloud.google.com/apt ${GCSFUSE_REPO} main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] http://packages.cloud.google.com/apt cloud-sdk main" \
    | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | tee /usr/share/keyrings/cloud.google.asc \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C0BA5CE6DC6315A3 \
    && apt-get update -y && apt-get install -y --no-install-recommends google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin gcsfuse

WORKDIR /usr/src/app

ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib64:$LD_LIBRARY_PATH
RUN cd /root/repo \
    && wget https://storage.googleapis.com/docker_resources/Video_Codec_SDK_12.1.14.zip \
    && unzip Video_Codec_SDK_12.1.14.zip \
    && rm Video_Codec_SDK_12.1.14.zip \
    && cp /root/repo/Video_Codec_SDK_*/Interface/* /usr/local/include/ \
    && git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git \
    && cd nv-codec-headers \
    && make && make install \
    && cd - \
    && rm -rf nv-codec-headers

RUN git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg_src \
    && cd ffmpeg_src \
    && PATH="/usr/local/cuda/bin:$HOME/bin:$PATH" \
    ./configure \
    --pkg-config-flags="--static" \
    --extra-cflags=-I/usr/local/cuda/include \
    --extra-ldflags=-L/usr/local/cuda/lib64 \
    --extra-libs="-lpthread -lm" \
    --ld="g++" \
    --enable-cuda-nvcc --enable-cuvid --enable-nvdec --enable-nvenc --enable-libnpp \
    --enable-gpl --enable-gnutls --enable-libfreetype \
    --enable-libass --enable-libfdk-aac --enable-libmp3lame --enable-libopus \
    --enable-libvorbis --enable-libvpx \
    --enable-libx264 --enable-libx265 \
    --enable-nonfree --disable-static --enable-shared --enable-optimizations \
    > configure.log 2>&1 || (cat configure.log && exit 1) \
    && make -j$(nproc) && make install \
    && cd - \
    && rm -rf Video_Codec_SDK_12.1.14 \
    && rm -rf ffmpeg_src

ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt /usr/src/app/requirements.txt
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10 \
    && python3.10 -m venv /opt/venv \
    && pip3 install --no-cache-dir -r /usr/src/app/requirements.txt \
    && pip3 install --ignore-installed --no-cache-dir -U crcmod

COPY entrypoint.sh /usr/src/app/entrypoint.sh
RUN chmod +x /usr/src/app/entrypoint.sh
RUN chown -R spyne:spyne /usr/src/app

USER spyne

ENV LOGO="\\\\e[1m\\\\033[38;2;255;255;228m-------- \\\\e[0m\\\\033[38;2;174;2;0m.d888888P d88888888b. Y888\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0md88P 888b\\\\e[1m\\\\033[38;2;255;255;228m--- \\\\e[0m\\\\033[38;2;174;2;0m888 d88888888888 \\\\n\\\\e[1m\\\\033[38;2;255;255;228m------ \\\\e[0m\\\\033[38;2;174;2;0md88P\\\\e[1m\\\\033[38;2;255;255;228m- \\\\e[0m\\\\033[38;2;174;2;0mY88P A8888888888b Y888bd88P\\\\e[1m\\\\033[38;2;255;255;228m- \\\\e[0m\\\\033[38;2;174;2;0m8888b\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0m888 A88888888888 \\\\n\\\\n\\\\e[1m\\\\033[38;2;255;255;228m----- \\\\e[0m\\\\033[38;2;174;2;0m\\\"Y888b.\\\\e[1m\\\\033[38;2;255;255;228m---- \\\\e[0m\\\\033[38;2;174;2;0m888888888P\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0m8888P\\\\e[1m\\\\033[38;2;255;255;228m--- \\\\e[0m\\\\033[38;2;174;2;0m888Y88b \\\\e[0m\\\\033[38;2;174;2;0m888\\\\e[1m\\\\033[38;2;255;255;228m- \\\\e[0m\\\\033[38;2;174;2;0m888888 \\\\n\\\\e[1m\\\\033[38;2;255;255;228m------ \\\\e[0m\\\\033[38;2;174;2;0m\\\"Y888b.\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0m8888888P\\\"\\\\e[1m\\\\033[38;2;255;255;228m--- \\\\e[0m\\\\033[38;2;174;2;0m8888\\\\e[1m\\\\033[38;2;255;255;228m---- \\\\e[0m\\\\033[38;2;174;2;0m888 Y88b888 \\\\e[1m\\\\033[38;2;255;255;228m- \\\\e[0m\\\\033[38;2;174;2;0m888888 \\\\n\\\\e[1m\\\\033[38;2;255;255;228m------- \\\\e[0m\\\\033[38;2;174;2;0md8888\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0m888\\\\e[1m\\\\033[38;2;255;255;228m--------- \\\\e[0m\\\\033[38;2;174;2;0m8888\\\\e[1m\\\\033[38;2;255;255;228m---- \\\\e[0m\\\\033[38;2;174;2;0m888\\\\e[1m\\\\033[38;2;255;255;228m- \\\\e[0m\\\\033[38;2;174;2;0mY88888\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0m888 \\\\n\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0m88888888P\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0m888\\\\e[1m\\\\033[38;2;255;255;228m--------- \\\\e[0m\\\\033[38;2;174;2;0m8888\\\\e[1m\\\\033[38;2;255;255;228m---- \\\\e[0m\\\\033[38;2;174;2;0m888\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0mY8888 \\\\e[1m\\\\033[38;2;255;255;228m- \\\\e[0m\\\\033[38;2;174;2;0m8888888888 \\\\n\\\\e[1m\\\\033[38;2;255;255;228m- \\\\e[0m\\\\033[38;2;174;2;0m8Y8888P\\\"\\\\e[1m\\\\033[38;2;255;255;228m--- \\\\e[0m\\\\033[38;2;174;2;0m888\\\\e[1m\\\\033[38;2;255;255;228m--------- \\\\e[0m\\\\033[38;2;174;2;0m8888\\\\e[1m\\\\033[38;2;255;255;228m---- \\\\e[0m\\\\033[38;2;174;2;0m888\\\\e[1m\\\\033[38;2;255;255;228m--- \\\\e[0m\\\\033[38;2;174;2;0mY888\\\\e[1m\\\\033[38;2;255;255;228m-- \\\\e[0m\\\\033[38;2;174;2;0m888888888\\e[1m\\033[38;2;12;255;12mv4-GPU \\\\n"

RUN echo "echo -e \"${LOGO}\"\n$(cat /home/spyne/.bashrc)" > /home/spyne/.bashrc \
    && sed -i "s/\#force_color_prompt=yes/force_color_prompt=yes/g" /home/spyne/.bashrc \
    && echo "export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/cuda/lib64:${LD_LIBRARY_PATH}" /home/spyne/.bashrc

ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
