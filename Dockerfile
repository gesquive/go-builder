FROM golang:alpine
LABEL maintainer="Gus Esquivel <gesquive@gmail.com>"

# Install build requirements
RUN apk update && apk add --no-cache git make

ENV bin $GOPATH/bin

# Create build user.
RUN adduser -D -g '' builder

WORKDIR /app

# Download dependencies
RUN go get -v golang.org/x/lint/golint
RUN go get -v github.com/mitchellh/gox
RUN go get -v github.com/gesquive/gop
