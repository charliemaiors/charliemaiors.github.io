---
layout: post
title:  "Openstack RC for fish shell"
comments: true
categories: openstack
---

Openstack allows the user to interact its APIs using ```openstack-cli```, which requires a set of environment variables or [yaml files](https://docs.openstack.org/python-openstackclient/pike/configuration/index.html). With yaml you can configure more than one Cluster (also public ones), with environment variables is possible to administrate only one cluster at time.

Through the [dashboard](https://docs.openstack.org/horizon/latest/) you can download the ```keystone_<project>_rc``` file (for instance ```keystone_admin_rc```) which is a pure ```bash``` compliant script; my favourite shell, instead, is ```fish``` so I had to adapt the script in order to be compliant with fish standards.

Below there is a snippet of adapted rc file.

```fish
set -e OS_SERVICE_TOKEN
set -gx OS_USERNAME user
set -gx OS_PASSWORD 'mypass'
set -gx OS_AUTH_URL <openstack-auth-url>

set -gx OS_PROJECT_NAME project
set -gx OS_USER_DOMAIN_NAME Domain
set -gx OS_PROJECT_DOMAIN_NAME Domain
set -gx OS_IDENTITY_API_VERSION 3
```