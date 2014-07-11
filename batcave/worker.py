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

    def build_app_container(self, username, app, tag, logpath):
        ''' Build the given application within a docker image '''
        log_setup = dna.logging.setup(
            level=os.environ.get('LOG_LEVEL', 'info'),
            filename='{}/{}.log'.format(logpath, app),
            show_log=False
        )

        with log_setup.applicationbound():
            self._consul = Consul(
                host=os.environ.get('CONSUL_HOST', 'localhost')
            )

            docker_host = self._consul.storage.get(
                'batcave/{}/docker/host'.format(username))
            docker_host = (self._default_docker_host
                           if 'error' in docker_host
                           else docker_host[0]['Value'])
            self._docker = docker.Client(
                base_url=docker_host,
                version='1.13', timeout=10
            )
            log.debug("Docker setup", status=self._docker.ping())

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
            self._docker.commit(container['Id'], repository=image)
            self._docker.commit(container['Id'], repository=image, tag=tag)

            should_push = self._consul.storage.get(
                'batcave/{}/push'.format(username))
            if code == 0 and 'error' not in should_push:
                # NOTE stream parameter ?
                log.info('Pushing image', image=image)
                self._docker.push(image)

            api_key = self._consul.storage.get(
                'batcave/{}/hipchat/apikey'.format(username))
            room_id = self._consul.storage.get(
                'batcave/{}/hipchat/room'.format(username))
            if 'error' not in api_key and 'error' not in room_id:
                hipchat = batcave.notification.HipchatBot(
                    room_id[0]['Value'],
                    name='Botcave',
                    api_key=api_key[0]['Value']
                )
                hipchat.notify(image, code)

            if code != 0:
                raise BuildFailed('build return code {}'.format(code))
            return code
