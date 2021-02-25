---
layout: post
title:  "How to obtain a development license for Nginx Plus"
comments: true
categories: nginx
sharing:
  twitter: How to obtain a development license for Nginx Plus
---

# Why test Nginx Plus?

Nowadays Nginx is one of the most popular web server/reverse proxy and  loadbalancer, let alone as Ingress/IngressController on Kubernetes which was one of the first implementations and the most used.  
Nginx offers (among the other products) is tiered in 2 levels: the open source, and the plus implementation.  
The Plus implementation offers, beyond the functionalities offered by the open source version, many other interesting features (for a more detailed comparison look at [this comparison](https://www.nginx.com/products/nginx/compare-models)):

* Active/Passive application health checking
* Activity monitoring
* Advanced Loadbalancing
* Reconfiguration on-the-fly
* Extended logging capabilities
* Adaptive media streaming
* High availability setup  

I've tried the healthcheck feature on the minio cluster (check the [article](https://www.carlomaiorano.me/freebsd/2021/02/21/minio-ha.html)), and also the dashboard to check the current state of the web server. I'm also planning to test the extended logging and the high availability setup.  

## Ask for a license

The license is available **ONLY** for side **NON**-commercial projects. In order to request the license you have to send an email to the [devsupport](mailto:devsupport@nginx.com?subject=Nginx%20Plus%20dev%20license) explaining why you need a dev license; I wrote a few lines about what I'm doing and one sentence on what I want to do with the Plus version of Nginx.  
After a while (some days) you will receive a code that must be filled in the [developer license portal](https://www.nginx.com/developer-license/).

![The developer porta](/assets/img/portalpng.png)

After that you will receive a mail with an activation URL to download the key for the license. To install Nginx Plus on your distribution (Nginx Plus is a different package from Nginx open source), check the [repo_setup](https://cs.nginx.com/repo_setup) site.  

## Conclusions

Nginx Plus has many interesting features and the Nginx's dev support is very kind to provide a free license for home/side projects.