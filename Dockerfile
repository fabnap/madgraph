# The FROM and initial USER must be like this, as requested.
FROM quay.io/uninuvola/base:main

# --- Environment Variables ---
ENV MG5_VERSION=3.5.7
ENV PYTHIA8_VERSION=8.309
ENV LHAPDF_VERSION=6.5.1
ENV MADANALYSIS_VERSION=1.9
ENV DELPHES_VERSION=3.5.0
ENV ROOT_VERSION=6.28.12

# Set DEBIAN_FRONTEND to noninteractive to avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# --- System Setup as root ---
USER root

# Install base tools and Python 3.10
# FIX: Added the deadsnakes PPA to find python3.10 and added cleanup steps.
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common wget curl build-essential git cmake && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends python3.10 python3.10-dev python3.10-venv python3-pip && \
    # Clean up apt cache to reduce image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Update system links to point to the new Python version
    ln -sf /usr/bin/python3.10 /usr/bin/python3 && \
    ln -sf /usr/bin/pip3 /usr/bin/pip

# Install ROOT dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends dpkg-dev g++ gcc binutils libx11-dev libxpm-dev \
    libxft-dev libxext-dev libssl-dev libffi-dev libsqlite3-dev libxmu-dev \
    libxrandr-dev libpng-dev libjpeg-dev libxml2-dev libglew-dev libftgl-dev \
    libmysqlclient-dev libtiff-dev libpq-dev libpcre3-dev xlibmesa-glu-dev \
    libbz2-dev liblzma-dev && \
    # Clean up apt cache
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
    # Clean up build files
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
    mv MG5_aMC_v${MG5_VERSION} MG5 && \
    chown -R jovyan:jovyan /opt/MG5

# --- Switch to non-root user ---
USER jovyan
WORKDIR /opt/MG5

# Pre-install MG5 packages
# IMPROVEMENT: Use a heredoc to run all install commands in a single layer. It's cleaner and more efficient.
RUN ./bin/mg5_aMC <<EOF
install lhapdf6
install pythia8
install Delphes
install MadAnalysis5
EOF

# Optional: Add a default PDF set to LHAPDF
# RUN lhapdf install CT10nlo

# Set final working directory and default command
WORKDIR /home/jovyan
CMD ["/bin/bash"]
