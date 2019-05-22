---
layout: post
title:  "My journey with Gitlab, from AIO Omnibus to HA"
comments: true
categories: gitlab
sharing:
  twitter: My journey with @gitlab, from AIO Omnibus to HA
---

# My journey with Gitlab

When I was a research grant at the university we had a problem with SCM, we rely on an old SVN server with all the projects on it and we want to migrate to git. Among the differents on-premise offers (like [Gogs](https://gogs.io/), [Bitbucket server](https://it.atlassian.com/software/bitbucket/download)) we choose [Gitlab](https://about.gitlab.com/) because was (and is) the best on premise SCM solution (and IMHO is growing up quickly also on cloud).
I had a spare bare metal machine, see [figure](optiplex) where I can make all the experiments that I want.

![optiplex](/assets/img/optiplex.jpg "The spare machine")

So I've decided to install the [Omnibus](https://docs.gitlab.com/omnibus/) package on that machine (which was running [Ubuntu](https://about.gitlab.com/install/#ubuntu) at the time), assigned a public IP and registered to a custom domain that we own (also for experiments).
My collegues started also to use it, migrating projects from the old SVN to the new server.

I've started to appreciate also other "side" functionalities, like [Docker](https://www.docker.com/) Registry and the pipeline engine for [CI](https://www.wikiwand.com/en/Continuous_integration).

After a while also my collegues started using the Gitlab instance, so we decided to migrate on our internal IaaS (Openstack) in order to have higher reliability compared to the [Optiplex](optiplex).
The migration was pretty much straight forward, I've just re-installed the ```gitlab-omnibus``` package, then restored the latest backup, modified the ```gitlab-secrets.json``` file and everything was up and running (IMHO the migration was very easy).
I've also appreciated the backup mechanism, which relies on a [Chef Cookbook](https://docs.chef.io/cookbooks.html), for its maximum configurability; in fact we decided to move our backups on the Openstack Object Storage (Swift), the backup mechanism relies on [Fog library](https://github.com/fog/fog-openstack) and the configuration was not so easy. For completeness I will report our configuration (with redacted sensitive values):

```ruby
gitlab_rails['backup_keep_time'] = 604800

gitlab_rails['backup_upload_connection'] = {
   'provider' => 'Openstack',
   'openstack_auth_url' => 'http://keystonev3url:5000/v3',
   'openstack_username' => 'username',
   'openstack_api_key' =>  'password',
   'openstack_project_name' => 'tenant',
   'openstack_domain_id' =>    'target-domain'
}
gitlab_rails['backup_upload_remote_directory'] = 'swift-container-name'
gitlab_rails['backup_multipart_chunk_size'] = 1048576000
```

After some tests with this configuration we choose to rely as-much-as-possible on the Object Storage, in order to maintain the instance with enough free space.
So we configured also the [artifacts storage](https://docs.gitlab.com/ee/user/project/pipelines/job_artifacts.html), which also save a copy of the pipeline job logs on it, and the [lfs](https://git-lfs.github.com/). The configuration is pretty much the same, except for some parameters like the Swift temporary URL key.

The artifacts snippet is:

```ruby
gitlab_rails['artifacts_enabled'] = true
# gitlab_rails['artifacts_path'] = "/mnt/storage/artifacts"
gitlab_rails['artifacts_object_store_enabled'] = true # EE only
gitlab_rails['artifacts_object_store_remote_directory'] = "artifacts-container"
gitlab_rails['artifacts_object_store_connection'] = {
   'provider' => 'OpenStack',
   'openstack_auth_url' => 'http://keystonev3url:5000/v3',
   'openstack_username' => 'user',
   'openstack_api_key' =>  'password',
   'openstack_project_name' => 'project',
   'openstack_domain_id' =>    'domain',
   'openstack_temp_url_key' => 'swift-temp-url-key'
}
```

Instead the lfs configuration snippet:

```ruby
### Git LFS
gitlab_rails['lfs_enabled'] = true
# gitlab_rails['lfs_storage_path'] = "/mnt/storage/lfs-objects"
gitlab_rails['lfs_object_store_enabled'] = true # EE only
gitlab_rails['lfs_object_store_background_upload'] = true # Our object storage is not so fast so we choose to do a background upload instead of have timeouts
gitlab_rails['lfs_object_store_remote_directory'] = "lfs-container"
gitlab_rails['lfs_object_store_connection'] = {
   'provider' => 'OpenStack',
   'openstack_auth_url' => 'http://keystonev3url:5000/v3',
   'openstack_username' => 'username',
   'openstack_api_key' => 'password',
   'openstack_project_name' => 'project',
   'openstack_domain_id' => 'domain',
   'openstack_temp_url_key' => 'swift-temp-url-key'
}
```

The Openstack cluster hosts (among all the projects) also other horizontal services which uses databases, key-value store and many other architectural components which can be shared between services. 
In particular we had (btw they are still running) some services which relies on PostgreSQL as database, so we decided to "clusterize" all the Postgres instances in order to have high availability and streamed data replication; from a functional point of view I've deployed a set of PostgreSQL instances and migrated all other databases to the cluster in order to have the same version on the same OS.
I've used ansible (this [role](https://github.com/geerlingguy/ansible-role-postgresql), I've used a lot of roles written by [geerlingguy](https://www.jeffgeerling.com/) because works as expected and covers all the aspect of the target service/application), to deploy Postgres and then performed some other manual tasks to create the cluster.
Once deployed the cluster