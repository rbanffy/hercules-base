# Hercules Base Image

This is a base image that builds the latest version of Hercules. By itself it
does nothing - you are supposed to use it as a base image for a Hercules Docker
image.

## How do I use it?

Use it as a starting point for your Dockerfile:

```dockerfile
FROM rbanffy/hercules-base:stable
```

The tag "stable" is generated from the main branch. The tag "latest" is from
the "develop" branch. Other branches will generate tags named after the branch.
