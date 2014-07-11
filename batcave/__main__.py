#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8

'''
  :copyright (c) 2014 Xavier Bruhiere.
  :license: %LICENCE%, see LICENSE for more details.
'''

import os
import click
from redis import Redis
from rq import Queue
import batcave.worker


@click.command()
@click.option('--username', default='batcave', help='Author of the push')
@click.option('--app', required=True, help='Application name')
@click.option('--commit', default='latest', help='Application name')
@click.option('--logpath', default='/tmp', help='Logs directory')
def schedule(username, app, commit, logpath):
    queue_ = Queue(connection=Redis(
        host=os.environ.get('REDIS_HOST', 'localhost'),
        port=os.environ.get('REDIS_PORT', '6379')
    ))

    builder_ = batcave.worker.Builder()
    job = queue_.enqueue_call(
        func=builder_.build_app_container,
        kwargs={
            'username': username,
            'app': app,
            'tag': commit,
            'logpath': logpath
        }
    )
    batcave.worker.log.debug("job enqueued", date=job.enqueued_at, uuid=job.id)


if __name__ == '__main__':
    schedule()
