# ansible-best-practices

[![Integration](https://github.com/computacenter-com/ansible-best-practices/actions/workflows/ci.yml/badge.svg)](https://github.com/computacenter-com/ansible-best-practices/actions/workflows/ci.yml) [![Deploy to Github pages](https://github.com/computacenter-com/ansible-best-practices/actions/workflows/cd.yml/badge.svg)](https://github.com/computacenter-com/ansible-best-practices/actions/workflows/cd.yml) [![Zensical Badge](https://img.shields.io/badge/Made_with_Zensical-orange?style=flat-square)](https://zensical.org/about/)

A collection of Best Practices for Ansible projects, published to [Github pages](https://computacenter-com.github.io/ansible-best-practices).  

## Contribution & Development

**To help us making the Best Practice Guide even better**, [open an issue](https://github.com/computacenter-com/ansible-best-practices/issues/new/choose) and/or take a look at our [Contributing Guidelines](.github/CONTRIBUTING.md), if you want to work on it yourself.  
The Guidelines also show you how to setup a [development environment](.github/CONTRIBUTING.md#create-development-environment).

## Manual build and deployment

The project contains the source files for a Zensical project, a *Containerfile* is provided which bundles all requirements and displays the resulting content in a webserver.

Clone the project and change into the base directory, afterwards build the image:

```bash
podman build -t best-practice-guide .
```

Start a container from the image, the webserver is available at Port 8080:

```bash
podman run -d -p 8080:8080/tcp --name ansible-guide best-practice-guide
```
