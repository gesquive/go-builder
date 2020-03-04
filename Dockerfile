FROM golang:1.13-alpine AS builder

RUN apk update && apk add --no-cache git

# Build utilities
RUN go get -v golang.org/x/lint/golint
RUN go get -v github.com/mitchellh/gox
RUN env GO111MODULE=on go get -v github.com/boxboat/fixuid && chmod 4755 ${GOPATH}/bin/fixuid

# =============================================================================
FROM golang:1.13-alpine
LABEL maintainer="Gus Esquivel <gesquive@gmail.com>"

ONBUILD ARG TARGETARCH
ONBUILD ARG TARGETOS
ONBUILD ARG TARGETVARIANT

# Install system requirements
RUN apk update && apk add --no-cache ca-certificates tzdata && update-ca-certificates

# Install build requirements
RUN apk update && apk add --no-cache git openssh-client make bash curl rsync
ENV BIN /usr/local/bin

# Create build user/group
RUN addgroup -g 1000 runner && \
    adduser -u 1000 -G runner -h /home/runner -s /bin/sh -D runner

WORKDIR /app

# Install the copy-release script 
COPY copy-release.sh /usr/bin/copy-release

# Install get-github-release
RUN curl -sL https://git.io/JeOSF | bash

# Install codecov uploader
RUN curl -sL https://codecov.io/bash -o ${BIN}/codecov-bash && \
    chmod +x ${BIN}/codecov-bash

# Import from builder
COPY --from=builder ${GOPATH}/bin/golint ${BIN}/golint
COPY --from=builder ${GOPATH}/bin/gox ${BIN}/gox
COPY --from=builder ${GOPATH}/bin/fixuid ${BIN}/fixuid

RUN get-github-release -e goreleaser -d ${BIN} goreleaser/goreleaser
RUN get-github-release -e gop -d ${BIN} gesquive/gop

# Configure fixuid
RUN mkdir -p /etc/fixuid
COPY fixuid.yml /etc/fixuid/config.yml
COPY run.sh ${BIN}/run

