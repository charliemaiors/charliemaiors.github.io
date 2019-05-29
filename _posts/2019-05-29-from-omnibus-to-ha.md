---
layout: post
title:  "My journey with Gitlab, from AIO Omnibus to HA"
comments: true
categories: gitlab
sharing:
  twitter: My journey with @gitlab, from AIO Omnibus to HA
---

# My journey with Gitlab

When I was a research grant at the university we had a problem with SCM, we rely on an old SVN server with all the projects on it and we want to migrate to git. Among the differents on-premise offers (like [Gogs](https://gogs.io/), [Bitbucket server](https://it.atlassian.com/software/bitbucket/download)) we choose [Gitlab](https://about.gitlab.com/) because was (and is) the best on premise SCM solution (and IMHO is growing up quickly also on cloud, they are very active on GCP, see [here](https://about.gitlab.com/2018/10/11/gitlab-com-stability-post-gcp-migration/) and [here](https://about.gitlab.com/2017/03/02/why-we-are-not-leaving-the-cloud/) and many more articles from their [blog](https://about.gitlab.com/blog/)).
I had a spare bare metal machine, see [figure](optiplex) where I can make all the experiments that I want.

![optiplex](/assets/img/optiplex.jpg "The spare machine")

So I've decided to install the [Omnibus](https://docs.gitlab.com/omnibus/) package on that machine (which was running [Ubuntu](https://about.gitlab.com/install/#ubuntu) at the time), assigned a public IP and registered to a custom domain that we own (also for experiments).
The initial configuration (without any extra services) take into account just the external URL, and spare configuration for HTTPS and email:

```ruby
external_url 'https://<your-desidered-gitlab-domain>'
gitlab_rails['gitlab_email_enabled'] = true
gitlab_rails['gitlab_email_from'] = '<your-email-address>'
gitlab_rails['gitlab_email_display_name'] = 'Gitlab'
gitlab_rails['gitlab_email_reply_to'] = '<your-email-address>'
nginx['enable'] = true
nginx['redirect_http_to_https'] = true
nginx['listen_https'] = true
nginx['ssl_certificate'] = "<your-cert>"
nginx['ssl_certificate_key'] = "<your-cert-key>"
```

My collegues started also to use it, migrating projects from the old SVN to the new server.

I've started to appreciate also other "side" functionalities, like [Docker](https://www.docker.com/) Registry and the pipeline engine for [CI](https://www.wikiwand.com/en/Continuous_integration) with a tons of documentation.
The configuration of the Docker Registry was pretty straighforward:

```ruby
registry_external_url 'https://<your-registry-external-url>' # This could be the same of the gitlab external url (with different port) or anoter subdomain (or event a different domain) according to your configuration on the DNS
gitlab_rails['registry_enabled'] = true
registry['enable'] = true
registry_nginx['enable'] = true

registry_nginx['listen_port'] = 5001
registry_nginx['listen_https'] = true
registry_nginx['ssl_certificate'] = "<your-cert>" # Obtained with letsencrypt
registry_nginx['ssl_certificate_key'] = "<your-cert-key>" # Obtained with letsencrypt
```
## Moving to Cloud

After a while also my collegues started using the Gitlab instance, so we decided to migrate on our internal IaaS (Openstack) in order to have higher reliability compared to the [Optiplex](optiplex).
The migration was pretty much straight forward, I've just re-installed the ```gitlab-omnibus``` package, then restored the latest backup, modified the ```gitlab-secrets.json``` file and everything was up and running (IMHO the migration was very easy).
I've also appreciated the backup mechanism, which relies on a [Chef Cookbook](https://docs.chef.io/cookbooks.html), for its maximum configurability; in fact we decided to move our backups on the Openstack Object Storage (Swift), the backup mechanism relies on [Fog library](https://github.com/fog/fog-openstack) and the configuration was not so easy, but after some tests I've found the square. For completeness I will report our configuration (with redacted sensitive values):

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
So we configured also the [artifacts storage](https://docs.gitlab.com/ee/user/project/pipelines/job_artifacts.html), which also save a copy of the pipeline job logs on it (but atm has some [problem](https://gitlab.com/gitlab-org/gitlab-ce/issues/57733)), and the [lfs](https://git-lfs.github.com/). The configuration is pretty much the same, except for some parameters like the Swift temporary URL key.

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
Once deployed the cluster I've started the migration of Gitlab data to the external cluster (Note: the cluster is without pgbouncer), I've done these steps to move from the internal Postgres to the external one (assuming the external cluster up and running):

1. Dump the internal Database: ```sudo -u gitlab-psql /opt/gitlab/embedded/bin/pg_dumpall --username=gitlab-psql --host=/var/opt/gitlab/postgresql > /var/lib/pgsql/database.sql```
2. Import the dump into the cluster ```sudo -u postgres psql -f /var/lib/pgsql/database.sql``` (this is an example feel free to import it as you prefer)
3. Create the ```gitlab``` and set its password: ```sudo -u postgres psql -c "ALTER USER gitlab ENCRYPTED PASSWORD 'password' VALID UNTIL 'infinity';"```
4. Then modify the configuration file setting the following values:
```ruby
postgresql['enable'] = false # Disable the embedded PostgreSQL
gitlab_rails['db_adapter'] = "postgresql"
gitlab_rails['db_encoding'] = "unicode"
gitlab_rails['db_database'] = "gitlabhq_production" # Is the default created in the embedded instance
gitlab_rails['db_username'] = "gitlab"
gitlab_rails['db_password'] = "password"
gitlab_rails['db_host'] = "<cluster-master-ip-address>"
gitlab_rails['db_port'] = 5432 # Tipically the 5432
```
5. Then reconfigure and restart (```sudo gitlab-ctl reconfigure && sudo gitlab-ctl restart```)

The migration to the external database was smooth, but a major update (11.9) caused some a little outage; btw I've opened an [issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/59455) and the efficient Gitlab team supported us and in few minutes Gitlab was up and running again.

## Scaling

Then we decided to move our Gitlab deployment architecture from the AIO with Omnibus to the High Availability with the [horizontal model](https://docs.gitlab.com/ee/administration/high_availability/README.html#horizontal), like the one in [figure](horizontal)

![horizontal](/assets/img/horizontal.png "The Horizontal Architecture, credits to Gitlab HA documentation")

To achieve this I've started with the deployment of a Redis (plus Sentinel, in particular the number of Sentinels must be odd otherwise they will not reach consensus) cluster.

We deployed the Redis cluster using ansible, in particular using the role provided by [David Wittman](https://github.com/DavidWittman/ansible-redis); the we configured the only omnibus installation to interact with the Redis Sentinels and the master of the cluster. In particular:

```ruby
gitlab_rails['redis_password'] = '<redis-password>'
gitlab_rails['redis_sentinels'] = [
  {'host' => '<host-1>', 'port' => 26379},
  {'host' => '<host-2>', 'port' => 26379},
  {'host' => '<host-3>', 'port' => 26379},
]
redis['enable'] = false
redis['master_name'] = '<redis-master-name>'
```
Reading the documentation we found that each instance of the application server must have a NFS share where they can read and write files which becames from git operations (push, pull etc etc), our Openstack Cluster hadn't the possibility to have a [multi-attach volume](https://docs.openstack.org/cinder/latest/admin/blockstorage-volume-multiattach.html) so we decided to deploy a machine with only the [Gitaly](https://docs.gitlab.com/ee/administration/gitaly/) service on it. The migration from the local storage to the Gitaly machine was smooth, we followed these steps:

1. Deploy the machine with enough ram and an high number of vcpu to handle all the requests (for the moment), and a sufficiently big Cinder volume attached
2. Install Gitlab Omnibus on it, see [here](https://about.gitlab.com/install/)
3. Prepare the volume and add it to the fstab (like in this [post](https://medium.com/@sh.tsang/partitioning-formatting-and-mounting-a-hard-drive-in-linux-ubuntu-18-04-324b7634d1e0))
4. Configure the instance with ONLY these values:

```ruby
gitlab_rails['internal_api_url'] = 'https://<your-gitlab-external-url>'
gitlab_rails['auto_migrate'] = false
gitlab_rails['rake_cache_clear'] = false
gitlab_workhorse['enable'] = false
unicorn['enable'] = false
sidekiq['enable'] = false
postgresql['enable'] = false
redis['enable'] = false
nginx['enable'] = false
prometheus['enable'] = false
alertmanager['enable'] = false
node_exporter['enable'] = false
redis_exporter['enable'] = false
pgbouncer_exporter['enable'] = false
gitlab_monitor['enable'] = false
gitaly['enable'] = true
gitaly['listen_addr'] = "0.0.0.0:8075" # This is the usual configuration for tcp WITHOUT tls (in our infrastructure gitaly is in a "trust zone")
gitaly['auth_token'] = '<your-supersecret-token>'
gitaly['storage'] = [
   {
     'name' => 'default',
     'path' => '<your-path>'
   } # more than one storage repo could be defined
]
```
5. Reconfigure and restart the gitlay instance: ```# gitlab-ctl reconfigure && gitlab-ctl restart```
6. Rsync the omnibus repository folder to the gitaly folder and set the proper permissions: ```rsync -qaHAXS -e ssh /var/opt/gitlab/git-data/ user@gitaly-server:/<your-path>```
7. Modify the ominibus installation configuration in order to use the gitaly server:
```ruby
gitlab_rails['gitaly_token'] = '<your-supersecret-token>'
git_data_dirs({
   "default" => {
     "path" => "<your-path>",
     "gitaly_address" => "tcp://<gitaly-address>:8075"
   }
})
```
8. Reconfigure and restart the omnibus installation: ```# gitlab-ctl reconfigure && gitlab-ctl restart```

After Gitaly we deployed yall the side components to reach the horizontal scalability, the missing components are: the reverse proxy/load balancer, and at least another gitlab instance.

I've made it deploying another gitlab instance, using near the same configuration, and together modified the configuration of a "Gateway" that we use for each service, which is a nginx with multiple hosts configured, one for each service.

The second Gitlab instance was configured taking as reference the HA [documentation](https://docs.gitlab.com/ee/administration/high_availability/gitlab.html), but instead of NFS we rely on Gitaly so the storage configuration part was replicated using the one from Gitaly (see above).
The only exception was the docker registry, this feature rely completely on NFS because the registry needs a storage folder and our Cinder deployment does not supports the multi-attach property; so we decided to not have a complete "mirror" in functionalities between the two application servers exploiting the custom domain for the registry on the load balancer.
The configuration of the second was the same of the first one except for the docker registry configuration and these parameters:

```ruby
 gitlab_shell['secret_token'] = '<your-secret-token>'
 gitlab_rails['otp_key_base'] = '<your-otp-key-base>'
 gitlab_rails['secret_key_base'] = '<your-secret-key-base>'
 gitlab_rails['db_key_base'] = '<your-db-key-base>'
```

And also as explained in the [guide](https://docs.gitlab.com/ee/administration/high_availability/gitlab.html), we configured the instance to avoid the database migration on new version:
```shell
# touch /etc/gitlab/skip-autoreconfigure
```

We had also to modify both of the instances nginx configuration, in order to be aware of the reverse proxy. The gitlab_nginx final configuration is:

```ruby
nginx['real_ip_trusted_addresses'] = [ '<load-balancer-ip>' ]
nginx['real_ip_header'] = 'X-Forwarded-For'
nginx['real_ip_recursive'] = 'on'
nginx['listen_https'] = false
nginx['listen_port'] = 80
#nginx['ssl_certificate'] = "<cert>"
#nginx['ssl_certificate_key'] = "<priv-key>"
#nginx['redirect_http_to_https'] = true
nginx['proxy_set_headers'] = {
  "Host" => "$http_host_with_default",
  "X-Real-IP" => "$remote_addr",
  "X-Forwarded-For" => "$proxy_add_x_forwarded_for",
  "X-Forwarded-Proto" => "https",
  "X-Forwarded-Ssl" => "on",
  "Upgrade" => "$http_upgrade",
  "Connection" => "$connection_upgrade"
}
```
On the instance with the Docker registry we have to modify the values relatives to the nginx instance which handle it. In particular we had to remove the https and change the listening port.

```ini
registry_nginx['enable'] = true

registry_nginx['listen_port'] = 5001
registry_nginx['listen_https'] = false
registry_nginx['proxy_set_headers'] = {
  "Host" => "$http_host",
  "X-Real-IP" => "$remote_addr",
  "X-Forwarded-For" => "$proxy_add_x_forwarded_for",
  "X-Forwarded-Proto" => "https",
  "X-Forwarded-Ssl" => "on"
}
```

Then we moved to the load balancer to properly configure the vhosts of the registry and gitlab, and also the ssh access to gitlab. The load balancer is an instance of nginx configured to act as reverse-proxy/load-balancer for some services. I will avoid the base configuration and report only the relevant files for each service.

The configuration for the application servers is:

```ini
upstream gitlab {
	server <gitlab-instance-1>;
	server <gitlab-instance-2>;
}

server {
	listen 80;
	server_name <gitlab.your-domain.your-gtld>;
	return 301 https://$server_name$request_uri;
}
server {
	listen 443 ssl http2;
	server_name <gitlab.your-domain.your-gtld>;
	ssl_certificate <your-cert>;
   ssl_certificate_key <your-key>
   ssl_trusted_certificate <your-trust-chain>; # For some services which uses gitlab API
   ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
   ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
   ssl_prefer_server_ciphers on;
   ssl_dhparam <your-dh-param>;
	server_tokens off;
	ssl on;
	add_header X-Content-Type-Options nosniff;

	location / {
		gzip off;
  		proxy_set_header Host $http_host;
  		proxy_set_header X-Real-IP $remote_addr;
  		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  		proxy_set_header X-Forwarded-Proto $scheme;
  		proxy_set_header X-Forwarded-Protocol $scheme;
  		proxy_set_header X-Url-Scheme $scheme;
		proxy_set_header X-Frame-Options     SAMEORIGIN;
		proxy_pass http://gitlab;
	}

   location /profile/personal_access_tokens { 
      gzip off;   
      proxy_set_header Host $http_host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Protocol $scheme;
      proxy_set_header X-Url-Scheme $scheme;
      proxy_set_header X-Frame-Options     SAMEORIGIN;
      proxy_pass http://<gitlab-docker-registry-instance>;
   }
}
```
The last part of the configuration is necessary because in my deployment only one instance has the registry configured, so if the developer needs to generate a token to read or interact with the registry must be redirected to the correct instance. Also the permissions of the instance with docker registry are a super set of the other one.

Tipically git relies on SSH/HTTP/HTTPS, the above configuration enables only HTTPS so I defined another load balancer rule on the gateway using nginx[ stream module](http://nginx.org/en/docs/stream/ngx_stream_core_module.html), these kind of rules must be defined (or [included](http://nginx.org/en/docs/ngx_core_module.html#include)) outside of the http section.

```ini
stream {
	upstream gitlab {
		server <gitlab-instance-1>:22;
		server <gitlab-instance-2>:22;
	}

	server { # Here is simple TCP you can't have custom headers which could be parsed for retrieve the destination host
		listen 22 reuseport;
		proxy_pass gitlab;
	}
}
```
Finally we defined the vhost for the Docker registry (because we choose a custom domain for it), which is a simple reverse proxy configuration which enables the proxy for the docker registry.

```ini
server {
	listen 80;
	server_name <your-registry-domain>;
	return 301 https://$server_name$request_uri;
}

server {
	listen 443 ssl http2;
	server_name <your-registry-domain>;
	ssl_certificate <your-cert>;
   ssl_certificate_key <your-key>;
   ssl_trusted_certificate <your-trust-chain>;
   ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
   ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
   ssl_prefer_server_ciphers on;
   ssl_session_cache shared:SSL:10m;
   ssl_dhparam <dh-param>;
   add_header Strict-Transport-Security "max-age=31536000; includeSubdomains;";

	location / {
  		proxy_set_header Host $http_host;
  		proxy_set_header X-Real-IP $remote_addr;
  		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  		proxy_set_header X-Forwarded-Proto $scheme;
  		proxy_set_header X-Forwarded-Protocol $scheme;
  		proxy_set_header X-Url-Scheme $scheme;
		proxy_pass http://docker-registry-ip:5001;
	}
}
```

I hope that this little narration plus some configuration snippet could be helpful. Enjoy :)