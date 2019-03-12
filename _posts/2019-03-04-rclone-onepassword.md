---
layout: post
title:  "Using 1password as backup for application configurations: Rclone"
comments: true
categories: ansible
---

# Introduction

1password is the industry leader for secure content management, starting from passwords and login to documents and secure notes. It offers a lot of client applications, like mobile for Android and iOS, Windows, macOS and include also a command line interface. Personally my security relies completely on 1password for password, software licenses, configuration, [2FA](https://www.wikiwand.com/en/Multi-factor_authentication) and everything tied with security for work and personal stuff.
I was also interested in using the CLI on OS with command line only (like my freebsd box) or linux in order to have all my passwords and also have a secure way to retrieve my configuration with sensitive data. For instance I use a lot [Rclone](https://rclone.org/) as all-cloud-sync client. Rclone is a rsync client (CLI only) for cloud storages, it allows to sync, copy files between cloud storage and local machine or cloud-to-cloud; there is also a project called rclone-browser for users which want always a GUI (personally I'm fine with the CLI).
Rclone relies on a configuration file located tipically in the user home directory, in this file the application saves (encrypted) all the configuration for each cloud storage (called remote); this file is perfectly portable between OSes and versions so it can be backupped in a safe place, for instance in 1password as document.

