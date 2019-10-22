#
#  Makefile
#

export SHELL ?= /bin/bash
include make.cfg

MK_VERSION := $(shell git describe --always --tags --dirty)
MK_HASH := $(shell git rev-parse --short HEAD)
MK_DATE := $(shell date -u +%Y-%m-%dT%H:%M:%SZ)

IMAGE_NAME := ${REGISTRY_URL}/${OWNER}/${PROJECT_NAME}
IMAGE_TAG := ${IMAGE_NAME}:${MK_HASH}
RELEASE_TAG := ${IMAGE_NAME}:${MK_VERSION}
LATEST_TAG := ${IMAGE_NAME}:latest

IMAGE := ${REGISTRY_URL}/${OWNER}/${PROJECT_NAME}
DK_VERSION = $(shell git describe --always --tags | sed 's/^v//' | sed 's/-g/-/')

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
	@echo "building ${IMAGE_TAG}"
	${DOCKER} info
	${DOCKER} build  --pull -t ${IMAGE_TAG} .

.PHONY: release
release: ## Tag and release the image
	@echo "release ${IMAGE_TAG}"
	${DOCKER} push ${IMAGE_TAG}

	@echo "tag and release ${RELEASE_TAG}"
	${DOCKER} pull ${IMAGE_TAG}
	${DOCKER} tag ${IMAGE_TAG} ${RELEASE_TAG}
	${DOCKER} push ${RELEASE_TAG}

	@echo "tag and release ${LATEST_TAG}"
	${DOCKER} pull ${IMAGE_TAG}
	${DOCKER} tag ${IMAGE_TAG} ${LATEST_TAG}
	${DOCKER} push ${LATEST_TAG}

.PHONY: release-version
release-version: ## Release a tagged image
	@echo "tag and release ${RELEASE_TAG}"
	${DOCKER} pull ${IMAGE_TAG}
	${DOCKER} tag ${IMAGE_TAG} ${RELEASE_TAG}
	${DOCKER} push ${RELEASE_TAG}


release-docker-%:
	@echo "building '${DK_TAG}' docker image"
	${DOCKER} build --pull -t ${IMAGE}:${DK_TAG} .
	${DOCKER} push ${IMAGE}:${DK_TAG}

release-docker-amd64: DK_TAG=${DK_VERSION}-amd64
release-docker-arm32v6: DK_TAG=${DK_VERSION}-arm32v6
release-docker-arm32v7: DK_TAG=${DK_VERSION}-arm32v7
release-docker-arm64v8: DK_TAG=${DK_VERSION}-arm64v8

.PHONY: release-manifest
release-manifest:  ## build and push all of docker images
	@echo "building docker manifest"
	${DOCKER} manifest create ${IMAGE}:${DK_VERSION} ${IMAGE}:${DK_VERSION}-amd64 ${IMAGE}:${DK_VERSION}-arm32v6 ${IMAGE}:${DK_VERSION}-arm32v7 ${IMAGE}:${DK_VERSION}-arm64v8
	${DOCKER} manifest annotate ${IMAGE}:${DK_VERSION} ${IMAGE}:${DK_VERSION}-arm32v6 --os linux --arch arm --variant v6
	${DOCKER} manifest annotate ${IMAGE}:${DK_VERSION} ${IMAGE}:${DK_VERSION}-arm32v7 --os linux --arch arm --variant v7
	${DOCKER} manifest annotate ${IMAGE}:${DK_VERSION} ${IMAGE}:${DK_VERSION}-arm64v8 --os linux --arch arm64 --variant v8
	${DOCKER} manifest push ${IMAGE}:${DK_VERSION}
	# ${DOCKER} pull ${IMAGE}:${DK_VERSION}
	# ${DOCKER} tag ${IMAGE} latest
	# ${DOCKER} push latest

# build manifest for git describe
# manifest version is "1.2.3-23ab3df"
# image version is "1.2.3-23ab3df-amd64"

.PHONY: release-buildkit
release-buildkit:
	@echo "building docker ${DK_VERSION}"
	docker buildx create --driver docker-container --use
	docker buildx inspect --bootstrap
	docker buildx ls
	docker buildx build --platform linux/arm32v6,linux/arm32v7,linux/arm64v8,linux/amd64 --pull -t ${IMAGE}:${DK_VERSION} -t ${IMAGE}:latest push .
