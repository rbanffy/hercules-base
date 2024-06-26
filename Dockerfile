# syntax=docker/dockerfile:1

FROM debian:stable-slim

ENV LD_LIBRARY_PATH=/usr/local/lib

LABEL maintainer="Ricardo Bánffy <rbanffy@gmail.com>"

ARG USERNAME=hercules
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG TARGETPLATFORM
ARG TARGETARCH

RUN DEBIAN_FRONTEND=noninteractive \
    groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    apt-get update && \
    apt-get -y full-upgrade && \
    apt-get -y install \
    apt-utils \
    autoconf \
    automake \
    build-essential \
    ca-certificates \
    cmake \
    flex \
    gawk \
    git \
    libbz2-dev \
    libcap2-bin \
    libltdl-dev \
    libregina3-dev \
    libtool-bin \
    m4 \
    sysvbanner \
    time \
    unzip \
    wget \
    zlib1g-dev && \
    cd /home/$USERNAME/ && \
    # Get the main repo
    git clone https://github.com/SDL-Hercules-390/hyperion.git && \
    # Remove Hyperion's distribution bundled amd64 binaries
    rm -v /home/$USERNAME/hyperion/crypto/lib/* && \
    rm -v /home/$USERNAME/hyperion/decNumber/lib/* && \
    rm -v /home/$USERNAME/hyperion/SoftFloat/lib/* && \
    rm -v /home/$USERNAME/hyperion/telnet/lib/* && \
    rm -rfv /home/$USERNAME/hyperion/.git && \
    # Get the external modules
    banner external modules && \
    git clone https://github.com/SDL-Hercules-390/crypto.git && \
    git clone https://github.com/SDL-Hercules-390/decNumber.git && \
    git clone https://github.com/SDL-Hercules-390/SoftFloat.git && \
    git clone https://github.com/SDL-Hercules-390/telnet.git && \
    # Figure out the library destination 
    echo "TARGETARCH is ${TARGETARCH}"; \
    if [ "${TARGETARCH}" = "ppc64le" ]; then \
        export DEST="ppc"; \
    #   export WORD_LENGTH="64";\
    elif [ "${TARGETARCH}" = "arm64" ]; then \
        export DEST="aarch64"; \
    #   export WORD_LENGTH="64"; \
    elif [ "${TARGETARCH}" = "arm" ]; then \
        export DEST="${TARGETARCH}"; \
    #   export WORD_LENGTH="32"; \
    elif [ "${TARGETARCH}" = "amd64" ]; then \
        export DEST=""; \
    #   export WORD_LENGTH="64"; \
    elif [ "${TARGETARCH}" = "s390x" ]; then \
        export DEST="${TARGETARCH}"; \
    #   export WORD_LENGTH="32"; \
    else \
        echo "Unsuported platform ${TARGETPLATFORM}"; \
        exit 3; \
    fi && \
    echo "${TARGETARCH} mapped to \"$DEST\""; \
    # Build the external crypto module
    mkdir -v /home/$USERNAME/crypto32.Release && \
    cd /home/$USERNAME/crypto32.Release && \
    cmake ../crypto && \
    make install && \
    mkdir -v /home/$USERNAME/crypto64.Release && \
    cd /home/$USERNAME/crypto64.Release && \
    cmake ../crypto && \
    make install && \
    mkdir -pv /home/$USERNAME/hyperion/crypto/lib/${DEST} && \
    cp -v /usr/local/lib/libcrypto*.a /home/$USERNAME/hyperion/crypto/lib/${DEST} && \
    # Build the external decNumber module
    mkdir -v /home/$USERNAME/decNumber32.Release && \
    cd /home/$USERNAME/decNumber32.Release && \
    cmake ../decNumber && \
    make install && \
    mkdir -v /home/$USERNAME/decNumber64.Release && \
    cd /home/$USERNAME/decNumber64.Release && \
    cmake ../decNumber && \
    make install && \
    mkdir -pv /home/$USERNAME/hyperion/decNumber/lib/${DEST} && \
    cp -v /usr/local/lib/libdecNumber*.a /home/$USERNAME/hyperion/decNumber/lib/${DEST} && \
    # Build the external SoftFloat module
    mkdir -v /home/$USERNAME/SoftFloat32.Release && \
    cd /home/$USERNAME/SoftFloat32.Release && \
    cmake ../SoftFloat && \
    make install && \
    mkdir -v /home/$USERNAME/SoftFloat64.Release && \
    cd /home/$USERNAME/SoftFloat64.Release && \
    cmake ../SoftFloat && \
    make install && \
    mkdir -pv /home/$USERNAME/hyperion/SoftFloat/lib/${DEST} && \
    cp -v /usr/local/lib/libSoftFloat*.a /home/$USERNAME/hyperion/SoftFloat/lib/${DEST} && \
    # Build the external telnet module
    mkdir -v /home/$USERNAME/telnet32.Release && \
    cd /home/$USERNAME/telnet32.Release && \
    cmake ../telnet && \
    make install && \
    mkdir -v /home/$USERNAME/telnet64.Release && \
    cd /home/$USERNAME/telnet64.Release && \
    cmake ../telnet && \
    make install && \
    mkdir -pv /home/$USERNAME/hyperion/telnet/lib/${DEST} && \
    cp -v /usr/local/lib/libtelnet*.a /home/$USERNAME/hyperion/telnet/lib/${DEST} && \
    # Build Hercules
    cd /home/$USERNAME/hyperion && \
    rm -rfv .git && \
    if [ "${TARGETARCH}" = "arm" ]; then \
        ./configure --host=arm-linux-gnueabihf -target=arm; \
    else \
        ./configure; \
    fi && \
    make && \
    make install && \
    # Remove unwanted files. Useful when it's a single step.
    apt purge -y \
    apt-utils \
    autoconf \
    automake \
    build-essential \
    ca-certificates \
    cmake \
    flex \
    gawk \
    git \
    libbz2-dev \
    libcap2-bin \
    libltdl-dev \
    libregina3-dev \
    libtool-bin \
    m4 \
    sysvbanner \
    time \
    unzip \
    wget \
    zlib1g-dev && \
    apt -y autoremove && \
    rm -rfv /var/lib/apt/lists/* *.zip hyperion *.Release SoftFloat64 decNumber telnet crypto && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME

EXPOSE 3270/TCP
EXPOSE 8038/TCP

CMD ["hercules"]