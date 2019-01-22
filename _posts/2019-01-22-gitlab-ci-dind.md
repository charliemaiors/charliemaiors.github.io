---
layout: post
title:  "A standard Gitlab CI template for Docker image build"
comments: true
categories: gitlab
---

# Introduction

Nowadays 

```yaml
image: docker:stable

variables:
  DOCKER_DRIVER: overlay2

# Add any test stage here

build:
  stage: build
  before_script:
  - docker info
  services:
  - docker:dind
  script:
  - docker login $CI_REGISTRY	 -u $REGISTRY_USER -p $REGISTRY_PASSWORD
  - docker build -t $CI_REGISTRY/$CI_PROJECT_PATH .
  - docker push $CI_REGISTRY/$CI_PROJECT_PATH
```