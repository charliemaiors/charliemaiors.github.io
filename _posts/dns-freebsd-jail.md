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