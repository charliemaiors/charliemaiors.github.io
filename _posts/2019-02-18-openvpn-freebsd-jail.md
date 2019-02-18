---
layout: post
title:  "OpenVPN in FreeBSD Jail"
comments: true
categories: freebsd
---

# FreeBSD and OpenVPN

FreeBSD [Jails](https://www.freebsd.org/doc/handbook/jails.html) are the first examples of containerization with [Solaris Zones](https://www.wikiwand.com/en/Solaris_Containers), followed by Docker, rkt, [Systemd-nspawn](https://wiki.archlinux.org/index.php/systemd-nspawn) and other [OCI](https://www.opencontainers.org) implementations.
The jails, IMHO, are the most effective and useful (with systemd-nspawn on the linux side) containerization technologies, because they allows to have daemons and more than one process per container relying on services (or systemd services) system providing automation and isolation at the same time.
A good usage of jails could be a VPN service, which is very sensitive and could compromise an entire system if is hijacked. In this artcle we will defined a jail with OpenVPN.

## Define jail

