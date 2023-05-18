FROM ghcr.io/tonmoyislam250/megacppsdk:latest AS builder

ARG CPU_ARCH=amd64
ENV HOST_CPU_ARCH=$CPU_ARCH

RUN git clone https://github.com/meganz/sdk.git sdk && cd sdk && \
     git checkout v4.8.0 && \
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
