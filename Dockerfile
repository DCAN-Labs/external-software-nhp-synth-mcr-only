FROM ubuntu:18.04 as base
# set non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive
# set working directory to /opt
WORKDIR /opt
# install dependencies
RUN apt-get update && apt-get install -y build-essential gpg wget m4 libglu1-mesa libncursesw5-dev libgdbm-dev \
    gfortran python python-pip libz-dev libreadline-dev libbz2-dev libopenblas-dev liblapack-dev libhdf5-dev \
    libfftw3-dev git graphviz patchelf libssl-dev libsqlite3-dev uuid-dev git-lfs curl bc dc libgl1-mesa-dev \
    unzip libgomp1 libxmu6 libxt6 tcsh libffi-dev lzma-dev liblzma-dev tk-dev libdb-dev && \
    # install cmake
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null \
    | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
    echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ bionic main' \
    | tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
    apt-get update && rm /usr/share/keyrings/kitware-archive-keyring.gpg && \
    apt-get install -y kitware-archive-keyring cmake && \
    # install python3.9
    curl -O https://www.python.org/ftp/python/3.10.16/Python-3.10.16.tgz && tar xvf Python-3.10.16.tgz && \
    rm Python-3.10.16.tgz && cd Python-3.10.16 && ./configure --enable-optimizations && make altinstall && \
    cd .. && rm -rf Python-3.10.16

# install ants
FROM base as ants
RUN echo "Downloading ANTs ..." && \ 
    mkdir -p /opt/ANTs && cd /opt/ANTs && \
    curl -O https://raw.githubusercontent.com/DCAN-Labs/antsInstallExample/refs/heads/master/installANTs.sh && \
    chmod +x /opt/ANTs/installANTs.sh && /opt/ANTs/installANTs.sh && rm installANTs.sh && \
    rm -rf /opt/ANTs/ANTs && rm -rf /opt/ANTs/build && rm -rf /opt/ANTs/install/lib && \
    mv /opt/ANTs/install/bin /opt/ANTs/bin && rm -rf /opt/ANTs/install

FROM base as final
RUN mkdir -p /opt/ANTs
COPY --from=ants /opt/ANTs/bin /opt/ANTs/bin

# make this run with Singularity, too.
RUN ldconfig

# setup ENTRYPOINT
CMD ["/bin/bash"]
