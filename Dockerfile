# syntax=docker/dockerfile:1

FROM debian:testing-slim

ENV LD_LIBRARY_PATH=/usr/local/lib

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
    # Create external package destination folder.
    mkdir -p /tmp/extpkgs/SoftFloat /tmp/extpkgs/crypto /tmp/extpkgs/telnet /tmp/extpkgs/decNumber && \
    # Download the external packages.
    wget https://codeload.github.com/SDL-Hercules-390/SoftFloat/zip/refs/heads/master -O /tmp/softfloat-master.zip && \
    wget https://codeload.github.com/SDL-Hercules-390/crypto/zip/refs/heads/master -O /tmp/crypto-master.zip && \
    wget https://codeload.github.com/SDL-Hercules-390/telnet/zip/refs/heads/master -O /tmp/telnet-master.zip && \
    wget https://codeload.github.com/SDL-Hercules-390/decNumber/zip/refs/heads/master -O /tmp/decnumber-master.zip && \
    # Download and expand the latest Hercules.
    wget https://codeload.github.com/Hercules-Aethra/aethra/zip/refs/heads/master -O /tmp/aethra-master.zip && \
    unzip /tmp/aethra-master.zip && \
    # Remove pre-built parts.
    # rm -rfv /tmp/hyperion-master/SoftFloat \
    #     /tmp/hyperion-master/crypto \
    #     /tmp/hyperion-master/telnet \
    #     /tmp/hyperion-master/decNumber && \
    # # Re-add their directories
    # mkdir -v /tmp/hyperion-master/SoftFloat \
    #     /tmp/hyperion-master/crypto \
    #     /tmp/hyperion-master/telnet \
    #     /tmp/hyperion-master/decNumber && \
    # Build SoftFloat.
    unzip /tmp/softfloat-master.zip && \
    mkdir /tmp/softfloat && \
    cd /tmp/softfloat && \
    /tmp/SoftFloat-master/build --pkgname . --all --install /tmp/extpkgs/SoftFloat && \
    cd /tmp && \
    # Build crypto.
    unzip /tmp/crypto-master.zip && \
    mkdir /tmp/crypto && \
    cd /tmp/crypto && \
    /tmp/crypto-master/build --pkgname . --all --install /tmp/extpkgs/crypto && \
    cd /tmp && \
    # Build telnet.
    unzip /tmp/telnet-master.zip && \
    mkdir /tmp/telnet && \
    cd /tmp/telnet && \
    /tmp/telnet-master/build --pkgname . --all --install /tmp/extpkgs/telnet && \
    cd /tmp && \
    # Build decNumber.
    unzip /tmp/decnumber-master.zip && \
    mkdir /tmp/decnumber && \
    cd /tmp/decnumber && \
    /tmp/decNumber-master/build --pkgname . --all --install /tmp/extpkgs/decNumber && \
    cd /tmp && \
    # Build the latest Hercules.
    cd /tmp/aethra-master && \
    ./autogen.sh && \
    ./configure --enable-extpkgs=/tmp/extpkgs && \
    make && \
    make install && \
    # Remove no longer needed packages and clean up the image.
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
    rm -rfv /var/lib/apt/lists/* *.zip /tmp/aethra-master

CMD [ "/usr/local/bin/hercules" ]