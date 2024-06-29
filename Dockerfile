# syntax=docker/dockerfile:1

FROM debian:testing-slim

ENV LD_LIBRARY_PATH=/usr/local/lib

LABEL maintainer="Ricardo Bánffy <rbanffy@gmail.com>"

ARG QEMU_CPU
ARG USERNAME=hercules
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG TARGETPLATFORM
ARG TARGETARCH

COPY hyperion-master.zip crypto-master.zip decNumber-master.zip SoftFloat-master.zip telnet-master.zip /

RUN DEBIAN_FRONTEND=noninteractive \
    echo "TARGETPLATFORM is '${TARGETPLATFORM}'"; \
    echo "TARGETARCH is '${TARGETARCH}'"; \
    echo "arch returns $( arch )"; \
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
    gcc-14 \
    git \
    libatomic1 \
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
    banner "Updated" && \
    cd /home/$USERNAME/ && \
    # Get the main repo.
    unzip /hyperion-master.zip && \
    mv -v hyperion-master hyperion && \
    # Remove Hyperion's distribution bundled amd64 binaries.
    rm -v /home/$USERNAME/hyperion/crypto/lib/* && \
    rm -v /home/$USERNAME/hyperion/decNumber/lib/* && \
    rm -v /home/$USERNAME/hyperion/SoftFloat/lib/* && \
    rm -v /home/$USERNAME/hyperion/telnet/lib/* && \
    # Use GCC-14 for compilation
    export CC=gcc-14 && \
    # Figure out the library destination.
    banner "${TARGETARCH}"; \
    banner "$( arch )"; \
    # Can't rely on TARGETARCH - it isn't present when not in emulation.
    # This way we support running `docker build` natively on the target.
    if [ "${TARGETARCH}" = "ppc64le" ] || [ "$( arch )" = "ppc64le" ]; then \
        export DEST="ppc"; \
    #   export WORD_LENGTH="64";\
    elif [ "${TARGETARCH}" = "arm64" ] || [ "$( arch )" = "aarch64" ]; then \
        export DEST="aarch64"; \
    #   export WORD_LENGTH="64"; \
    elif [ "${TARGETARCH}" = "arm" ] || [ "$( arch )" = "armv7l" ] || [ "$( arch )" = "armv6l" ]; then \
        export DEST="${TARGETARCH}"; \
    #   export WORD_LENGTH="32"; \
    elif [ "${TARGETARCH}" = "amd64" ] || [ "$( arch )" = "amd64" ]; then \
        export DEST=""; \
    #   export WORD_LENGTH="64"; \
    elif [ "${TARGETARCH}" = "s390x" ] || [ "$( arch )" = "s390x" ]; then \
        export DEST="${TARGETARCH}"; \
    #   export WORD_LENGTH="32"; \
    else \
        echo "Unsuported platform ${TARGETPLATFORM} and/or architecture '$( arch )'"; \
        exit 3; \
    fi && \
    echo "'${TARGETARCH}/$( arch )' mapped to '$DEST'"; \
    banner external modules && \
    # Build the external crypto module.
    banner crypto && \
    unzip /crypto-master.zip && \
    mkdir -v /home/$USERNAME/crypto32.Release && \
    cd /home/$USERNAME/crypto32.Release && \
    cmake --trace-expand ../crypto-master && \
    make VERBOSE=1 install && \
    mkdir -v /home/$USERNAME/crypto64.Release && \
    cd /home/$USERNAME/crypto64.Release && \
    cmake --trace-expand ../crypto-master && \
    make VERBOSE=1 install && \
    mkdir -pv /home/$USERNAME/hyperion/crypto/lib/${DEST} && \
    cp -v /usr/local/lib/libcrypto*.a /home/$USERNAME/hyperion/crypto/lib/${DEST} && \
    # Build the external decNumber module.
    banner decNumber && \
    cd /home/$USERNAME && \
    unzip /decNumber-master.zip && \
    ls -l .. && \
    mkdir -v /home/$USERNAME/decNumber32.Release && \
    cd /home/$USERNAME/decNumber32.Release && \
    cmake --trace-expand ../decNumber-master && \
    make VERBOSE=1 install && \
    mkdir -v /home/$USERNAME/decNumber64.Release && \
    cd /home/$USERNAME/decNumber64.Release && \
    cmake --trace-expand ../decNumber-master && \
    make VERBOSE=1 install && \
    mkdir -pv /home/$USERNAME/hyperion/decNumber/lib/${DEST} && \
    cp -v /usr/local/lib/libdecNumber*.a /home/$USERNAME/hyperion/decNumber/lib/${DEST} && \
    # Build the external SoftFloat module
    banner SoftFloat && \
    cd /home/$USERNAME && \
    unzip /SoftFloat-master.zip && \
    mkdir -v /home/$USERNAME/SoftFloat32.Release && \
    cd /home/$USERNAME/SoftFloat32.Release && \
    cmake --trace-expand ../SoftFloat-master && \
    make VERBOSE=1 install && \
    mkdir -v /home/$USERNAME/SoftFloat64.Release && \
    cd /home/$USERNAME/SoftFloat64.Release && \
    cmake --trace-expand ../SoftFloat-master && \
    make VERBOSE=1 install && \
    mkdir -pv /home/$USERNAME/hyperion/SoftFloat/lib/${DEST} && \
    cp -v /usr/local/lib/libSoftFloat*.a /home/$USERNAME/hyperion/SoftFloat/lib/${DEST} && \
    # Build the external telnet module
    banner telnet && \
    cd /home/$USERNAME && \
    unzip /telnet-master.zip && \
    mkdir -v /home/$USERNAME/telnet32.Release && \
    cd /home/$USERNAME/telnet32.Release && \
    cmake --trace-expand ../telnet-master && \
    make VERBOSE=1 install && \
    mkdir -v /home/$USERNAME/telnet64.Release && \
    cd /home/$USERNAME/telnet64.Release && \
    cmake --trace-expand ../telnet-master && \
    make VERBOSE=1 install && \
    mkdir -pv /home/$USERNAME/hyperion/telnet/lib/${DEST} && \
    cp -v /usr/local/lib/libtelnet*.a /home/$USERNAME/hyperion/telnet/lib/${DEST} && \
    # Build Hercules itself
    cd /home/$USERNAME/hyperion && \
    rm -rfv .git && \
    if [ "${TARGETARCH}" = "arm" ]; then \
        ./configure --host=arm-linux-gnueabihf -target=arm; \
    else \
        ./configure; \
    fi && \
    banner "Configured"

RUN cd /home/$USERNAME/hyperion && \
    # Use GCC-14 for compilation
    export CC=gcc-14 && \
    make && \
    make VERBOSE=1 install && \
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
    gcc-14 \
    git \
    libatomic1 \
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