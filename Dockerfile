FROM quay.io/uninuvola/base:main

ENV MG5_VERSION=3.5.3
ENV PYTHIA8_VERSION=8.309
ENV LHAPDF_VERSION=6.5.1
ENV MADANALYSIS_VERSION=1.9
ENV DELPHES_VERSION=3.5.0
ENV ROOT_VERSION=6.28.12

USER root

# Install base tools and Python 3.10 (avoid Python 3.12 issues)
RUN apt update && \
    apt install -y software-properties-common wget curl build-essential git cmake \
    python3.10 python3.10-dev python3-pip && \
    ln -sf /usr/bin/python3.10 /usr/bin/python3 && \
    ln -sf /usr/bin/pip3 /usr/bin/pip

# Install ROOT dependencies
RUN apt install -y dpkg-dev g++ gcc binutils libx11-dev libxpm-dev libxft-dev libxext-dev \
    libssl-dev libffi-dev libsqlite3-dev libxmu-dev libxrandr-dev libpng-dev libjpeg-dev \
    libxml2-dev libglew-dev libftgl-dev libmysqlclient-dev libtiff-dev libpq-dev \
    libpcre3-dev xlibmesa-glu-dev libbz2-dev liblzma-dev

# Build and install ROOT
WORKDIR /opt
RUN wget https://root.cern/download/root_v${ROOT_VERSION}.source.tar.gz && \
    tar -xzf root_v${ROOT_VERSION}.source.tar.gz && \
    rm root_v${ROOT_VERSION}.source.tar.gz && \
    mkdir root_build && cd root_build && \
    cmake ../root-${ROOT_VERSION} -DCMAKE_INSTALL_PREFIX=/opt/root && \
    cmake --build . --target install -- -j$(nproc)

# ROOT environment setup
ENV ROOTSYS=/opt/root
ENV PATH=$ROOTSYS/bin:$PATH
ENV LD_LIBRARY_PATH=$ROOTSYS/lib:$LD_LIBRARY_PATH
ENV PYTHONPATH=$ROOTSYS/lib:$PYTHONPATH

# Download and extract MG5_aMC
RUN cd /opt && \
    wget https://launchpad.net/mg5amcnlo/3.0/${MG5_VERSION}.x/+download/MG5_aMC_v${MG5_VERSION}.tar.gz && \
    tar -xzf MG5_aMC_v${MG5_VERSION}.tar.gz && \
    rm MG5_aMC_v${MG5_VERSION}.tar.gz && \
    mv MG5_aMC_v${MG5_VERSION} MG5 && \
    chown -R jovyan:jovyan /opt/MG5

USER jovyan
WORKDIR /opt/MG5

# Pre-install MG5 packages (this avoids prompts later)
RUN echo "install lhapdf6" | ./bin/mg5_aMC && \
    echo "install pythia8" | ./bin/mg5_aMC && \
    echo "install Delphes" | ./bin/mg5_aMC && \
    echo "install MadAnalysis5" | ./bin/mg5_aMC

# Optional: Add a default PDF set to LHAPDF
# RUN lhapdf install CT10nlo

# Set working directory to home
WORKDIR /home/jovyan

# Launch interactive shell by default
CMD ["/bin/bash"]
