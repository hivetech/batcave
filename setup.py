# -*- coding: utf-8 -*-
# vim:fenc=utf-8

'''
  :copyright (c) 2014 Xavier Bruhiere
  :license: Apache 2.0, see LICENSE for more details.
'''

import multiprocessing
import setuptools
from batcave import (
    __version__, __author__, __licence__, __project__
)


REQUIREMENTS = [
    'click',
    'redis',
    'rq',
    'docker-py',
    'dna'
]


def long_description():
    try:
        with open('README.md') as f:
            return f.read()
    except IOError:
        return "failed to read README.md"


setuptools.setup(
    name=__project__,
    version=__version__,
    description='Automatic DevOps tooling around your app',
    author=__author__,
    author_email='xavier.bruhiere@gmail.com',
    packages=setuptools.find_packages(),
    long_description=long_description(),
    license=__licence__,
    install_requires=REQUIREMENTS,
    url="https://github.com/hivetech/batcave",
    entry_points={
        'console_scripts': [
            'batcave = batcave.__main__:schedule',
        ],
    },
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'License :: OSI Approved :: MIT Licence',
        'Natural Language :: English',
        'Programming Language :: Python',
        'Programming Language :: Python :: 2.7',
        'Operating System :: OS Independent',
        'Intended Audience :: Science/Research',
        'Topic :: Software Development',
        'Topic :: Software Development :: Build Tools'
    ]
)
