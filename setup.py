from codecs import open
from os import path
from setuptools import setup, find_packages
from subprocess import check_output

here = path.abspath(path.dirname(__file__))

check_output(
    'pandoc --from=markdown --to=rst --output=' + path.join(here, 'README.rst') + ' ' + path.join(here, 'README.md'),
    shell=True
)

with open(path.join(here, 'README.rst'), encoding='utf-8') as f:
    long_description = f.read()

install_requires = list()
with open(path.join(here, 'requirements.txt'), 'r', encoding='utf-8') as f:
    for line in f.readlines():
        install_requires.append(line)

setup(
    name='dotstow',

    version='0.1.2',

    description='Manage dotfiles with stow',

    long_description=long_description,

    url='https://github.com/codejamninja/dotstow',

    author='Jam Risser',

    author_email='jam@codejam.ninja',

    license='MIT',

    # https://pypi.python.org/pypi?%3Aaction=list_classifiers
    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'Topic :: Utilities',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
    ],

    keywords='ubuntu remaster fork install linux',

    packages=find_packages(exclude=['contrib', 'docs', 'tests']),

    install_requires=install_requires,

    include_package_data=True,

    entry_points = {
        'console_scripts': ['dotstow=dotstow.__main__:main'],
    }
)
