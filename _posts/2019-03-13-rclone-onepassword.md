---
layout: post
title:  "Using 1password as backup for application configurations: Rclone"
comments: true
categories: ansible
sharing:
  twitter: "Using 1password as backup for application configurations: Rclone"
  facebook: "Using 1password as backup for application configurations: Rclone"
  linkedin: "Using 1password as backup for application configurations: Rclone"
---

# Introduction

1password is the industry leader for secure content management, starting from passwords and login to documents and secure notes. It offers a lot of client applications, like mobile for Android and iOS, Windows, macOS and include also a command line interface. Personally my security relies completely on 1password for password, software licenses, configuration, [2FA](https://www.wikiwand.com/en/Multi-factor_authentication) and everything tied with security for work and personal stuff.
I was also interested in using the CLI on OS with command line only (like my freebsd box) or linux in order to have all my passwords and also have a secure way to retrieve my configuration with sensitive data. For instance I use a lot [Rclone](https://rclone.org/) as all-cloud-sync client. Rclone is a rsync client (CLI only) for cloud storages, it allows to sync, copy files between cloud storage and local machine or cloud-to-cloud; there is also a project called rclone-browser for users which want always a GUI (personally I'm fine with the CLI).
Rclone relies on a configuration file located tipically in the user home directory, in this file the application saves (encrypted) all the configuration for each cloud storage (called remote); this file is perfectly portable between OSes and versions so it can be backupped in a safe place, for instance in 1password as document.

## Automation 

Personally every new box which I deploy for development purposes I use rclone to sync all produced data to object storage like swift or s3 or personal cloud provider, I've also developed an [ansible role](https://galaxy.ansible.com/charliemaiors/rclone-ansible) to automatic deploy rclone on new boxes (even macos and windows) and manually copy my configuration file to new installation.

Since when ansible introduced the [```onepassword_facts``` module](https://docs.ansible.com/ansible/latest/modules/onepassword_facts_module.html) I've finished the automation part regarding rclone.

Using delegation I've configured the ansible host machine with ```op``` binary properly configured to login on my 1password account.

Below you can find the playbook used to automatically install and configure rclone:

```yaml
- name: Install rclone and configure it using 1password
  hosts: rclone
  become_method: sudo # Testing on a cloud VPS tipically the user has NOPASSWD for sudo
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
Now we will examine the main parts of the playbook:

```yaml
 roles:
    - { role: charliemaiors.rclone_ansible, become: true }
```

This is pretty straightforward, uses a predefined role deployed on the ansible galaxy to install rclone.

```yaml
 - name: Take the rclone configuration
      onepassword_facts:
        search_terms: "{{ onepassword_rclone_config }}"  # Assuming that you have already run op signin...
      delegate_to: localhost
      no_log: true
```

This task will interrogate you onepassword account, relying on the ```op``` binary, for the rclone configuration document. The ```delegate_to: localhost``` delegate the task execution to the host machine using its resources (again the ```op``` binary above all).
Using ```onepassword_facts``` without any login advice assumes that you have already logged in to 1password cli using ```op signin ...```. Of course you want to avoid to dump all your rclone configuration on log file and standard out so ```no_log``` is set to ```true```.

```yaml
- name: Get the location of the config file
      shell: 'rclone config file | grep -v "Configuration file*"'
      args:
        executable: /bin/bash
      register: config_file
```
This snippet is an "hack" in order to retrieve the configuration file location, the grep part of the command must be substituted with ```Select-String -NotMatch "Configuration file*"``` on Windows and the task must be a ```win_shell```.

```yaml
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
```

These tasks creates the necessary directory and configuration file if they don't exists. The last task creates the rclone file empty because the ```copy``` module will fail if the file does not exist.

```yaml
- name: Create the rclone config
      copy:
        dest: "{{ config_file.stdout }}"
        content: "{{ item.value.document }}" # One Document
      with_dict: "{{ onepassword }}"
      no_log: true # Otherwise the configuration will be printed to stdout
```

The last task will copy the retrieved configuration to the rclone configuration file. The ```onepassword_facts``` module will produce a dictionary with using the search term as key and the tuple \<field:value\> as value, so to retrieve the value of the document you have to use ```"{{ item.value.document }}"``` as value for the ```content``` field of the copy module. Is obvious that the copy module will produce an output with the value of the dictionary so the ```no_log``` is mandatory.

## Conclusion

This playbook can be easly declined to every service which stores configuration in a predefined place, but must be take into account the "overhead" of this procedure.

### Note

The playbook is available on Github: [https://github.com/charliemaiors/ansible-onepassword](https://github.com/charliemaiors/ansible-onepassword).