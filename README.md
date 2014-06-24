BatCave
=======

> Automatic DevOps tooling around your app

`git push` your code to *Batcave* and get the build wrapped back into a
smart docker image featuring log and perfs monitoring, service discovery
and configuration manager setup.

The project is built on top of :

* [Dokku](https://github.com/progrium/dokku) and [Gitreceived](https://github.com/flynn/gitreceived)
* [Consul](http://www.consul.io/)
* [Ansible](http://ansible.com/)
* [Passenger-docker](https://github.com/phusion/passenger-docker)

Kudos for all.


Install
-------

You need [docker](https://docs.docker.com/) and [Go](http://golang.org/) installed.

```console
$ git clone https://github.com/hivetech/batcave.git
$ # Please beware, this setup is absolutely not secure for now.
$ cd batcave && make
```

Alternaly you can use the docker image. Point to a working docker server
exposed over http (add `DOCKER_OPTS="-H tcp://0.0.0.0:4243` to `/etc/default/docker` and restart
docker : `sudo service docker restart`).

```console
$ docker run -d -P \
  -e DOCKER_HOST=tcp://192.168.0.19:4243 \  # Your docker server
  -e BATCAVE_BASE=hivetech/buildstep \      # The image you want to base your builds on
  -e BATCAVE_REPO=<username> \              # It will be used to commit the image as <username>/<project>
  hivetech/batcave
```

With this method you will still need to use the private ssh key in
batcave/build (just run `make ssh` in *batcave* root directory).


App build
---------

There are two ways *Batcave* can build an app.

* Heroku or dokku like ([judo]() style) (not functionnal yet)

Without anything particular, it will use buildpacks, and a Procfile if present
to boot the app.

* Travis-like, with explicit instructions

`hive.yml` is a configuration file to write in the app root directory,
similar to [Travis](http://travis-ci.org/) or
[Shippable](http://shippable.com/) (see example.hive.yml), except for `command`
and `workers`. The former should be the main program to run, while the later is
an array of scripts to start in parallel.


Getting started
---------------

On the build server

```console
$ # An authentification system is on the roadmap
$ sudo gitreceived -n -k ~/.ssh/batcave_id_rsa auth.sh batcave.sh
```

In another terminal

```console
$ cd /my/app
$ $EDITOR hive.yml  # Optional, see example.hive.yml
$ git remote add my_batcave git@<your-server>:<project>.git

$ git push -u my_batcave master

... Build logs ...
```

If everything went fine, we have now a `batcave/<project>` docker container
with our application, built from `batcave/warehouse/buildstep`.


Built images usage
------------------

Prepare the server

```console
$ # Prepare the server for service orchestration (optional)
$ consul agent -server -bootstrap -data-dir /tmp/consul -node=master -client 0.0.0.0

$ # This image compiles logstash, elasticsearch and kibana
$ docker run --name logstash -p 9292:9292 -d -t hivetech/logstash
```

Kickoff the app

```console
# Skipping those variables will prevent services from running
docker run -d --name myapp \
  -e CONSUL_MASTER=192.168.0.11   # Will join the consul master autmatically \
  -e LOGSTASH_SERVER=172.17.0.3   # Where to ship logs \
  -e NODE_ID=myapp                # Identify the new node \
  hivetech/base /sbin/my_init --enable-insecure-key
```
