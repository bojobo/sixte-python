FROM bojobo/heasoft:6.34 AS base

ARG SIXTE_VERSION=3.0.5
ARG SIMPUT_VERSION=2.6.3

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

ADD --chown=heasoft:heasoft https://www.sternwarte.uni-erlangen.de/~sixte/downloads/sixte/simput-${SIMPUT_VERSION}.tar.gz simput.tar.gz
ADD --chown=heasoft:heasoft https://www.sternwarte.uni-erlangen.de/~sixte/downloads/sixte/sixte-${SIXTE_VERSION}.tar.gz sixte.tar.gz

RUN tar xfz simput.tar.gz \
    && cd simput-${SIMPUT_VERSION} \
    && cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/opt/simput \
    && cmake --build build \
    && cmake --install build

RUN tar xfz sixte.tar.gz \
    && cd sixte-${SIXTE_VERSION} \
    && cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/opt/simput \
    && cmake --build build \
    && cmake --install build

FROM base AS final

LABEL version="${SIXTE_VERSION}" \
      description="Simulation of X-Ray Telescopes (SIXTE) ${SIXTE_VERSION} https://www.sternwarte.uni-erlangen.de/sixte/" \
      maintainer="Bojan Todorkov"

COPY --from=sixte_builder --chown=heasoft:heasoft /opt/simput /opt/simput

ENV SIMPUT=/opt/simput \
    SIXTE=/opt/simput \
    PATH=/opt/simput/bin:${PATH} \
    PFILES=${PFILES}:/opt/simput/share/sixte/pfiles:/opt/simput/share/simput/pfiles \
    LD_LIBRARY_PATH=/opt/simput/lib:${LD_LIBRARY_PATH}

USER heasoft
WORKDIR /home/heasoft
