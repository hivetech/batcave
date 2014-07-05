BatCave
=======

> Automatic DevOps tooling around your app

`git push` your code to *Batcave* and get the build wrapped back into a
smart docker image featuring log and perfs monitoring, service discovery
and configuration manager setup.

The project is built on top of :

* [Dokku](https://github.com/progrium/dokku), [Buildstep](https://github.com/progrium/buildstep) and [Gitreceived](https://github.com/flynn/gitreceived)
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

Alternaly you can use the docker image.

```console
$ docker run -d -P -e CONSUL_HOST=192.168.0.19 hivetech/batcave
```

Then point to a working docker server exposed over http (see below for
customization, add `DOCKER_OPTS="-H tcp://0.0.0.0:4243` to
`/etc/default/docker` and restart : `sudo service docker restart`).

With this method you still need to use the private ssh key in
batcave/build/base/certs (just run `make ssh` in *batcave* root directory).


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
$ # We need sudo to listen on port 22
$ sudo gitreceived -n -k ~/.ssh/batcave_id_rsa auth.sh batcave.sh
```

In another terminal

```console
$ cd /my/app
$ $EDITOR hive.yml  # Optional, see example.hive.yml
$ git remote add my_batcave git@<your-server>:<project>.git
$ # Or with batcave listening on a custom port (like in a container)
$ git remote add do ssh://<user>@<ip>:<port>/<projet>.git

$ git push -u my_batcave master

... Build logs ...
```

If everything went fine, we have now a `batcave/<project>` docker container
with our application, built from `batcave/warehouse/buildstep`.

Customization
-------------

`Batcave` reads the following values from [consul kv
storage](http://www.consul.io/intro/getting-started/kv.html):

* `<user>/docker/host` (default `unix:///var/run/docker.sock`). Point to the
  docker server where images are built.
* `<user>/docker/repo` (default `batcave`). The first part of docker images,
  providing the repository where images could be pushed and stored.
* `<user>/base` (default `hivetech/batcave:buildstep`). The image used to build
  applications. It must include specific scripts so for now I recommend to
  stick with default.
* `<user>/push` (default `""`). If set to true, `Batcave` will try to push the
  image to the provided repository. You must be already logged in (`docker
  login`).

Workers and Services
--------------------

Not stable yet ...


Built images usage
------------------

Prepare the server

```console
$ # Prepare the server for service orchestration (optional)
$ consul agent -server -bootstrap -data-dir /tmp/consul -node=master -client 0.0.0.0

$ # This image combines logstash, elasticsearch and kibana (even more optional)
$ docker run --name logstash -p 9292:9292 -d -t hivetech/logstash
```

Kickoff the app

```console
# Skipping those variables will prevent services from running
docker run -d --name myapp \
  -e CONSUL_HOST=192.168.0.11     # Will join the consul master autmatically \
  -e LOGSTASH_HOST=172.17.0.3     # Where to ship logs \
  -e NODE_ID=myapp                # Identify the new node \
  hivetech/batcave:base /sbin/my_init --enable-insecure-key
```
