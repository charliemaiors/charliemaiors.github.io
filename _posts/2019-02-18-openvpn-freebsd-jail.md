---
layout: post
title:  "OpenVPN in a FreeBSD Jail"
comments: true
categories: freebsd
sharing:
  twitter: OpenVPN in a FreeBSD Jail
  facebook: OpenVPN in a FreeBSD Jail
  linkedin: OpenVPN in a FreeBSD Jail
---

# FreeBSD and OpenVPN

FreeBSD [Jails](https://www.freebsd.org/doc/handbook/jails.html) are the first examples of containerization with [Solaris Zones](https://www.wikiwand.com/en/Solaris_Containers), followed by Docker, rkt, [Systemd-nspawn](https://wiki.archlinux.org/index.php/systemd-nspawn) and other [OCI](https://www.opencontainers.org) implementations.
The jails, IMHO, are the most effective and useful (with systemd-nspawn on the linux side) containerization technologies, because they allows to have daemons and more than one process per container relying on services (or systemd services) system providing automation and isolation at the same time.
A good usage of jails could be a VPN service, which is very sensitive and could compromise an entire system if is hijacked. In this artcle we will defined a jail with OpenVPN.

## Define jail

There are several methods to create a new jail:

* Using base system archives, or building from source as explained in the [handbook](https://www.freebsd.org/doc/handbook/jails-build.html)
* Using a base jail and expand from it (also using VTNET for FreeBSD < 12.0) as explained in [nixcraft](https://www.cyberciti.biz/faq/how-to-configure-a-freebsd-jail-with-vnet-and-zfs/)
* Using ezjail, always from [handbook](https://www.freebsd.org/doc/handbook/jails-ezjail.html);
* Using [iocage](https://github.com/iocage/iocage), a newer jail handler written in python;

I prefer using ```src``` method and compile the base system (and also the kernel) in order to have a userland synced with the kernel. In order to have a new jail I will (assuming that you have already in place networking, firewall and jail configuration file):

* Create the directory (use also a different zfs dataset or even pool with a given mountpoint) ```mkdir <jail-root>/<new-jail-name>```
* Install the new jail ```setenv D <path-to-jail>```, then run ```make installworld DESTDIR=$D``` and ```make distribution DESTDIR=$D```
* Add your new defined jail to your jail configuration file
* Run it ```service jail start <jail-name>```

### Extra Jail configuration for OpenVPN

OpenVPN in a jail requires extra configuration to work, because it uses a tun device for network routing:

* Create a tun device on the host, this can be done in two ways:

  * Add to rc.conf ```cloned_interfaces="tun"``` (or simply add tun if you have already a cloned interface), ```ifconfig_tun="10.8.0.0/24"``` and restart the network and routing service ```service netif restart && service routing restart``
  * Run ```ifconfig tun create``` (the output will be tun0), ```ifconfig tun0 inet 10.8.0.2 10.8.0.1 netmask 255.255.255.0``` and ```ifconfig tun0 up```
* Create a devfs ruleset for the jail, mine is:

  ```bash
  [devfsrules_jail_vpn=5]
  add include $devfsrules_hide_all
  add include $devfsrules_unhide_basic
  add include $devfsrules_unhide_login
  add path 'tun*' unhide
  add path zfs unhide
  ```

* Apply the ruleset to your jail section, plus a network configuration for the tun device in the jail configuration file, this is the snippet of my file:

  ```bash
  ...  
  devfs_ruleset = "5";
  ip4.addr += "tun0|10.8.0.1 10.8.0.2 netmask 255.255.255.0";
  exec.prestart = "route add -net 10.8.0.0/24 10.8.0.2";
  ...
  ```

* Configure your firewall, ipfw or pf, to forward the openvpn port to the jail and handle the tun interface, I've used pf:

  ```bash
  ext_if="em0"
  tun_if="tun0"
  openvpn_jail_ip = "<jail-ip>"
  ...
  tun_net="10.8.0.0/24"
  ...
  openvpn_jail_udp = "{ openvpn }" # is in /etc/services
  nat on ! $tun_if from $tun_net to any -> $ext_if
  ...
  pass quick on $tun_if
  ...
  ```

* Then reload your firewall (if needed)

## Configure the Jail

After this preliminary configuration we can work with the jail running ```jls``` to find which is the jid of the OpenVPN jail, then run ```jexec <jid> tcsh```. 
Inside the jail run:

* ```pkg bootstrap```, to bootstrap the pkg service and install OpenVPN from that, or ```portsnap fetch extract``` if you want to use ports.
* Install (or compile) OpenVPN: ```pkg install -y openvpn```, this will install also ```easyrsa```
* Copy the easy-rsa folder inside the OpenVPN folder running: ```cp -r /usr/local/share/easy-rsa /usr/local/etc/openvpn/easy-rsa``` and move into it ```cd /usr/local/etc/openvpn/easy-rsa```

Now we will define our Certification Authority using ```easyrsa```. You can replace the usage of easyrsa executable inside the copied folder with the one available system wide setting the variable ```setenv EASYRSA=/usr/local/etc/openvpn/easy-rsa```. The steps needed to create the PKI are:

* Edit the ```vars``` file for default values according to your organization:

  ```conf
  set_var EASYRSA_REQ_COUNTRY     "Whatever"
  set_var EASYRSA_REQ_PROVINCE    "Whatever"
  set_var EASYRSA_REQ_CITY        "Whatever"
  set_var EASYRSA_REQ_ORG         "Whatever"
  set_var EASYRSA_REQ_EMAIL       "Whatever@Whatever.com"
  set_var EASYRSA_REQ_OU          "Nobody"
  
  set_var EASYRSA_KEY_SIZE        384 (or 2048/4096 in   case of RSA)
  
  set_var EASYRSA_ALGO            ec (could be also rsa)
  set_var EASYRSA_CURVE           secp384r1 (only in   case of EASYRSA_ALGO=ec)
  
  set_var EASYRSA_CA_EXPIRE       3650
  ```

* The create the Public Key Infrastructure (pki): ```/easyrsa.real init-pki```
* Build your ca: ```./easyrsa.real build-ca```
* Build the server certifcate: ```./easyrsa.real build-server-full server nopass```
* Generate the Diffie Hellman params: ```./easyrsa.real gen-dh```
* Generate  the OpenVPN TLS Authentication key: ```openvpn --genkey --secret ta.key```

Now we will configure the OpenVPN server:

* Copy the sample configuration for the OpenVPN server:
```cp /usr/local/share/examples/openvpn/sample-config-files/server.conf /usr/local/etc/openvpn/server.conf```
* Edit the file, in particular add (or replace):

  ```conf
  ...
  dev tun0
  ca /usr/local/etc/openvpn/easy-rsa/pki/ca.crt
  cert /usr/local/etc/openvpn/easy-rsa/pki/issued/server.crt  
  key /usr/local/etc/openvpn/easy-rsa/pki/private/server.key  # This file should be kept secret
  dh /usr/local/etc/openvpn/easy-rsa/pki/dh.pem
  ...
  push "route <physical-net> 255.255.255.0"
  ...
  push "redirect-gateway def1 bypass-dhcp" # if you want to use the VPN for traffic redirecting
  push "dhcp-option DNS 8.8.8.8" # DNS 1
  push "dhcp-option DNS 8.8.4.4" # DNS 2
  tls-auth /usr/local/etc/openvpn/easy-rsa/ta.key 0 # This file is secret
  ifconfig-noexec # to avoid tun reconfiguration which will cause a failure
  ```

* Enable the service and configure it adding in ```/etc/rc.conf``` the following lines:

  ```conf 
  openvpn_enable="YES"
  openvpn_if="tun"
  openvpn_configfile="/usr/local/etc/openvpn/server.conf"
  openvpn_dir="/usr/local/etc/openvpn/"
  ```

* Run the service ```service openvpn start``` (NOTE: if it fails run on the host system ```ifconfig tun0 inet 10.8.0.2 10.8.0.1``` only for the first time)
* Generate the client credentials, I've created a set of script to create the base configuration and then generate each client ovpn file. You can clone the running: ```git clone https://cmaiorano@bitbucket.org/cmaiorano/openvpn-client-generator.git```
* Move into directory: ```cd openvpn-client-generator/```
* Run ```./generate-base-conf.sh``` for the first time, then for each client run ```./generate-client.sh <client-name>```.
* You can also revoke a client certificate running ```./revoke-client.sh```, it will also generate a crl and add it to your openvpn server configuration, then you have to reload the service.

Now if everything went right you can enjoy you OpenVPN server inside a FreeBSD jail.