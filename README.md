# Hercules Base Image

This is a base image that builds the latest version of Hercules. By itself it
does nothing - you are supposed to use it as a base image for a Hercules Docker
image.

## How do I use it?

Use it as a starting point for your Dockerfile:

```dockerfile
FROM rbanffy/hercules-base:stable
```

or, you feel adventurous:

```dockerfile
FROM rbanffy/hercules-base:latest
```

The tag "stable" is generated from the main branch. The tag "latest" is from
the "develop" branch. Other branches will generate tags named after the branch.

## How do I build the images?

You'll need Docker buildx and the QEMU environment set up properly (with
armv6l, armv7l, arm64, ppc64le, and s390x). Then use `make build` to build
local copies. Use `make help` or `make` to show a listing of targets and a
description.