# -*- coding: utf-8 -*-
# vim:fenc=utf-8

'''
  :copyright (c) 2014 Xavier Bruhiere.
  :license: %LICENCE%, see LICENSE for more details.
'''

import os
import docker
import dna.logging
import batcave.notification
from pyconsul.http import Consul

log = dna.logging.logger(__name__)


class BuildFailed(Exception):
    pass


class Builder(object):

    _default_docker_host = 'unix:///var/run/docker.sock'
    # batcave.sh should have exported it
    _batcave_root = os.environ.get('BATCAVE_ROOT', '/tmp/repos')

    def build_app_container(self, username, app, tag):
        ''' Build the given application within a docker image '''
        self._docker = docker.Client(
            base_url=os.environ.get('DOCKER_HOST', self._default_docker_host),
            version='1.13', timeout=10
        )
        log.debug("Docker setup", status=self._docker.ping())

        self._consul = Consul(host=os.environ.get('CONSUL_HOST', 'localhost'))

        cache_directory = '{}/{}'.format(self._batcave_root, app)
        image = '{}/{}'.format(username, app)

        log.info('Building application ...')
        container = self._docker.create_container(
            image,
            detach=True,
            volumes=[cache_directory],
            command="/build/stack/proxy_builder"
        )
        self._docker.start(
            container['Id'],
            binds={'/cache': {'bind': cache_directory, 'ro': False}}
        )
        log.debug(container)
        log.info('Streaming logs ...')
        log.info('Waiting container to finish ...')
        code = self._docker.wait(container['Id'])
        log.info('Container returned {}'.format(code))
        build_logs = self._docker.logs(container['Id'])
        log.debug(build_logs)
        log.info('Commiting final {} as {}'.format(container['Id'], image))
        self._docker.commit(container['Id'], repository=image, tag='latest')
        self._docker.commit(container['Id'], repository=image, tag=tag)

        result = self._consul.storage.get('user/push')
        if (code == 0 and
                os.path.exists(os.path.expanduser('~/.docker.cfg')) and
                'error' not in result):
            # NOTE stream parameter ?
            log.info('Pushing image', image=image)
            self._docker.push(image)

        result = self._consul.storage.get('user/hipchat')
        if 'error' not in result:
            hipchat = batcave.notification.HipchatBot(
                'Lab', name='Botcave', api_key=result[0]['Value']
            )
            hipchat.notify(image, code)

        log.debug(self._default_docker_host)
        log.debug(self._batcave_root)

        if code != 0:
            raise BuildFailed('build return code {}'.format(code))
        return code
