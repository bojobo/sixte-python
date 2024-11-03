FROM bojobo/heasoft:6.34 AS base

ARG sixte_version=3.0.2_BETA
ARG simput_version=2.6.1_BETA

USER 0

RUN apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
        autotools-dev \
        automake \
        libcgal-dev \
        libexpat1-dev \
        libgsl0-dev \
        libboost-dev \
        libcmocka-dev \
        autoconf \
        libtool \
        cmake \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/simput \
    && chown heasoft:heasoft /opt/simput

FROM base AS sixte_builder

ADD --chown=heasoft:heasoft https://www.sternwarte.uni-erlangen.de/~sixte/downloads/sixte/simput-${simput_version}.tar.gz simput.tar.gz
ADD --chown=heasoft:heasoft https://www.sternwarte.uni-erlangen.de/~sixte/downloads/sixte/sixte-${sixte_version}.tar.gz sixte.tar.gz

RUN tar xfz simput.tar.gz \
    && cd simput/ \
    && cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/opt/simput \
    && cmake --build build \
    && cmake --install build

RUN tar xfz sixte.tar.gz \
    && cd $(ls -d sixte-*/|head -n 1) \
    && cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/opt/simput \
    && cmake --build build \
    && cmake --install build

FROM base AS final

LABEL version="${sixte_version}" \
      description="Simulation of X-Ray Telescopes (SIXTE) ${sixte_version} https://www.sternwarte.uni-erlangen.de/sixte/" \
      maintainer="Bojan Todorkov"

COPY --from=sixte_builder --chown=heasoft:heasoft /opt/simput /opt/simput

ENV SIMPUT=/opt/simput \
    SIXTE=/opt/simput \
    PATH=/opt/simput/bin:${PATH} \
    PFILES=${PFILES}:/opt/simput/share/sixte/pfiles:/opt/simput/share/simput/pfiles \
    LD_LIBRARY_PATH=/opt/simput/lib:${LD_LIBRARY_PATH}

USER heasoft
WORKDIR /home/heasoft
