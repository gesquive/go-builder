#
#  Makefile
#

export SHELL ?= /bin/bash

# Project owner used in package name
OWNER = gesquive

# Project name used in package name
PROJECT_NAME = go-builder

# Project url used for builds
# examples: index.docker.io, registry.gitlab.com
REGISTRY_URL = index.docker.io

# The golang version to use
GOVERSION ?= 1.13

BASE_IMAGE=${GOVERSION}-alpine
IMAGE := ${REGISTRY_URL}/${OWNER}/${PROJECT_NAME}
DATE_VERSION = $(shell date "+%Y%m%d")
HASH_VERSION = $(shell git describe --always | sed 's/^v//' | sed 's/-g/-/')
DK_VERSION = ${GOVERSION}-${DATE_VERSION}-${HASH_VERSION}

export DOCKER_CLI_EXPERIMENTAL = enabled

DOCKER ?= docker

default: build

.PHONY: help
help:
	@echo 'Management commands for $(PROJECT_NAME):'
	@grep -Eh '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	 awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: ## Build the image
	@echo "building ${DK_VERSION}"
	${DOCKER} info
	${DOCKER} build --build-arg GOVERSION=${GOVERSION} --pull -t ${IMAGE}:${DK_VERSION} .

.PHONY: release
release: ## Tag and release the image
	@echo "release ${DK_VERSION}"
	${DOCKER} push ${IMAGE}:${DK_VERSION}

	@echo "tag and release latest"
	${DOCKER} pull ${IMAGE}:${DK_VERSION}
	${DOCKER} tag ${IMAGE}:${DK_VERSION} ${IMAGE}:latest
	${DOCKER} push ${IMAGE}:latest

# build manifest for git describe
# manifest version is "1.2.3-23ab3df"
# image version is "1.2.3-23ab3df"
# "1.14-23ab3df-20200315"
# "1.14"
# "latest"

.PHONY: release-multiarch
release-multiarch:
	@echo "building multi-arch docker images ${DK_VERSION}"
	${DOCKER} context create build-${GOVERSION}
	${DOCKER} buildx create --driver docker-container --use build-${GOVERSION}
	${DOCKER} buildx inspect --bootstrap
	${DOCKER} buildx ls
	${DOCKER} buildx build --build-arg GOVERSION=${GOVERSION} \
		--platform linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64 \
		--pull -t ${IMAGE}:${DK_VERSION} -t ${IMAGE}:${GOVERSION} -t ${IMAGE}:latest --push .
