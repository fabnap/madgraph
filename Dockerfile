FROM quay.io/uninuvola/base:main

ENV MG5_VERSION=3.5.3
ENV PYTHIA8_VERSION=8.309
ENV LHAPDF_VERSION=6.5.1
ENV MADANALYSIS_VERSION=1.9
ENV DELPHES_VERSION=3.5.0

USER root

# Downgrade to Python 3.10 to avoid MG5_aMC compatibility issues
RUN apt update && \
    apt install -y software-properties-common wget curl build-essential git cmake \
    python3.10 python3.10-dev python3-pip && \
    ln -sf /usr/bin/python3.10 /usr/bin/python3 && \
    ln -sf /usr/bin/pip3 /usr/bin/pip

# Install ROOT dependencies
RUN apt install -y dpkg-dev cmake g++ gcc binutils libx11-dev libxpm-dev \
    libxft-dev libxext-dev python3-dev libssl-dev libffi-dev

# Install ROOT
WORKDIR /opt
RUN wget https://root.cern/download/root_v6.28.12.source.tar.gz && \
    tar -xzf root_v6.28.12.source.tar.gz && \
    rm root_v6.28.12.source.tar.gz && \
    mkdir root_build && cd root_build && \
    cmake ../root-6.28.12 -DCMAKE_INSTALL_PREFIX=/opt/root && \
    cmake --build . --target install -- -j$(nproc)

# Add ROOT to environment
ENV ROOTSYS=/opt/root
ENV PATH=$ROOTSYS/bin:$PATH
ENV LD_LIBRARY_PATH=$ROOTSYS/lib:$LD_LIBRARY_PATH
ENV PYTHONPATH=$ROOTSYS/lib:$PYTHONPATH

# Install MG5_aMC
RUN cd /opt && \
    wget https://launchpad.net/mg5amcnlo/3.0/${MG5_VERSION}.x/+download/MG5_aMC_v${MG5_VERSION}.tar.gz && \
    tar -xzf MG5_aMC_v${MG5_VERSION}.tar.gz && \
    rm MG5_aMC_v${MG5_VERSION}.tar.gz && \
    mv MG5_aMC_v${MG5_VERSION} MG5 && \
    chown -R jovyan:jovyan /opt/MG5

USER jovyan
WORKDIR /opt/MG5

# Install packages from MG5 prompt
RUN echo "install lhapdf6" | ./bin/mg5_aMC && \
    echo "install pythia8" | ./bin/mg5_aMC && \
    echo "install Delphes" | ./bin/mg5_aMC && \
    echo "install MadAnalysis5" | ./bin/mg5_aMC

# Set working directory to writable location
WORKDIR /home/jovyan

# Default to bash
CMD ["/bin/bash"]
