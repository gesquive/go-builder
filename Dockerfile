ARG BASE_IMAGE=golang:1.13-alpine
FROM $BASE_IMAGE
LABEL maintainer="Gus Esquivel <gesquive@gmail.com>"

# Install system requirements
RUN apk update && apk add --no-cache ca-certificates tzdata && update-ca-certificates

# Install build requirements
RUN apk update && apk add --no-cache git make bash curl rsync
ENV BIN ${GOPATH}/bin

# Create build user.
RUN adduser -D -g '' runner

WORKDIR /app

# Install the copy-release script 
COPY copy-release.sh /usr/bin/copy-release

# Install get-github-release
RUN curl -sL https://git.io/JeOSF | bash

# Download dependencies
RUN go get -v golang.org/x/lint/golint
RUN go get -v github.com/mitchellh/gox
RUN env GO111MODULE=on go get -v github.com/gesquive/gop

RUN get-github-release -e goreleaser -d ${GOPATH}/bin goreleaser/goreleaser
# RUN get-github-release -e gop -d ${GOPATH}/bin gesquive/gop
