FROM quay.io/uninuvola/base:main

# DO NOT EDIT USER VALUE
USER root

## -- ADD YOUR CODE HERE !! -- ##


# 1) System dependencies
RUN apt-get update && apt-get install -y \
      gfortran g++ wget make tar \
      zlib1g-dev libpng-dev libx11-dev libxpm-dev libxft-dev libxext-dev \
      python3-pip git curl \
    && rm -rf /var/lib/apt/lists/*

# 2) Download & unpack MG5_aMC LTS‑3.5.7
WORKDIR /opt
ENV MG5_VERSION=3.5.7
RUN wget https://launchpad.net/mg5amcnlo/3.0/3.5.x/+download/MG5_aMC_v${MG5_VERSION}.tar.gz && \
    tar -xzf MG5_aMC_v${MG5_VERSION}.tar.gz && \
    rm MG5_aMC_v${MG5_VERSION}.tar.gz

# 3) Install Pythia8 & Delphes via MG5 installer
WORKDIR /opt/MG5_aMC_v${MG5_VERSION//./_}
RUN printf "install pythia8\ninstall Delphes\n" > install_script && \
    ./bin/mg5_aMC install_script && \
    rm install_script

# 4) Smoke‑test MG5
RUN ./bin/mg5_aMC --help | head -n 5

# 5) Expose MG5 in PATH
ENV PATH="/opt/MG5_aMC_v${MG5_VERSION//./_}/bin:$PATH"

# 6) Register Jupyter kernel
RUN python3 -m pip install ipykernel && \
    python3 -m ipykernel install --name mg_env --display-name "MG5+Pythia+Delphes"

# DO NOT EDIT USER VALUE

USER jovyan
