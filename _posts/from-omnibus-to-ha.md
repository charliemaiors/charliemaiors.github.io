---
layout: post
title:  "My journey with Gitlab, from AIO Omnibus to HA"
comments: true
categories: gitlab
sharing:
  twitter: My journey with @gitlab, from AIO Omnibus to HA
---

# My journey with Gitlab

When I was a research grant at the university we had a problem with SCM, we rely on an old SVN server with all the projects on it and we want to migrate to git. Among the differents on-premise offers (like [Gogs](https://gogs.io/), [Bitbucket server](https://it.atlassian.com/software/bitbucket/download)) we choose [Gitlab](https://about.gitlab.com/) because was (and is) the best on premise SCM solution (and IMHO is growing up quickly also on cloud).
I had a spare bare metal machine, see [figure](optiplex) where I can make all the experiments that I want.

![optiplex](/assets/img/optiplex.jpg "The spare machine")

So I've decided to install the [Omnibus](https://docs.gitlab.com/omnibus/) package on that machine (which was running [Ubuntu](https://about.gitlab.com/install/#ubuntu) at the time), assigned a public IP and registered to a custom domain that we own (also for experiments).
My collegues started also to use it, migrating projects from the old SVN to the new server.

I've started to appreciate also other "side" functionalities, like [Docker](https://www.docker.com/) Registry 