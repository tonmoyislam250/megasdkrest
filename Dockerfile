FROM golang:alpine3.17 AS Builder
RUN apk add unzip tar xz wget alpine-sdk git libtool autoconf automake linux-headers musl-dev m4 \
    build-base perl ca-certificates
RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing --update \
     zlib-dev zlib-static curl-dev curl-static openssl-dev openssl-libs-static \
     alpine-sdk git libtool autoconf automake linux-headers musl-dev m4 build-base perl ca-certificates \
     brotli-dev brotli-static readline-dev readline-static unzip tar xz wget libidn2-dev libcurl \
     sqlite-dev sqlite-static libsodium-dev libsodium-static  nghttp2-dev nghttp2-static
RUN wget https://github.com/tonmoyislam250/fluffy-guide/releases/download/v1.0.8/packages.tar.gz \
    && tar -xzf packages.tar.gz && \
    cd packages/crypto/x86_64/ && apk add --allow-untrusted *.apk && \
    cd ../../cares/x86_64/ && apk add --allow-untrusted *.apk
ARG CPU_ARCH=amd64
ENV HOST_CPU_ARCH=$CPU_ARCH

RUN git clone https://github.com/meganz/sdk.git sdk && cd sdk && \
     git checkout v4.9.0 && \
     sh autogen.sh && \
    ./configure CFLAGS='-fpermissive' CXXFLAGS='-fpermissive' CPPFLAGS='-fpermissive' CCFLAGS='-fpermissive' \
    --disable-examples --disable-silent-rules --disable-shared --enable-static --without-freeimage && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install

RUN mkdir -p /usr/local/go/src/ && cd /usr/local/go/src/ && \
    git clone https://github.com/tonmoyislam250/megasdkgo \
    && cd megasdkgo && rm -rf .git && \
    mkdir include && cp -r /go/sdk/include/* include && \
    mkdir .libs && \
    cp /usr/lib/lib*.a .libs/ && ls .libs/ && \
    cp /usr/lib/lib*.la .libs/ && \
    go tool cgo megasdkgo.go

RUN git clone https://github.com/tonmoyislam250/megasdkrest && cd megasdkrest && \
    go build -ldflags "-linkmode external -extldflags '-static' -s -w -X main.Version=${VERSION}" . && \
    mkdir -p /go/build/ && mv megasdkrpc ../build/megasdkrest-${HOST_CPU_ARCH}

FROM scratch AS megasdkrest

COPY --from=builder /go/build/ /
