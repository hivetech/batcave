# -*- coding: utf-8 -*-
# vim:fenc=utf-8

'''
  :copyright (c) 2014 Xavier Bruhiere.
  :license: %LICENCE%, see LICENSE for more details.
'''

import os
import datetime as dt
import requests
import dna.logging

log = dna.logging.logger(__name__)


class HipchatBot(object):
    '''
    Hipchat api client that sends notifications to a specified room
    Doc: https://www.hipchat.com/docs/api
    '''

    _api_url = 'https://api.hipchat.com/v1'
    bg_color = 'green'
    intro = 'Application syntheze notification'

    def __init__(self, room_id, name=None, api_key=None):
        self.room_id = room_id
        self.api_key = api_key if api_key else os.environ.get('HIPCHAT_API')
        self.name = name if name else 'Bot'

    def _api_call(self, path, data={}, http_method=requests.get):
        ''' Process an http call against the hipchat api '''
        log.info('performing api request', path=path)
        response = http_method('/'.join([self._api_url, path]),
                               params={'auth_token': self.api_key},
                               data=data)
        log.debug('{} remaining calls'.format(
            response.headers['x-ratelimit-remaining']))
        return response.json()

    def message(self, body, room_id, style='text'):
        ''' Send a message to the given room '''
        # TODO Automatically detect body format ?
        path = 'rooms/message'
        data = {
            'room_id': room_id,
            'message': body,
            'from': self.name,
            'notify': 1,
            'message_format': style,
            'color': self.bg_color
        }
        log.info('sending message to hipchat', message=body, room=room_id)
        feedback = self._api_call(path, data, requests.post)
        log.debug(feedback)
        return feedback

    # TODO Report send success or failure
    def notify(self, image, status):
        # TODO Same flood security as mobile
        body = '<strong>[{}] {} Build Status - {}</strong>'.format(
            str(dt.datetime.now()), image, status,
        )
        # TODO Customize bg color regarding status
        self.message(body, self.room_id, style='html')
