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

# Install MATLAB Compiler Runtime
FROM base as mcr
RUN mkdir /opt/mcr /opt/mcr_download && cd /opt/mcr_download && \
    wget https://ssd.mathworks.com/supportfiles/downloads/R2019a/Release/9/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2019a_Update_9_glnxa64.zip \
    && unzip MATLAB_Runtime_R2019a_Update_9_glnxa64.zip \
    && ./install -agreeToLicense yes -mode silent -destinationFolder /opt/mcr \
    && rm -rf /opt/mcr_download

# install fsl
FROM base as fsl
#RUN echo "Downloading FSL ..." && \
#    curl -O https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py && \
#    python2 fslinstaller.py -d /opt/fsl && rm fslinstaller.py
RUN echo "Downloading FSL ..." && \
    curl -O https://s3.msi.umn.edu/tmadison-public/fslinstaller.py && \
    python2 fslinstaller.py --manifest https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/manifest-6.0.7.9.json -d /opt/fsl &&  rm fslinstaller.py

# install ants
FROM base as ants
RUN echo "Downloading ANTs ..." && \ 
    mkdir -p /opt/ANTs && cd /opt/ANTs && \
    curl -O https://raw.githubusercontent.com/cookpa/antsInstallExample/master/installANTs.sh && \
    chmod +x /opt/ANTs/installANTs.sh && /opt/ANTs/installANTs.sh && rm installANTs.sh && \
    rm -rf /opt/ANTs/ANTs && rm -rf /opt/ANTs/build && rm -rf /opt/ANTs/install/lib && \
    mv /opt/ANTs/install/bin /opt/ANTs/bin && rm -rf /opt/ANTs/install

# install freesurfer
FROM base as freesurfer
# Make libnetcdf
RUN echo "Downloading libnetcdf ..." && \
    curl -sSL --retry 5 https://github.com/Unidata/netcdf-c/archive/v4.6.1.tar.gz | tar zx -C /opt && \
    cd /opt/netcdf-c-4.6.1/ && \
    LDFLAGS=-L/usr/local/lib && CPPFLAGS=-I/usr/local/include && ./configure --disable-netcdf-4 --disable-dap \
    --enable-shared --prefix=/usr/local && \
    make && make install && \
    rm -rf /opt/netcdf-c-4.6.1/ && ldconfig
# Install FreeSurfer v5.3.0-HCP
RUN echo "Downloading FreeSurfer ..." && \
    curl -sSL --retry 5 https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/5.3.0-HCP/freesurfer-Linux-centos6_x86_64-stable-pub-v5.3.0-HCP.tar.gz \
    | tar xz -C /opt \
    --exclude='freesurfer/average/mult-comp-cor' \
    --exclude='freesurfer/lib/cuda' \
    --exclude='freesurfer/lib/qt' \
    --exclude='freesurfer/subjects/V1_average' \
    --exclude='freesurfer/subjects/bert' \
    --exclude='freesurfer/subjects/cvs_avg35' \
    --exclude='freesurfer/subjects/cvs_avg35_inMNI152' \
    --exclude='freesurfer/subjects/fsaverage3' \
    --exclude='freesurfer/subjects/fsaverage4' \
    --exclude='freesurfer/subjects/fsaverage5' \
    --exclude='freesurfer/subjects/fsaverage6' \
    --exclude='freesurfer/subjects/fsaverage_sym' \
    --exclude='freesurfer/trctrain'

from base as final
RUN mkdir -p /opt/ANTs
COPY --from=ants /opt/ANTs/bin /opt/ANTs/bin
COPY --from=fsl /opt/fsl /opt/fsl
COPY --from=freesurfer /usr/local/lib/libnetcdf* /usr/local/lib/
COPY --from=freesurfer /opt/freesurfer /opt/freesurfer
COPY --from=mcr /opt/mcr /opt/mcr

# make this run with Singularity, too.
RUN ldconfig

# setup ENTRYPOINT
CMD ["/bin/bash"]
