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

## Automation 

Personally every new box which I deploy for development purposes I use rclone to sync all produced data to object storage like swift or s3 or personal cloud provider, I've also developed an [ansible role](https://galaxy.ansible.com/charliemaiors/rclone-ansible) to automatic deploy rclone on new boxes (even macos and windows) and manually copy my configuration file to new installation.

Since when ansible introduced the [```onepassword_facts``` module](https://docs.ansible.com/ansible/latest/modules/onepassword_facts_module.html) I've finished the automation part regarding rclone. Below you can find the playbook used to automatically install and configure rclone:

```yaml
- name: Install rclone and configure it using 1password
  hosts: rclone
  become_method: sudo
  vars:
    onepassword_rclone_config: "doc-of-rclone-config"
  roles:
    - { role: charliemaiors.rclone_ansible, become: true }
  tasks:
    - name: Take the rclone configuration
      onepassword_facts:
        search_terms: "{{ onepassword_rclone_config }}"  # Assuming that you have already run op signin...
      delegate_to: localhost
      no_log: true
    - name: Get the location of the config file
      shell: 'rclone config file | grep -v "Configuration file*"'
      args:
        executable: /bin/bash
      register: config_file
    - name: Check if rclone config directory exist
      stat:
        path: "{{ config_file.stdout | dirname }}"
      register: create_folder
    - name: Check if the rclone.conf file exist
      stat:
        path: "{{ config_file.stdout }}"
      register: touch_file
    - name: Create directory for rclone config if not exist
      file:
        path: "{{ config_file.stdout | dirname }}"
        state: directory
      when: not create_folder.stat.exists
    - name: Touch rclone file if the folder does not exist
      file:
        path: "{{ config_file.stdout }}"
        state: touch
      when: not touch_file.stat.exists
    - name: Create the rclone config
      copy:
        dest: "{{ config_file.stdout }}"
        content: "{{ item.value.document }}" # One Document
      with_dict: "{{ onepassword }}"
      no_log: true # Otherwise the configuration will be printed to stdout
```
