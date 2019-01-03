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

In order to build properly the image is 