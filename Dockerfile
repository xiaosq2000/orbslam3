FROM osrf/ros:noetic-desktop-full AS orbslam3_base
ARG HTTP_PROXY=http://127.0.0.1:1080
ARG HTTPS_PROXY=https://127.0.0.1:1080
ARG COMPILE_JOBS=12
ENV USER /root
SHELL ["/bin/bash", "-c"]
RUN echo "Acquire::http::proxy \"${HTTP_PROXY}\";" \
    >> /etc/apt/apt.conf && \
    echo "Acquire::https::proxy \"${HTTPS_PROXY}\";" \
    >> /etc/apt/apt.conf && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -qy --no-install-recommends \
    cmake build-essential git vim wget curl unzip \
    libgoogle-glog-dev libgflags-dev libatlas-base-dev libsuitesparse-dev \
    && rm -rf /var/lib/apt/lists/* && \
    head -n -2 /etc/apt/apt.conf > /etc/apt/tmp_apt.conf && \ 
    mv /etc/apt/tmp_apt.conf /etc/apt/apt.conf
# eigen
ADD third_party/eigen ${USER}/third_party/eigen
RUN cd ${USER}/third_party/eigen && \
    cmake . -Bbuild -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build -j${COMPILE_JOBS} && \
    cmake --install build && \
    rm -rf ${USER}/third_party
# opencv
ADD third_party/opencv ${USER}/third_party/opencv
RUN export http_proxy=$HTTP_PROXY && \
    export https_proxy=$HTTPS_PROXY && \
    cd ${USER}/third_party/opencv && \
    cmake . -Bbuild \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=OFF \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_opencv_apps=OFF \
    -DWITH_TBB=ON && \
    cmake --build build -j${COMPILE_JOBS} && \
    cmake --install build && \
    rm -rf ${USER}/third_party
# pangolin
ADD third_party/Pangolin ${USER}/third_party/Pangolin
RUN cd ${USER}/third_party/Pangolin && \
    cmake . -Bbuild -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build -j${COMPILE_JOBS} && \
    cmake --install build && \
    rm -rf ${USER}/third_party
FROM orbslam3_base AS orbslam3_dev
RUN echo "Acquire::http::proxy \"${HTTP_PROXY}\";" \
    >> /etc/apt/apt.conf && \
    echo "Acquire::https::proxy \"${HTTPS_PROXY}\";" \
    >> /etc/apt/apt.conf && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -qy --no-install-recommends \
    # python
    python3-pip python3-tk python3-catkin-tools \
    # x11 client
    xauth \
    # doxygen
    doxygen \
    # ccls dependencies
    clang-9 libclang-9-dev llvm-9-dev zlib1g-dev \
    libncurses-dev rapidjson-dev \
    && rm -rf /var/lib/apt/lists/* && \
    head -n -2 /etc/apt/apt.conf > /etc/apt/tmp_apt.conf && \ 
    mv /etc/apt/tmp_apt.conf /etc/apt/apt.conf
# python modules
RUN pip3 install -U autopep8 \
    cpplint \
    numpy pandas matplotlib ipywidgets \
    pytransform3d && \
    pip3 install evo --upgrade --no-binary evo
# ccls
ADD third_party/dev_utils/cpp/ccls ${USER}/ccls
RUN cd ${USER}/ccls && \
    cmake . -BRelease -DCMAKE_BUILD_TYPE=Release \ 
    -DCMAKE_PREFIX_PATH=/usr/lib/llvm-9 \
    -DLLVM_INCLUDE_DIR=/usr/lib/llvm-9/include && \
    cmake --build Release -j${COMPILE_JOBS}
# initialize a catkin workspace
ENV WORKSPACE ${USER}/catkin_ws
RUN mkdir -p ${WORKSPACE}/src && \
    cd ${WORKSPACE} && \
    catkin init && \
    catkin config --extend /opt/ros/noetic && \
    catkin config --cmake-args -DCMAKE_BUILD_TYPE=Release -DROS_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
# set up ros and catkin_ws automatically
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ${USER}/.bashrc && \
    echo "source ${USER}/catkin_ws/devel/setup.bash" >> ${USER}/.bashrc
# git configuration
RUN git config --global user.name "肖书奇" && \
    git config --global user.email "xiaoshuqi@ldrobot.com" && \
    git config --global core.editor vim
# vim configuration
ADD third_party/dev_utils/vim/.vimrc ${USER}/.vimrc
# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics
