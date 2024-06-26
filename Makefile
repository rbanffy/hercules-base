.PHONY: help build upload upload_images
.DEFAULT_GOAL := help

SHELL = /bin/sh

BRANCH = $(shell git branch --show-current)

ifeq ($(BRANCH),main)
	IMAGE_TAG = latest
else
	IMAGE_TAG = $(BRANCH)
endif

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

help: ## Displays this message.
	@echo "Please use \`make <target>' where <target> is one of:"
	@python3 -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

build: ## Builds the Docker images
	docker build -t ${USER}/hercules-base:${IMAGE_TAG}-amd64 --platform=linux/amd64 --progress=plain .
	docker build -t ${USER}/hercules-base:${IMAGE_TAG}-arm64 --platform=linux/arm64 --progress=plain .
	docker build -t ${USER}/hercules-base:${IMAGE_TAG}-armv7 --platform=linux/arm/v7 --progress=plain .
	docker build -t ${USER}/hercules-base:${IMAGE_TAG}-s390x --platform=linux/s390x --progress=plain .
	docker build -t ${USER}/hercules-base:${IMAGE_TAG}-ppc64le --platform=linux/ppc64le --progress=plain .

upload_images: ## Uploads the docker images
	docker image push ${USER}/hercules-base:${IMAGE_TAG}-amd64
	docker image push ${USER}/hercules-base:${IMAGE_TAG}-arm64
	docker image push ${USER}/hercules-base:${IMAGE_TAG}-armv7
	docker image push ${USER}/hercules-base:${IMAGE_TAG}-s390x
	docker image push ${USER}/hercules-base:${IMAGE_TAG}-ppc64le

upload: upload_images ## Uploads the manifest
	docker manifest create ${USER}/hercules-base:${IMAGE_TAG} \
		--amend ${USER}/hercules-base:${IMAGE_TAG}-amd64 \
		--amend ${USER}/hercules-base:${IMAGE_TAG}-arm64 \
		--amend ${USER}/hercules-base:${IMAGE_TAG}-armv7 \
		--amend ${USER}/hercules-base:${IMAGE_TAG}-s390x \
		--amend ${USER}/hercules-base:${IMAGE_TAG}-ppc64le
	docker manifest push ${USER}/hercules-base:${IMAGE_TAG}
