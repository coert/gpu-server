#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

WORKSPACE=/opt/workspace
mkdir -p ${WORKSPACE}
cp ./pyproject.toml ${WORKSPACE}/pyproject.toml
cp ./poetry.lock ${WORKSPACE}/poetry.lock

INSTALL_LOCATION=/opt/nvidia_install
mkdir -p ${INSTALL_LOCATION}
cd ${INSTALL_LOCATION}

apt-get remove --purge nvidia-driver-* -y \
    && apt-get autoremove --purge -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

apt update && apt upgrade -y \
    && apt install -y --no-install-recommends linux-headers-$(uname -r) curl wget nano \
    htop software-properties-common apt-utils git git-core screen unzip

# NVIDIA_DRIVER_VERSION="520.61.05" \
NVIDIA_DRIVER_VERSION="535.54.03" \
    && NVIDIA_DRIVER_INSTALLER="NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}.run" \
    && wget -nv https://us.download.nvidia.com/tesla/${NVIDIA_DRIVER_VERSION}/${NVIDIA_DRIVER_INSTALLER} \
    && chmod +x ${NVIDIA_DRIVER_INSTALLER} \
    && ./${NVIDIA_DRIVER_INSTALLER} --no-questions --ui=none \

# CUDA_VERSION="11.8.0" \
CUDA_VERSION="12.2.0" \
    && cuda_string=$(echo $CUDA_VERSION|sed -e 's/\.//g') \
    && CUDA_INSTALLER="cuda_${CUDA_VERSION}_${NVIDIA_DRIVER_VERSION}_linux.run" \
    && wget -nv https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/local_installers/${CUDA_INSTALLER} \
    && chmod +x ${CUDA_INSTALLER} \
    && "./${CUDA_INSTALLER}" --silent --toolkit --no-drm \
    && update-alternatives --install /usr/local/cuda cuda /usr/local/cuda-${cuda_string} ${cuda_string}

add-apt-repository -y ppa:deadsnakes/ppa && \
    apt update && apt upgrade -y && apt install -y --no-install-recommends python3 ipython3 \
    python3.10 python2-minimal python2.7 python2.7-dev \
    python3-dev python3.10-dev python3-apt python3.10-distutils python3.10-venv \
    && update-alternatives --install /usr/bin/python python /usr/bin/python2.7 210 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.10 310 \
    && update-alternatives --set python /usr/bin/python3.10 \
    && update-alternatives --install /usr/bin/python2 python2 /usr/bin/python2.7 2 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 10 \
    && update-alternatives --set python3 /usr/bin/python3.10 \
    && apt update -y && apt install -y --no-install-recommends \
    gnupg automake autoconf bash-completion build-essential caca-utils flite1-dev gcc gfortran yasm nasm \
    ladspa-sdk lame libasound2-dev libatlas-base-dev libavcodec-dev libavformat-dev \
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
    libeigen3-dev liblapack-dev cmake libopencv-dev \
    apt-transport-https ca-certificates \
    libmp3lame-dev libfdk-aac-dev libopus-dev libflac-dev libx264-dev libx265-dev libvpx-dev libass-dev libvorbis-dev \
    libfreetype6-dev meson ninja-build texinfo zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

CUPTI="cupti-linux-2019.1.1.1" \
    && wget -nv https://storage.googleapis.com/docker_resources/${CUPTI}.tar.gz \
    && tar xvzf ${CUPTI}.tar.gz \
    && rm ${CUPTI}.tar.gz \
    && find "${CUPTI}/include/" -type f -exec cp -P {} /usr/local/cuda/include/ \; \
    && find "${CUPTI}/lib64/" -type f -exec cp -P {} /usr/local/cuda/lib64/ \; \
    && find -L "${CUPTI}/lib64/" -xtype l -exec cp -P {} /usr/local/cuda/lib64/ \; \
    && cd /usr/local/cuda/lib64 \
    && find -type f -name "libcupti*10.1.59" -exec sh -c 'ln -sf "$(basename "{}")" "$(basename "{}" .10.1.59)".10.1' \; \
    && find -name "libcupti*10.1" -exec sh -c 'ln -sf "$(basename "{}")" "$(basename "{}" .10.1)"' \; \
    && cd - \
    && cp ${CUPTI}/lib64/libnvperf* /usr/local/cuda/lib64 \
    && chmod a+r /usr/local/cuda/include/*.h /usr/local/cuda/lib64/libcupti* /usr/local/cuda/lib64/libnvperf* \
    && rm -rf ${CUPTI}

CUDNN="cudnn-linux-x86_64-8.9.5.29_cuda11-archive" \
    && wget -nv https://storage.googleapis.com/docker_resources/${CUDNN}.tar.xz \
    && tar xvf "${CUDNN}.tar.xz" \
    && rm "${CUDNN}.tar.xz" \
    && find "${CUDNN}/include/" -type f -exec cp -P {} /usr/local/cuda/include/ \; \
    && find "${CUDNN}/lib/" -type f -exec cp -P {} /usr/local/cuda/lib64/ \; \
    && find -L "${CUDNN}/lib/" -xtype l -exec cp -P {} /usr/local/cuda/lib64/ \; \
    && chmod a+r /usr/local/cuda/include/*.h /usr/local/cuda/lib64/libcudnn* \
    && rm -rf ${CUDNN}
    
TENSORRT="TensorRT-8.6.1.6" \
    && wget -nv https://storage.googleapis.com/docker_resources/${TENSORRT}.Linux.x86_64-gnu.cuda-11.8.tar.gz \
    && tar xvxf ${TENSORRT}.Linux.x86_64-gnu.cuda-11.8.tar.gz \
    && rm ${TENSORRT}.Linux.x86_64-gnu.cuda-11.8.tar.gz \
    && find "${TENSORRT}/include/" -type f -exec cp -P {} /usr/local/cuda/include/ \; \
    && find "${TENSORRT}/lib/" -type f -exec cp -P {} /usr/local/cuda/lib64/ \; \
    && find -L "${TENSORRT}/lib/" -xtype l -exec cp -P {} /usr/local/cuda/lib64/ \; \
    && find "${TENSORRT}/bin/" -type f -exec cp -P {} /usr/local/cuda/bin/ \; \
    && chmod a+r /usr/local/cuda/include/*.h /usr/local/cuda/lib64/* \
    && rm -rf ${TENSORRT}

VIDEO_CODEC="Video_Codec_SDK_12.1.14" \
    && wget -nv https://storage.googleapis.com/docker_resources/${VIDEO_CODEC}.zip \
    && unzip -o ${VIDEO_CODEC}.zip \
    && rm ${VIDEO_CODEC}.zip \
    && cp Video_Codec_SDK_*/Interface/* /usr/local/include/ \
    && rm -rf ${VIDEO_CODEC}

git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git \
    && cd nv-codec-headers \
    && make && make install \
    && cd - \
    && rm -rf nv-codec-headers

crontab -l | { cat; echo "@reboot /usr/bin/nvidia-persistenced --verbose"; } | crontab -

lsb_release_codename=$(lsb_release -c -s) && GCSFUSE_REPO="gcsfuse-$lsb_release_codename" \
    && echo "deb https://packages.cloud.google.com/apt ${GCSFUSE_REPO} main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] http://packages.cloud.google.com/apt cloud-sdk main" \
    | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | tee /usr/share/keyrings/cloud.google.asc \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C0BA5CE6DC6315A3 \
    && apt-get update -y && apt-get install -y --no-install-recommends google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin gcsfuse

export PATH="/usr/local/cuda/bin:${HOME}/bin:${HOME}/.local/bin:${PATH}"

git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg_src \
    && cd ffmpeg_src \
    && ./configure \
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
    && rm -rf ffmpeg_src

bash -c "cat <<'EOT' >> /etc/profile

export PATH=\${HOME}/.local/bin:/usr/local/cuda/bin:/usr/local/cuda/TensorRT/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/cuda/lib64:/usr/lib/x86_64-linux-gnu:/usr/lib:

if [[ -f \${HOME}/.ssh/id_rsa ]]; then
  HOST=\${HOSTNAME}
  /usr/bin/keychain \${HOME}/.ssh/id_rsa
  source \${HOME}/.keychain/\${HOST}-sh
fi
EOT"

KEYRING_DIR=${HOME}/.config/python_keyring \
    && mkdir -p ${KEYRING_DIR} \
    && cat <<EOT > ${KEYRING_DIR}/keyringrc.cfg
[backend]
default-keyring=keyring.backends.fail.Keyring
EOT

# cd ${PWD}
# curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10 \
#     && python3.10 -m venv /opt/venv \
#     && curl -sSL https://install.python-poetry.org | python3.10 -

# curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10
# curl -sSL https://install.python-poetry.org | python3.10 -
# snap install nvtop

# POETRY=poetry
# RFILE="requirements.txt"
# ${POETRY} export -f ${RFILE} --output ${RFILE} --with torch --with google --without dev \
#     || err "Unable to export ${RFILE}"

# pip3 install --no-cache-dir -r requirements.txt \
#     && pip3 install --ignore-installed --no-cache-dir -U crcmod

rm -rf ${INSTALL_LOCATION}

reboot 0