## Chainer
FROM aarch64/ubuntu

# This is the base container for the Jetson TX2 board with drivers (with cuda)

# base URL for NVIDIA libs
ARG URL=http://developer.download.nvidia.com/devzone/devcenter/mobile/jetpack_l4t/3.2GA/m892ki/JetPackL4T_32_b196

# Update packages, install some useful packages
ENV ARCH=arm64
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y apt-utils bzip2 sudo git curl vim

# Deploy relevant JETSON packages
WORKDIR /tmp

# Install drivers first
RUN curl -sL http://developer.nvidia.com/embedded/dlc/l4t-jetson-tx2-driver-package-28-2 | tar xvfj -
RUN chown root /etc/passwd /etc/sudoers /usr/lib/sudo/sudoers.so /etc/sudoers.d/README
RUN /tmp/Linux_for_Tegra/apply_binaries.sh -r / && rm -fr /tmp/*

## Pull the rest of the jetpack libs for cuda/cudnn/tensorrt and install them
RUN curl $URL/cuda-repo-l4t-9-0-local_9.0.252-1_arm64.deb -o /tmp/cuda-repo-l4t_arm64.deb
RUN curl $URL/libcudnn7_7.0.5.13-1+cuda9.0_arm64.deb -o /tmp/libcudnn_arm64.deb
RUN curl $URL/libcudnn7-dev_7.0.5.13-1+cuda9.0_arm64.deb -o /tmp/libcudnn-dev_arm64.deb
RUN curl $URL/nv-tensorrt-repo-ubuntu1604-ga-cuda9.0-trt3.0.4-20180208_1-1_arm64.deb -o /tmp/nv-tensorrt-repo-ubuntu1604_arm64.deb
RUN curl $URL/libopencv_3.3.1_t186_arm64.deb -o /tmp/libopencv_arm64.deb
RUN curl $URL/libopencv-dev_3.3.1_t186_arm64.deb -o /tmp/libopencv-dev_arm64.deb
RUN curl $URL/libopencv-python_3.3.1_t186_arm64.deb -o /tmp/libopencv-python_arm64.deb

## Install libs: L4T, CUDA, cuDNN, Tensorrt
RUN dpkg -i /tmp/cuda-repo-l4t_arm64.deb
RUN apt-key add /var/cuda-repo-9-0-local/7fa2af80.pub
RUN dpkg -i /tmp/nv-tensorrt-repo-ubuntu1604_arm64.deb
RUN apt-key add /var/nv-tensorrt-repo-ga-cuda9.0-trt3.0.4-20180208/7fa2af80.pub
RUN apt-get update && apt-get install -y cuda-toolkit-9.0 tensorrt
RUN dpkg -i /tmp/libcudnn_arm64.deb
RUN dpkg -i /tmp/libcudnn-dev_arm64.deb
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/aarch64-linux-gnu/tegra:/usr/local/cuda-9.0/lib64

## Re-link libs in /usr/lib/<arch>/tegra
RUN ln -s /usr/lib/aarch64-linux-gnu/tegra/libnvidia-ptxjitcompiler.so.28.2.0 /usr/lib/aarch64-linux-gnu/tegra/libnvidia-ptxjitcompiler.so
RUN ln -s /usr/lib/aarch64-linux-gnu/tegra/libnvidia-ptxjitcompiler.so.28.2.0 /usr/lib/aarch64-linux-gnu/tegra/libnvidia-ptxjitcompiler.so.1
RUN ln -sf /usr/lib/aarch64-linux-gnu/tegra/libGL.so /usr/lib/aarch64-linux-gnu/libGL.so
# D.R. -- need to do this for some strange reason (for jetson tx2)
RUN ln -s /usr/lib/aarch64-linux-gnu/libcuda.so /usr/lib/aarch64-linux-gnu/libcuda.so.1

# Install OpenCV dependencies
RUN apt-get update && apt-get install -y libavcodec-ffmpeg56 libavformat-ffmpeg56 libavutil-ffmpeg54 libcairo2 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk2.0-0 libjasper1 libjpeg8 libswscale-ffmpeg3 libtbb2 libtbb-dev

# Install libopencv4tegra
RUN dpkg -i /tmp/libopencv_arm64.deb && dpkg -i /tmp/libopencv-dev_arm64.deb && dpkg -i /tmp/libopencv-python_arm64.deb

## Compile and install Chainer and ChainerCV
RUN apt-get update && apt-get install -y python-pip python-setuptools python-dev python-numpy python-six python-protobuf python-pillow python-h5py

RUN pip install --upgrade pip==9.0.3
RUN pip install cupy
RUN pip install chainer
RUN pip install chainercv

## Adding in extras
COPY src/bashrc /root/.bashrc

# Disable systemd
ENV INITSYSTEM off

# Cleanup
RUN apt-get -y autoremove && apt-get -y autoclean && apt-get clean && rm -rf /var/cache/apt && rm -rf /tmp/*

CMD exec /bin/bash -c "echo 'online' && trap : TERM INT; sleep infinity & wait"