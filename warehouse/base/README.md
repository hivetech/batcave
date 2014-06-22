Unide Node
==========

This dockerfile builds the base node of the [unide](unide.co) platform.
It introduces basic services needed by hivy to orchastrate containers.

* [serf](serfdom.io) : Event-based service discovery and orchestration
* SSH
* salt-minion / Ansible : unide containers are ready to be configured through
  those onfiguratin managers

Further unide containers are expected to be built on top of this image.
