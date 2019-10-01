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
