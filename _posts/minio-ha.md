---
layout: post
title:  "Configure distributed Minio in multiple jail"
comments: true
categories: freebsd
sharing:
  twitter: Configure distributed Minio in multiple jail
---

# Configure distributed Minio in multiple jail

In the last period I've done a lot of experiments, on my FreeBSD powered nuc, like configuring the [DNS server](https://www.carlomaiorano.me/freebsd/2021/02/19/dns-freebsd-jail.html), deploy Homeassistant (I will also write about it), installed nginx-plus (I will also write an article on how-to obtain a development/home license), and last but not least deploy a [Minio cluster](https://docs.min.io/docs/distributed-minio-quickstart-guide.html).  
Ok, a Minio cluster on a single machine probably does not have any sense but I want to try how to configure it in order to understand it works.  
Regarding [MinIO](https://min.io/) is an implementation of the s3 API, which are a standard de-facto for object storage APIs, highly scalable and resilient. It allows also to host a static website or a dynamic one if the framework allows it (for instance [vuejs](https://medium.com/employbl/host-a-vue-js-website-on-amazon-s3-for-the-best-hosting-solution-ever-%EF%B8%8F-eee2a28b2506)).  

## Configure the environment

Minio for distributed deployment requires at least 4 drives up and running distributed among any number of replicas, in my deployment I've one drive per replica.  
After the deployment of four different jails (see the Define Jail section in this [article](https://www.carlomaiorano.me/freebsd/2019/02/18/openvpn-freebsd-jail.html)), you have to install MinIO in each of them, for instance (assuming that each jail is called minio-x, where x is a number):

```bash
for jail in `jls -v name | grep minio`;
    jexec $jail pkg bootstrap; pkg upgrade -y; pkg install -y minio;
end
```

