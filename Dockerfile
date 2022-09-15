FROM ghcr.io/tonmoyislam250/megarestbase:latest AS builder

ARG CPU_ARCH=amd64
ENV HOST_CPU_ARCH=$CPU_ARCH

ENV VERSION=0.1.1
ENV MEGASDK_VERSION=3.12.2

# MegaSDK
RUN git clone https://github.com/meganz/sdk.git sdk && cd sdk && \
    git checkout v${MEGASDK_VERSION} && \
    sh autogen.sh && \
    ./configure --disable-examples --disable-shared --enable-static --without-freeimage && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install

# MegaSDK-Go
RUN mkdir -p /usr/local/go/src/ && cd /usr/local/go/src/ && \
    git clone https://github.com/l3v11/megasdkgo && \
    cd megasdkgo && rm -rf .git && \
    mkdir include && cp -r /go/sdk/include/* include && \
    mkdir .libs && \
    cp /usr/lib/lib*.a .libs/ && \
    cp /usr/lib/lib*.la .libs/ && \
    go tool cgo megasdkgo.go

# MegaSDK-REST
RUN git clone https://github.com/l3v11/megasdkrest && cd megasdkrest && \
    go build -ldflags "-linkmode external -extldflags '-static' -s -w -X main.Version=${VERSION}" . && \
    mkdir -p /go/build/ && mv megasdkrpc ../build/megasdkrest-${HOST_CPU_ARCH}

FROM scratch AS megasdkrest

COPY --from=builder /go/build/ /
