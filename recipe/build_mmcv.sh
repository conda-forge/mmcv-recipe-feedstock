#!/bin/bash
set -ex

# TODO remove when migrating to PyTorch 2.9
if [ "$CROSS_COMPILING" == "true" ]; then
  echo "Detected cross-compilation - deleting env-based pytorch header files to prevent duplicate definition errors"
  rm -rf "$CONDA_PREFIX"/lib/python3.*/site-packages/torch/include/
fi

export PATH="$PWD:$PATH"

export CC=$(basename $CC)
export CXX=$(basename $CXX)

# uncomment for debug
# export CMAKE_VERBOSE_MAKEFILE=1

if [[ "$target_platform" == "osx-64" ]]; then
  export CXXFLAGS="$CXXFLAGS -DTARGET_OS_OSX=1"
  export CFLAGS="$CFLAGS -DTARGET_OS_OSX=1"
fi

export CMAKE_GENERATOR=Ninja
LDFLAGS="${LDFLAGS//-Wl,-z,now/-Wl,-z,lazy}"
export MAX_JOBS=${CPU_COUNT}
export MMCV_WITH_OPS=1

if [[ ${cuda_compiler_version} != "None" ]]; then
    export FORCE_CUDA="1"
    # https://github.com/conda-forge/conda-forge.github.io/issues/1901
    if [[ ${cuda_compiler_version} == 12.* ]]; then
      export TORCH_CUDA_ARCH_LIST="5.0;6.0;7.0;7.5;8.0;8.6;9.0;10.0;12.0+PTX"
      # $CUDA_HOME not set in CUDA 12.0. Using $PREFIX
      export CUDA_TOOLKIT_ROOT_DIR="${PREFIX}"
    else
        echo "unsupported cuda version. edit build_mmcv.sh"
        exit 1
    fi
fi

export CMAKE_BUILD_TYPE=Release
# we skip deps so opencv-python from pip is not pulled in
$PYTHON -m pip install . -vvv --no-deps
