# syntax=docker.io/docker/dockerfile:1.7-labs
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

# install fsl
FROM base as fsl
#RUN echo "Downloading FSL ..." && \
#    curl -O https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py && \
#    python2 fslinstaller.py -d /opt/fsl && rm fslinstaller.py
RUN echo "Downloading FSL ..." && \
    curl -O https://s3.msi.umn.edu/tmadison-public/fslinstaller.py && \
    python2 fslinstaller.py --manifest https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/manifest-6.0.7.9.json -d /opt/fsl && \
    rm /opt/fsl/bin/*eddy* && \
    rm /opt/fsl/bin/*fibre* && \
    rm /opt/fsl/bin/*fabber* && \
    rm /opt/fsl/bin/*probtrack* && \
    rm /opt/fsl/bin/*flameo* && \
    rm /opt/fsl/bin/*dti* && \
    rm /opt/fsl/bin/*feat* && \
    rm /opt/fsl/bin/*mist* && \
    rm /opt/fsl/bin/*gpu* && \
    rm -rf /opt/fsl/data/first* && \
    rm -rf /opt/fsl/pkgs/fsl*eddy* && \
    rm -rf /opt/fsl/pkgs/fsl*fabber* && \
    rm -rf /opt/fsl/pkgs/fsl*first_models* && \
    rm -rf /opt/fsl/pkgs/fsl*omm* && \
    rm -rf /opt/fsl/pkgs/fsl*mist* && \
    rm -rf /opt/fsl/pkgs/fsl*cuda* && \
    rm -rf /opt/fsl/pkgs/fsleyes* && \
    rm fslinstaller.py

FROM base as final
COPY --from=fsl /opt/fsl /opt/fsl

# make this run with Singularity, too.
RUN ldconfig

# setup ENTRYPOINT
CMD ["/bin/bash"]
