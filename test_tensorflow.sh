#!/bin/bash
TENSORRT_VERSION=$(python3 -c "import tensorflow.compiler as tf_cc; print('.'.join(map(str, tf_cc.tf2tensorrt._pywrap_py_utils.get_linked_tensorrt_version())))" 2> /dev/null) \
    && TENSORRT_FILE=$(python3 -c "import tensorrt; print(tensorrt.__file__)" 2>/dev/null) \
    && TENSORRT_DIR=$(dirname "$TENSORRT_FILE") \
    && TENSORRT_LIBS_FILE=$(python3 -c "import tensorrt_libs; print(tensorrt_libs.__file__)" 2>/dev/null) \
    && TENSORRT_LIBS_DIR=$(dirname "$TENSORRT_LIBS_FILE") \
    && ln -srf "${TENSORRT_LIBS_DIR}/libnvinfer.so.8" "${TENSORRT_DIR}/libnvinfer.so.${TENSORRT_VERSION}" \
    && ln -srf "${TENSORRT_LIBS_DIR}/libnvinfer_plugin.so.8" "${TENSORRT_DIR}/libnvinfer_plugin.so.${TENSORRT_VERSION}"

poetry run python3 -c '
import tensorflow as tf
print(f"{tf.__version__=}")
print(tf.reduce_sum(tf.random.normal([1000, 1000])))'