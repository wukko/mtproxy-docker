FROM alpine:latest AS build

RUN apk add --no-cache \
    build-base \
    git \
    linux-headers \
    openssl-dev \
    zlib-dev

WORKDIR /src

RUN git clone --depth 1 https://github.com/TelegramMessenger/MTProxy.git . \
    && make \
    && strip objs/bin/mtproto-proxy

FROM alpine:latest

RUN apk add --no-cache bash ca-certificates curl

COPY --from=build /src/objs/bin/mtproto-proxy /mtproto-proxy
COPY env.sh /env.sh
COPY secrets.sh /secrets.sh
COPY entrypoint.sh /entrypoint.sh
COPY tg-config-updater.sh /tg-config-updater.sh

RUN chmod +x /env.sh /secrets.sh /entrypoint.sh /tg-config-updater.sh

ENTRYPOINT ["/entrypoint.sh"]
