.PHONY: help build build_amd64 build_arm64 build_armv6 build_armv7 build_ppc64le build_s390x upload upload_images 
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
	match = re.match(r'^([a-zA-Z0-9_-]+):.+?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

help: ## Display this message.
	@echo "Please use \`make <target>' where <target> is one of:"
	@python3 -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

clean: ## Delete downloaded archives.
	rm -v hyperion-master.zip crypto-master.zip decNumber-master.zip SoftFloat-master.zip telnet-master.zip

archives: hyperion-master.zip crypto-master.zip decNumber-master.zip SoftFloat-master.zip telnet-master.zip ## Download files for the sources

hyperion-master.zip:
	wget -c https://github.com/SDL-Hercules-390/hyperion/archive/refs/heads/master.zip -O hyperion-master.zip

crypto-master.zip:
	wget -c https://github.com/SDL-Hercules-390/crypto/archive/refs/heads/master.zip -O crypto-master.zip

decNumber-master.zip:
	wget -c https://github.com/SDL-Hercules-390/decNumber/archive/refs/heads/master.zip -O decNumber-master.zip

SoftFloat-master.zip:
	wget -c https://github.com/SDL-Hercules-390/SoftFloat/archive/refs/heads/master.zip -O SoftFloat-master.zip

telnet-master.zip:
	wget -c https://github.com/SDL-Hercules-390/telnet/archive/refs/heads/master.zip -O telnet-master.zip

build: build_amd64 build_arm64 build_armv7 build_s390x build_ppc64le ## Build the Docker images.

build_amd64: archives ## Build the AMD64 image.
	docker build -t ${USER}/hercules-base:${IMAGE_TAG}-amd64 --platform=linux/amd64 --progress=plain .

build_arm64: archives ## Build the ARM64 image.
	docker build -t ${USER}/hercules-base:${IMAGE_TAG}-arm64 --platform=linux/arm64 --progress=plain .

build_armv6: archives ## Build the ARMv6 image.
	docker build --build-arg QEMU_CPU=arm1176 -t ${USER}/hercules-base:${IMAGE_TAG}-armv6 --platform=linux/arm/v6 --progress=plain .

build_armv7: archives ## Build the ARMv7 image.
	docker build -t ${USER}/hercules-base:${IMAGE_TAG}-armv7 --platform=linux/arm/v7 --progress=plain .

build_s390x: archives ## Build the s390x image.
	docker build -t ${USER}/hercules-base:${IMAGE_TAG}-s390x --platform=linux/s390x --progress=plain .

build_ppc64le: archives ## Build the PPC64el image.
	docker build -t ${USER}/hercules-base:${IMAGE_TAG}-ppc64le --platform=linux/ppc64le --progress=plain .

upload_images: ## Upload the docker images.
	docker image push ${USER}/hercules-base:${IMAGE_TAG}-amd64
	docker image push ${USER}/hercules-base:${IMAGE_TAG}-arm64
	docker image push ${USER}/hercules-base:${IMAGE_TAG}-armv7
	docker image push ${USER}/hercules-base:${IMAGE_TAG}-s390x
	docker image push ${USER}/hercules-base:${IMAGE_TAG}-ppc64le

upload: upload_images ## Upload the manifest.
	docker manifest create ${USER}/hercules-base:${IMAGE_TAG} \
		--amend ${USER}/hercules-base:${IMAGE_TAG}-amd64 \
		--amend ${USER}/hercules-base:${IMAGE_TAG}-arm64 \
		--amend ${USER}/hercules-base:${IMAGE_TAG}-armv7 \
		--amend ${USER}/hercules-base:${IMAGE_TAG}-s390x \
		--amend ${USER}/hercules-base:${IMAGE_TAG}-ppc64le
	docker manifest push ${USER}/hercules-base:${IMAGE_TAG}
