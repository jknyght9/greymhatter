# GreymHatter Tool Builder
# Compiles DFIR tools from source inside a container to keep the host clean.
# Binaries are extracted to /output/ for copying to the host.
#
# Usage (via Ansible docker-build.yml task):
#   docker build -f Dockerfile.builder -t greymhatter-builder .
#   docker create --name builder greymhatter-builder
#   docker cp builder:/output/ /tmp/tool-binaries/
#   docker rm builder && docker rmi greymhatter-builder

FROM fedora:42

# All build dependencies — these never touch the host system
RUN dnf install -y \
    autoconf automake gcc gcc-c++ libtool make git \
    bison flex pkg-config \
    zlib-devel e2fsprogs-devel libuuid-devel \
    afflib-devel libewf-devel \
    fuse-devel python3-devel python3-setuptools python3-pip \
    re2 re2-devel gettext-devel openssl-devel \
    && dnf clean all

RUN mkdir -p /output

# --- libvmdk (VMDK image support for Sleuthkit) ---
RUN git clone --depth 1 https://github.com/libyal/libvmdk /build/libvmdk \
    && cd /build/libvmdk \
    && ./synclibs.sh \
    && ./autogen.sh \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && make install DESTDIR=/output/libvmdk \
    && rm -rf /build/libvmdk

# --- libvhdi (VHD/VHDX image support for Sleuthkit) ---
RUN git clone --depth 1 https://github.com/libyal/libvhdi /build/libvhdi \
    && cd /build/libvhdi \
    && ./synclibs.sh \
    && ./autogen.sh \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && make install DESTDIR=/output/libvhdi \
    && rm -rf /build/libvhdi

# --- Sleuthkit (with libvmdk and libvhdi compiled above) ---
RUN git clone --depth 1 https://github.com/sleuthkit/sleuthkit /build/sleuthkit \
    && cd /build/sleuthkit \
    && ./bootstrap \
    && ./configure \
    && make -j$(nproc) \
    && make install DESTDIR=/output/sleuthkit \
    && rm -rf /build/sleuthkit

# --- bulk_extractor ---
RUN git clone --depth 1 --recursive https://github.com/simsong/bulk_extractor /build/bulk_extractor \
    && cd /build/bulk_extractor \
    && ./bootstrap.sh \
    && ./configure --disable-libewf \
    && make -j$(nproc) \
    && make install DESTDIR=/output/bulk_extractor \
    && rm -rf /build/bulk_extractor

# --- libbde (bdemount) ---
RUN git clone --depth 1 https://github.com/libyal/libbde /build/libbde \
    && cd /build/libbde \
    && ./synclibs.sh \
    && ./autogen.sh \
    && ./configure --enable-python \
    && make -j$(nproc) \
    && make install DESTDIR=/output/libbde \
    && rm -rf /build/libbde

# --- libfvde (fvdemount) ---
RUN git clone --depth 1 https://github.com/libyal/libfvde /build/libfvde \
    && cd /build/libfvde \
    && ./synclibs.sh \
    && ./autogen.sh \
    && ./configure --enable-python \
    && make -j$(nproc) \
    && make install DESTDIR=/output/libfvde \
    && rm -rf /build/libfvde

CMD ["echo", "Build complete. Extract binaries from /output/"]
