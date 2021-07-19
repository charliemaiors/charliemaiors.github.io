---
layout: post
title:  "My Home CA with Smallstep CA"
comments: true
categories: freebsd
sharing:
  twitter: My Home CA with Smallstep CA
---
# My Home CA with Smallstep CA

During these days, forced at home by the pandemic, I have increased my experiments' difficulty. This time I've tried more in-depth [SmallStep CA](https://smallstep.com/docs/step-ca), the most automated, opensource, and powerful CA. Also, I took my [CKA Certification](https://wekan.lab.imolinfo.it/b/trDE2qoDNssL7hcqp/achilles-infrastructure/myNt8H9QE6dsaRjrF) so, I've decided to expand the surface of the experiment with this component exploiting also the [ACME](https://www.wikiwand.com/en/Automated_Certificate_Management_Environment) capability of the software.  

## Why Smallstep CA?

Typically if you want a simple and easy to use Certification Authority for your homelab you can rely on OpenSSL and a bunch of scripts, but I've casually intercepted the `step-ca` project and decided to try it.