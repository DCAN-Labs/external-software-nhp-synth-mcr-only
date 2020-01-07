#! /bin/bash
imagename=external-software
datestamp=$( date +%Y%m%d )
tarfile=${imagename}_${datestamp}.tar

pushd /mnt/max/shared/code/internal/utilities/dcan-stack_dockerfiles/${imagename}
docker build . -t dcanlabs/${imagename}
popd
docker save -o ${tarfile} dcanlabs/${imagename}:latest
chmod g+rw ${tarfile}
gzip ${tarfile}
popd

