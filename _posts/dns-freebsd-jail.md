---
layout: post
title:  "Configure a local authoritative DNS in FreeBSD Jail"
comments: true
categories: freebsd
sharing:
  twitter: Configure a local authoritative DNS in FreeBSD Jail
---

# An authoritative DNS jailed

Since when I installed my FreeBSD box I've tried a lot of different services/servers, each one of them is [jailed](https://www.freebsd.org/doc/handbook/jails.html).  
Starting with a simple vpn service based on OpenVPN, till a "local-authoritative" DNS server; which could be useful in a home environment, tipically statically served in terms of IP allocation.

## Environment preparation

First of all a new jail must be settled up (see the [Define Jail](https://www.carlomaiorano.me/freebsd/2019/02/18/openvpn-freebsd-jail.html) part of the OpenVPN post), then we can proceed to the jail initialization and configuration.  
You can find a some hints on the [OpenVPN guide](https://www.carlomaiorano.me/freebsd/2019/02/18/openvpn-freebsd-jail.html) to setup the jail, then we have to connect to it and bootstrap all the necessary systems. First of all we have to connect to the already defined jail using `jexec <jail-name> tcsh`, then we have to bootstrap the package manger `pkg bootstrap && pkg upgrade -y` and then we can start to install packages.  
I've used [`bind9`](https://wiki.debian.org/Bind9) as DNS server because is the most reliable and RFC compliant DNS server nowadays, and also is the most well-documented and *nix compliant server.  
We have to install the `bind9` package using: `pkg install -y bind9`, then we have to enable it in `/usr/local/etc/rc.conf` manually (or using `echo 'named_enable="YES"' >> /usr/local/etc/rc.conf`), or delegating to the `sysrc` system tool running `sysrc named_enable="YES"`.  

## Jail and Server Configuration

We want to install a local-authoritative DNS server so we do


## Host Configuration