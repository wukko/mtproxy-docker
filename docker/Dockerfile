FROM debian:trixie-slim AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        git \
        libssl-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN git clone --depth 1 https://github.com/TelegramMessenger/MTProxy.git . \
    && make \
    && strip objs/bin/mtproto-proxy

FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /src/objs/bin/mtproto-proxy /mtproto-proxy
COPY --chmod=755 env.sh secrets.sh entrypoint.sh tg-config-updater.sh /

ENTRYPOINT ["/entrypoint.sh"]
