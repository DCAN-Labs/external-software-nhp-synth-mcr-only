FROM ubuntu:18.04 as base
# set non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive
# set working directory to /opt
WORKDIR /opt

RUN mkdir -p /opt/ANTs
COPY --from=dcanumn/external-software-nhp-synth:ants-only /opt/ANTs/bin /opt/ANTs/bin
COPY --from=dcanumn/external-software-nhp-synth:fsl-only /opt/fsl /opt/fsl
COPY --from=dcanumn/external-software-nhp-synth:mcr-only /opt/mcr /opt/mcr

# setup ENTRYPOINT
CMD ["/bin/bash"]
