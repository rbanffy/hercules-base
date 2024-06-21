.PHONY: help archives build upload upload_images build
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

archives: hyperion-master.zip crypto-master.zip decNumber-master.zip SoftFloat-master.zip telnet-master.zip ## Zip files for the sources
	wget -c https://github.com/SDL-Hercules-390/hyperion/archive/refs/heads/master.zip -O hyperion-master.zip
	wget -c https://github.com/SDL-Hercules-390/crypto/archive/refs/heads/master.zip -O crypto-master.zip
	wget -c https://github.com/SDL-Hercules-390/decNumber/archive/refs/heads/master.zip -O decNumber-master.zip
	wget -c https://github.com/SDL-Hercules-390/SoftFloat/archive/refs/heads/master.zip -O SoftFloat-master.zip
	wget -c https://github.com/SDL-Hercules-390/telnet/archive/refs/heads/master.zip -O telnet-master.zip

build: archives build_amd64 build_arm64 build_armv7 build_s390x build_ppc64le ## Builds the Docker images

build_amd64:
	docker build -t ${USER}/hercules-base:${IMAGE_TAG}-amd64 --platform=linux/amd64 --progress=plain .

build_arm64:	
	docker build -t ${USER}/hercules-base:${IMAGE_TAG}-arm64 --platform=linux/arm64 --progress=plain .

build_armv6: archives ## Build the ARMv6 image.
	docker build --build-arg QEMU_CPU=arm1176 -t ${USER}/hercules-base:${IMAGE_TAG}-armv6 --platform=linux/arm/v6 --progress=plain .

build_armv7:
	docker build -t ${USER}/hercules-base:${IMAGE_TAG}-armv7 --platform=linux/arm/v7 --progress=plain .

build_s390x:
	docker build -t ${USER}/hercules-base:${IMAGE_TAG}-s390x --platform=linux/s390x --progress=plain .

build_ppc64le:
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
