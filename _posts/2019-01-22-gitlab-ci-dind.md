---
layout: post
title:  "A \"standard\" Gitlab CI template for Docker image build"
comments: true
categories: gitlab
---

# What is Docker

Nowadays [Docker](https://hub.docker.com/u/cmaiorano) is a standard de-facto for containers, every service which could be deployed on premise is "dockerized" and is also useful for service development; in fact it enables a near-zero time to configure the development environment.

Docker, which is explained very well in this [course](https://linuxacademy.com/devops/training/course/name/introduction-to-docker), is the first implementation of the [OCI standard](https://www.opencontainers.org/) (indeed Docker itself created the OCI), almost every container orchestration platform could use docker containers.

## Build your own Docker image

Tipically docker images were built using [Continuous integration](https://en.wikipedia.org/wiki/Continuous_integration) stages and/or pipelines.

In my department we use Gitlab as [SCM](https://www.wikiwand.com/en/Source_control_management) and we exploit also its [CI engine](https://about.gitlab.com/product/continuous-integration/), which is very adaptable to every use case (including molecule and devops tools, and also docker itself).

The Continuous Integration relies on [Runners](https://docs.gitlab.com/runner/), which could also use docker containers.

```yaml
image: golang:1.11 # For instance

variables:
  DOCKER_DRIVER: overlay2

# Add any test stage here

build_my_docker_image:
  image: docker:stable
  before_script:
  - docker info # not necessary
  services:
  - docker:dind
  script:
  - docker login $CI_REGISTRY -u $REGISTRY_USER -p $REGISTRY_PASSWORD
  - docker build -t $CI_REGISTRY/$CI_PROJECT_PATH .
  - docker push $CI_REGISTRY/$CI_PROJECT_PATH
```