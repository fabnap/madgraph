FROM quay.io/uninuvola/base:main

# --- Environment Variables ---
ENV MG5_VERSION=3.5.7
ENV MG5_DIR_NAME=MG5_aMC_v3_5_7
ENV PYTHIA8_VERSION=8.309
ENV LHAPDF_VERSION=6.5.1
ENV MADANALYSIS_VERSION=1.9
ENV DELPHES_VERSION=3.5.0
ENV ROOT_VERSION=6.28.12

ENV DEBIAN_FRONTEND=noninteractive

# --- System Setup as root ---
USER root

# Install base tools and Python 3.10
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common wget curl build-essential git cmake && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends python3.10 python3.10-dev python3.10-venv python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    ln -sf /usr/bin/python3.10 /usr/bin/python3 && \
    ln -sf /usr/bin/pip3 /usr/bin/pip

# Install ROOT dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends dpkg-dev g++ gcc binutils libx11-dev libxpm-dev \
    libxft-dev libxext-dev libssl-dev libffi-dev libsqlite3-dev libxmu-dev \
    libxrandr-dev libpng-dev libjpeg-dev libxml2-dev libglew-dev libftgl-dev \
    libmysqlclient-dev libtiff-dev libpq-dev libpcre3-dev xlibmesa-glu-dev \
    libbz2-dev liblzma-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Build and install ROOT
WORKDIR /opt
RUN wget https://root.cern/download/root_v${ROOT_VERSION}.source.tar.gz && \
    tar -xzf root_v${ROOT_VERSION}.source.tar.gz && \
    rm root_v${ROOT_VERSION}.source.tar.gz && \
    mkdir root_build && cd root_build && \
    cmake ../root-${ROOT_VERSION} -DCMAKE_INSTALL_PREFIX=/opt/root && \
    cmake --build . --target install -- -j$(nproc) && \
    cd /opt && rm -rf root_build root-${ROOT_VERSION}

# ROOT environment setup
ENV ROOTSYS=/opt/root
ENV PATH=$ROOTSYS/bin:$PATH
ENV LD_LIBRARY_PATH=$ROOTSYS/lib:$LD_LIBRARY_PATH
ENV PYTHONPATH=$ROOTSYS/lib:$PYTHONPATH

# Download and extract MG5_aMC
RUN cd /opt && \
    wget https://launchpad.net/mg5amcnlo/lts/lts.3.5.x/+download/MG5_aMC_v${MG5_VERSION}.tar.gz && \
    tar -xzf MG5_aMC_v${MG5_VERSION}.tar.gz && \
    rm MG5_aMC_v${MG5_VERSION}.tar.gz && \
    mv ${MG5_DIR_NAME} MG5 && \
    chown -R jovyan /opt/MG5

# --- Switch to non-root user ---
USER jovyan
WORKDIR /opt/MG5

# Pre-install MG5 packages
RUN ./bin/mg5_aMC <<EOF
install lhapdf6
install pythia8
install Delphes
install MadAnalysis5
EOF

# Set final working directory and default command
WORKDIR /home/jovyan
CMD ["/bin/bash"]
