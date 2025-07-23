ARG SIXTE_VERSION
ARG SIMPUT_VERSION
ARG HEASOFT_VERSION=latest

FROM scratch AS downloader

ARG SIXTE_VERSION
ARG SIMPUT_VERSION

ADD https://www.sternwarte.uni-erlangen.de/~sixte/downloads/sixte/simput-${SIMPUT_VERSION}.tar.gz simput.tar.gz
ADD https://www.sternwarte.uni-erlangen.de/~sixte/downloads/sixte/sixte-${SIXTE_VERSION}.tar.gz sixte.tar.gz

FROM bojobo/heasoft:${HEASOFT_VERSION} AS base

RUN apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        autotools-dev \
        cmake \
        libboost-dev \
        libcgal-dev \
        libcmocka-dev \
        libexpat1-dev \
        libgsl0-dev \
        libtool \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /home/simput \
    && mkdir -p /home/sixte

FROM base AS sixte_builder

ARG SIXTE_VERSION
ARG SIMPUT_VERSION

COPY --from=downloader ./simput.tar.gz simput.tar.gz
COPY --from=downloader ./sixte.tar.gz sixte.tar.gz

RUN tar xfz simput.tar.gz \
    && cd simput-${SIMPUT_VERSION} \
    && cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/home/simput \
    && cmake --build build \
    && cmake --install build

RUN tar xfz sixte.tar.gz \
    && cd sixte-${SIXTE_VERSION} \
    && cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/home/sixte -DSIMPUT_ROOT=/home/simput \
    && cmake --build build \
    && cmake --install build

FROM base AS final

ARG SIXTE_VERSION

LABEL version="${SIXTE_VERSION}" \
      description="Simulation of X-Ray Telescopes (SIXTE) ${SIXTE_VERSION} https://www.sternwarte.uni-erlangen.de/sixte/" \
      maintainer="Bojan Todorkov"

COPY --from=sixte_builder /home/simput /home/simput
COPY --from=sixte_builder /home/sixte /home/sixte

ENV SIMPUT=/home/simput \
    SIXTE=/home/sixte \
    PATH=/home/simput/bin:/home/sixte/bin:${PATH} \
    PFILES=${PFILES}:/home/sixte/share/sixte/pfiles:/home/simput/share/simput/pfiles \
    LD_LIBRARY_PATH=/home/simput/lib:${LD_LIBRARY_PATH}
