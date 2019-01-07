---
layout: post
title:  "FreeBSD Image for Openstack"
categories: freebsd
---

# Introduction

My job as research grant includes also some system and cluster administration, install and maintain an [Openstack Cluster](https://www.openstack.org/) among them. The Openstack cluster is for research purposes and all relevant services are configured, the cluster offer also a lot of different OS images like Windows, and various Linux distributions. All of these images could be found from distributions main page, or can be built like the [Windows Server/10](https://cloudbase.it/windows-cloud-images/); inside the lab we use also *BSD distributions as server systems and I've noticed that FreeBSD image for Openstack was not available.
I've followed a lot of articles where you can create a FreeBSD image for Openstack using the [BSDCloudInit](https://pellaeon.github.io/bsd-cloudinit/), but the images didn't boot or start properly; then I looked at a [bug report](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=213396) on FreeBSD bugzilla and found some configuration made by [Diego Casati](https://diegocasati.com/) and I've take these files and tried to improve them.
The entire process relies on [release(7)](https://www.freebsd.org/cgi/man.cgi?release(7)) build process.

# Prerequisites

In order to build properly the image is necessary to have ```src``` component installed and the ```openstack cli``` variables properly configured (for configuration params see this [website](https://docs.openstack.org/newton/user-guide/common/cli-set-environment-variables-using-openstack-rc.html)) to interact with your Openstack Cluster.

# Installation

Go to the [FreeBSD-Image releases](https://github.com/charliemaiors/freebsd-openstack-image/releases/latest) and fetch it using ```fetch <latest-release-url>```, then untar it using ```tar -C /usr/src/release -xvf openstack.tar.xz```.

After move to ```/usr/src``` folder and compile the userland and the kernel running ```make -j <proc_num> buildworld buildkernel```, and grab a coffee.

When the compilation is done move to the ```/usr/src/release``` folder and run: ```make cloudware-release WITH_CLOUDWARE=yes CLOUDWARE=OPENSTACK```, and grab another coffee.

When everything is done run: ```make openstack-upload``` to upload the image to your Openstack Cluster.

Then run ```openstack server create --image FreeBSD-<your-FreeBSD-version> <server-params> <server-name>``` in order to run it on your cluster.

# Customization

You can add packages and/or services before create the image adding params to the ```openstack.conf``` file in ```/usr/src/release/tools/``` folder.

For extra packages you have to add the ports name or the package name to ```VM_EXTRA_PACKAGES```. For instance add ```python2.7``` package in order to be compatible with [Ansible](https://www.ansible.com/)

For extra services add the service name to ```VM_RC_LIST```. For instance add ```jail``` in order to have jail service enabled at boot.

# Known issues

The current release (v1.1) will boot and work properly but the logs on horizon are not available.