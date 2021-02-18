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

## DNS Configuration

The DNS server configuration is not complicated, we have to edit the configuration file, and then we have to define our zone files. The configuration must be made, as always, inside the appropriate jail.  
We have to edit the `named` configuration file which is located in `/usr/local/etc/namedb/named.conf` like this:

```conf
acl goodclients { # A list of "good clients" in terms of which networks are allowed to query the DNS server
	192.168.1.0/24; # My local network
	192.168.177.0/24; # My jail network
	192.168.188.0/24; # My vm network
	localhost;
	localnets;
};
options{
...
  listen-on	{ 127.0.0.1; <your-jail-ip>; };
	notify yes;
	recursion yes;
  allow-recursion { goodclients; };
	forwarders { # We want to forward each unknown request to other dns services
		8.8.8.8; 
		8.8.4.4;
	};
 ...
}
```

Then we have to define our zones, first of all we have to add them to the configuration file:

```conf
...
options{
  .... # at the end of 
  zone <your-zone-name> {
    
  }
}
```
## Jail and Server Configuration

We want to install a local-authoritative DNS server so we have to configure the firewall and then each jail to rely on the newest DNS server.  
First of all we have to define the services on the firewall (bind is the name of my jail):  

```conf

...
ext_if = "<you-public-iface>"
bind_jail_ip = "<your-jail-ip>"
bind_jail_udp = "{ rndc, domain }"
bind_jail_tcp = "{ domain }"
....
rdr pass on $ext_if inet proto udp to port $bind_jail_udp -> $bind_jail_ip
rdr pass on $ext_if inet proto tcp to port $bind_jail_tcp -> $bind_jail_ip
```

Then we have to instruct each jail, the hosting machine, and each machine on the same network to use the defined DNS server. To do it you have to configure in `/etc/resolv.conf` the ip address of the jail/server depending on what device are you configuring (of course for Windows or Mac the configuration method is different). For example on a jail you have to define the resolv file like this:

```conf
search <your-base-domain>
nameserver <nameserver-jail-ip>
nameserver <another-fallback-dns>
```

Instead for the hosting server you have to configure the resolv file like this:

```conf
search <your-base-domain>
nameserver 127.0.0.1
nameserver <another-fallback-dns>
```

Then for another machine in your local area network:

```conf
search <your-base-domain>
nameserver <server-ip>
nameserver <another-fallback-dns>
```