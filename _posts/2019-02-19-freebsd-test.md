---
layout: post
title:  "Continuous integration for FreeBSD Ansbile Roles with molecule"
comments: true
categories: freebsd
---

# Introduction

The modern software engineering, in order to find any bug before they appear in production, uses [CI/CD](https://it.atlassian.com/continuous-delivery/principles/continuous-integration-vs-delivery-vs-deployment) paradigm. This paradigm could be also applied to Ansible roles and playbooks, for instance using [molecule](https://molecule.readthedocs.io/en/latest/) the developer could test an Ansible role.

## FreeBSD in CI

Currently there are not any support for FreeBSD in the "public" CI/CD engines, unless you have your own Jenkins cluster (with FreeBSD slave) or Gitlab CI/CD with a FreeBSD Runner. Also there aren't any docker image for FreeBSD (is a unix distribution, and the docker project over FreeBSD is stuck at version 1.7 which is experimental). Therefore is very hard to test an Ansible Role which involves FreeBSD using molecule (or any other tool) without alter the slave/runner state (or using a VM each time, which is not allowed on public CI engines).

## Molecule and Openstack

Molecule provides also drivers to use [Openstack](https://www.openstack.org) for role testing, running ```molecule init <role-name> --driver Openstack``` it will create the folder structure for new role (inside the ```<role-name>``` folder) and populate the create playbook for virtual machine (alongside with ssh keypair and security group) creation.

### Molecule and FreeBSD

Exploting the Openstack driver and the already described [FreeBSD Openstack Image](https://www.carlomaiorano.me/freebsd/2019/01/02/freebsd-openstack.html) you can test your own role on FreeBSD, relying also on the [BSD Ansible Community](https://github.com/ansible/community/wiki/BSD) for BSD specific modules.
In order to have Python in the FreeBSD image (if you don't have included, as explained in the article), you can add a ```prepare.yml``` to your molecule folder to install Python and create the link needed by molecule.

```yaml
- name: Prepare
  hosts: all
  gather_facts: false
  tasks:
    - name: Install python for Ansible
      raw: test -e /usr/bin/python || (pkg upgrade -y && pkg install -y python && ln -sf /usr/local/bin/python2.7 //usr/bin/python)
      become: true
      changed_when: false
```

Cheers :)