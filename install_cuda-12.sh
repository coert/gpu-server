#!/bin/bash

set -e
set -x

export DEBIAN_FRONTEND=noninteractive

# These are linked, you need to look up the correct driver version that comes with the CUDA version
CUDA_VERSION="12.4.1"
NVIDIA_DRIVER_VERSION="550.54.15"

CURRENT_DIR=$(pwd)

INSTALL_LOCATION=/opt/nvidia_install
mkdir -p ${INSTALL_LOCATION}
cd ${INSTALL_LOCATION}

# Purge old NVIDIA drivers
apt-get remove --purge nvidia-driver-* -y \
    && apt-get autoremove --purge -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install downloaders and installers
apt update && apt upgrade -y \
    && apt install -y --no-install-recommends \
    pkg-config xorg-dev libvulkan-dev libvulkan1 \
    linux-headers-$(uname -r) curl wget nano \
    htop software-properties-common apt-utils git git-core screen unzip

# Extract NVIDIA drivers, CUDA and Extras from the CUDA archive
CUDA_INSTALLER="cuda_${CUDA_VERSION}_${NVIDIA_DRIVER_VERSION}_linux.run" \
    && wget -nv "https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/local_installers/${CUDA_INSTALLER}" \
    && chmod +x ${CUDA_INSTALLER} \
    && "./${CUDA_INSTALLER}" --extract="${INSTALL_LOCATION}/cuda_${CUDA_VERSION}"

# Install CUDA
cuda_string=$(echo $CUDA_VERSION|sed -e 's/\.//g') && cuda_major="${CUDA_VERSION%.*}" \
    && "./${CUDA_INSTALLER}" --silent --toolkit --no-drm \
    && update-alternatives --install /usr/local/cuda cuda /usr/local/cuda-${cuda_major} ${cuda_string}

# Go to the CUDA archive directory and install its NVIDIA drivers
cd "${INSTALL_LOCATION}/cuda_${CUDA_VERSION}"

# Install NVIDIA drivers
NVIDIA_DRIVER_INSTALLER="NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}.run" \
    && ./${NVIDIA_DRIVER_INSTALLER} --no-questions --ui=none

# Install CUPTI (required by Torch 2.1+)
CUPTI="cuda_cupti/extras/CUPTI" \
    && find "${CUPTI}/include/" -type f -exec cp -P {} /usr/local/cuda/include/ \; \
    && find "${CUPTI}/lib64/" -type f -exec cp -P {} /usr/local/cuda/lib64/ \; \
    && find -L "${CUPTI}/lib64/" -xtype l -exec cp -P {} /usr/local/cuda/lib64/ \;

# # Install NCCL (required by Torch 2.1+)
# NCCL="nccl_2.18.5-1+cuda12.2_x86_64" \
#     && wget -nv "https://storage.googleapis.com/docker_resources/${NCCL}.txz" \
#     && tar xxf ${NCCL}.txz \
#     && rm ${NCCL}.txz \
#     && find "${NCCL}/include/" -type f -exec cp -P {} /usr/local/cuda/include/ \; \
#     && find "${NCCL}/lib/" -type f -exec cp -P {} /usr/local/cuda/lib64/ \; \
#     && find -L "${NCCL}/lib/" -xtype l -exec cp -P {} /usr/local/cuda/lib64/ \;

# # Install cuDNN (required by Torch 2.1+)
# CUDNN="cudnn-linux-x86_64-8.9.5.29_cuda12-archive" \
#     && wget -nv "https://storage.googleapis.com/docker_resources/${CUDNN}.tar.xz" \
#     && tar xxf "${CUDNN}.tar.xz" \
#     && rm "${CUDNN}.tar.xz" \
#     && find "${CUDNN}/include/" -type f -exec cp -P {} /usr/local/cuda/include/ \; \
#     && find "${CUDNN}/lib/" -type f -exec cp -P {} /usr/local/cuda/lib64/ \; \
#     && find -L "${CUDNN}/lib/" -xtype l -exec cp -P {} /usr/local/cuda/lib64/ \; \
#     && chmod a+r /usr/local/cuda/include/*.h /usr/local/cuda/lib64/libcudnn* \
#     && rm -rf ${CUDNN}

# # Install cuDNN (required by Tensorflow 2+)
# TENSORRT="TensorRT-8.6.1.6" && trt_cuda="cuda-12.0" \
#     && wget -nv https://storage.googleapis.com/docker_resources/${TENSORRT}.Linux.x86_64-gnu.${trt_cuda}.tar.gz \
#     && tar xzf ${TENSORRT}.Linux.x86_64-gnu.${trt_cuda}.tar.gz \
#     && rm ${TENSORRT}.Linux.x86_64-gnu.${trt_cuda}.tar.gz \
#     && find "${TENSORRT}/include/" -type f -exec cp -P {} /usr/local/cuda/include/ \; \
#     && find "${TENSORRT}/lib/" -type f -exec cp -P {} /usr/local/cuda/lib64/ \; \
#     && find -L "${TENSORRT}/lib/" -xtype l -exec cp -P {} /usr/local/cuda/lib64/ \; \
#     && find "${TENSORRT}/bin/" -type f -exec cp -P {} /usr/local/cuda/bin/ \; \
#     && chmod a+r /usr/local/cuda/include/*.h /usr/local/cuda/lib64/* \
#     && rm -rf ${TENSORRT}

# Install TensorRT
TRT_VER=10.0.0.6 && trt_cuda="cuda-12.4" \
    && wget -nv https://storage.googleapis.com/docker_resources/TensorRT-${TRT_VER}.Linux.x86_64-gnu.${trt_cuda}.tar.gz -O TensorRT.tar.gz \
    && tar -xvf TensorRT.tar.gz \
    && rm TensorRT.tar.gz \
    && find "TensorRT-${TRT_VER}/include/" -type f -exec cp -P {} /usr/local/cuda/include/ \; \
    && find "TensorRT-${TRT_VER}/lib/" -type f -exec cp -P {} /usr/local/cuda/lib64/ \; \
    && find -L "TensorRT-${TRT_VER}/lib/" -xtype l -exec cp -P {} /usr/local/cuda/lib64/ \; \
    && chmod a+r /usr/local/cuda/include/*.h /usr/local/cuda/lib64/* \
    && rm -rf TensorRT-${TRT_VER} \

# Return to INSTALL_LOCATION
cd ${INSTALL_LOCATION}

# Get everything needed for FFMpeg
add-apt-repository -y ppa:deadsnakes/ppa \
    && apt update -y && apt upgrade -y && apt install -y --no-install-recommends \
    python3 ipython3 python3-dev python3.10 python3.12 \
    python3.10-dev python3-apt python3.10-distutils python3.10-venv \
    python3.12-dev python3-apt python3.12-distutils python3.12-venv \
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
    && rm -rf /var/lib/apt/lists/*.

# update-alternatives --install /usr/bin/python python /usr/bin/python3.08 308 \
#     && update-alternatives --install /usr/bin/python python /usr/bin/python3.10 310 \
#     && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 10 \
#     && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 12 \
#     && update-alternatives --set python3 /usr/bin/python3.12

# # Required by FFMpeg
# VIDEO_CODEC="Video_Codec_SDK_12.1.14" \
#     && wget -nv https://storage.googleapis.com/docker_resources/${VIDEO_CODEC}.zip \
#     && unzip -o ${VIDEO_CODEC}.zip \
#     && rm ${VIDEO_CODEC}.zip \
#     && cp Video_Codec_SDK_*/Interface/* /usr/local/include/ \
#     && rm -rf ${VIDEO_CODEC}

# # Required by FFMpeg
# git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git \
#     && cd nv-codec-headers \
#     && make && make install \
#     && cd - \
#     && rm -rf nv-codec-headers

# lsb_release_codename=$(lsb_release -c -s) && GCSFUSE_REPO="gcsfuse-$lsb_release_codename" \
#     && echo "deb https://packages.cloud.google.com/apt ${GCSFUSE_REPO} main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list \
#     && echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] http://packages.cloud.google.com/apt cloud-sdk main" \
#     | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
#     && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | tee /usr/share/keyrings/cloud.google.asc \
#     && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C0BA5CE6DC6315A3 \
#     && apt-get update -y && apt-get install -y --no-install-recommends google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin gcsfuse

# Required for the FFMpeg make to find nvcc
export PATH="/usr/local/cuda/bin:${HOME}/bin:${HOME}/.local/bin:${PATH}"

# # GIT Clone FFMpeg, make and make install
# git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg_src \
#     && cd ffmpeg_src \
#     && ./configure \
#     --pkg-config-flags="--static" \
#     --extra-cflags=-I/usr/local/cuda/include \
#     --extra-ldflags=-L/usr/local/cuda/lib64 \
#     --extra-libs="-lpthread -lm" \
#     --ld="g++" \
#     --enable-cuda-nvcc --enable-cuvid --enable-nvdec --enable-nvenc --enable-libnpp \
#     --enable-gpl --enable-gnutls --enable-libfreetype \
#     --enable-libass --enable-libfdk-aac --enable-libmp3lame --enable-libopus \
#     --enable-libvorbis --enable-libvpx \
#     --enable-libx264 --enable-libx265 \
#     --enable-nonfree --disable-static --enable-shared --enable-optimizations \
#     > configure.log 2>&1 || (cat configure.log && exit 1) \
#     && make -j$(nproc) && make install \
#     && cd - \
#     && rm -rf ffmpeg_src

# Add paths and autoload keychain to general profile 
# and add keyring config which is required by Poetry
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

# Return
cd ${CURRENT_DIR}
# Remove the installation directory
rm -rf ${INSTALL_LOCATION}

snap install nvtop

# Add everything needed to install the workspace
WORKSPACE=/opt/workspace
mkdir -p ${WORKSPACE}
cp ${CURRENT_DIR}/pyproject.toml ${WORKSPACE}/pyproject.toml
cp ${CURRENT_DIR}/poetry.lock ${WORKSPACE}/poetry.lock
cp ${CURRENT_DIR}/install_poetry.sh ${WORKSPACE}/install_poetry.sh
cp ${CURRENT_DIR}/test_torch.sh ${WORKSPACE}/test_torch.sh
cp ${CURRENT_DIR}/test_tensorflow.sh ${WORKSPACE}/test_tensorflow.sh

# TENSORRT_VERSION=$(python3 -c "import tensorflow.compiler as tf_cc; print('.'.join(map(str, tf_cc.tf2tensorrt._pywrap_py_utils.get_linked_tensorrt_version())))" 2> /dev/null) \
#     && TENSORRT_FILE=$(python3 -c "import tensorrt; print(tensorrt.__file__)" 2>/dev/null) \
#     && TENSORRT_DIR=$(dirname "$TENSORRT_FILE") \
#     && TENSORRT_LIBS_FILE=$(python3 -c "import tensorrt_libs; print(tensorrt_libs.__file__)" 2>/dev/null) \
#     && TENSORRT_LIBS_DIR=$(dirname "$TENSORRT_LIBS_FILE") \
#     && ln -srf "${TENSORRT_LIBS_DIR}/libnvinfer.so.8" "${TENSORRT_DIR}/libnvinfer.so.${TENSORRT_VERSION}" \
#     && ln -srf "${TENSORRT_LIBS_DIR}/libnvinfer_plugin.so.8" "${TENSORRT_DIR}/libnvinfer_plugin.so.${TENSORRT_VERSION}"
