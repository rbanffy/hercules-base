# syntax=docker/dockerfile:1

FROM debian:testing-slim

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get -y install \
        autoconf \
        automake \
        build-essential \
        cmake \
        flex \
        gawk \
        git \
        libbz2-dev \
        libcap2-bin \
        libltdl-dev \
        libtool-bin \
        m4 \
        time \
        unzip \
        wget \
        zlib1g-dev && \
    cd /tmp && \
    wget -c https://github.com/hercules-390/SoftFloat-3a/archive/refs/heads/master.zip -O softfloat-master.zip && \
    unzip softfloat-master.zip && \
    mv SoftFloat-3a-master SoftFloat-3a && \
    cd SoftFloat-3a && \
    ./1Stop && \
    cd /tmp && \
    wget -c https://github.com/SDL-Hercules-390/hyperion/archive/refs/heads/master.zip -O hyperion-master.zip && \
    unzip hyperion-master.zip && \
    mv hyperion-master hyperion && \
    cd hyperion && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install && \
    apt-get -y remove \
        autoconf \
        automake \
        build-essential \
        cmake \
        flex \
        gawk \
        git \
        libbz2-dev \
        libcap2-bin \
        libltdl-dev \
        libtool-bin \
        m4 \
        time \
        unzip \
        wget \
        zlib1g-dev ; \
        apt-get -y autoremove ; \
    rm -rf /var/lib/apt/lists/* *.zip hyperion SoftFloat-3a
