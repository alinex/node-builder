Alinex Development Utils
=================================================

[![Build Status](https://travis-ci.org/alinex/node-make.svg?branch=master)](https://travis-ci.org/alinex/node-make)
[![Dependency Status](https://gemnasium.com/alinex/node-make.png)](https://gemnasium.com/alinex/node-make)

This package contains some helper commands for development of the alinex
node packages. This is a superset of npm and other command line tools.

At the moment it is not completely general but specific to my own development.
But feel free to change the settings within the code to match your environment.


Motivation
-------------------------------------------------
While developing an automated build tool always help saving time and make things
magic and smooth.

My first intention was to use the standardized tools so I looked at Bower and
Cake. To have more possibilities above the tasks I decided to create a Cakefile.
This was a good way but over time it got bloated.

Because the general tasks are easy but have to be modularized I decided to
separate them into build tasks which stay in the package and overall management
tasks which were moved out into this helper tool.


Installation
-------------------------------------------------

Install the package using npm:

    > npm install alinex-make --production -g
    > npm dedupe

After global installation you may directly call `alinex-make` from anywhere.

[![NPM](https://nodei.co/npm/alinex-make.png?downloads=true&stars=true)](https://nodei.co/npm/alinex-make/)


Usage
-------------------------------------------------

The tool will be called with

    > bin/make [general options] <command> [command options]

With the option `--help` a screen explaining all commands and options will be
displayed. The major commands will be described here.


### General options

`-v`or `--verbose` will display a lot of information of what is going on.
This information will sometimes look discarded because of the parallel
processing of some tasks.

`-C` or `--no-colors` can be used to disable the colored output.


### Command `create`

Create a new package from scratch. This will create:

* the directory
* make some initial files
* init git repository
* setup github repository
* add and commit everything

The create task needs the `--password` setting to access github
through the api. And you may specify the `--package` setting for the npm name
of the package. The also mandatory path will be used as the github repository
name, too.

Some example calls will look like:

    > alinex-make create ./node-error --package alinex-error

    > alinex-make create ./private-module --private

This process is interactive and will ask you some more details. After that you 
may directly start to add your code. 


### Command `push`

This will push the changes to the origin repository. With the `--commit` option
it will also add and commit all other changes before doing so.

    > alinex-make push ./node-error

or

    > alinex-make push ./node-error --commit "commit message"


### Command `pull`

Like `push` this will fetch the newest changes from git origin.

    > alinex-make pull ./node-error


### Command `test`

As a first test a coffeelint check will be run. Only if this won't have any
errors the automatic tests will be run.

If the [istanbul](http://gotwarlost.github.io/istanbul/) module is installed
a code coverage report will be build.

    > bin/make test ../node-error

Or to contineously watch:

    > alinex-make test ./node-error --watch

And at last you may also add the `--browser` flag to open the documentation in
the browser after created.


### Command: `doc`

Generate the documentation this will create the documentation in the `doc`
folder. It includes the API documentation with code. Each module will get his
own documentation space with an auto generated index page.

This tool will extract the documentation from the markup and code files in
any language and generate HTML pages with the documentation beside the
code.

    > alinex-make doc ./node-error

It is also possible to update the documentation stored on any website. To
configure this for GitHub pages, you have to do nothing, for all others you
need to specify an `doc-publish` script in `package.json`. This may be an
rsync copy job like `rsync -av --delete doc root@myserver:/var/www`.
Start the document creation with publication using:

    > alinex-make doc ./node-error --publish

With the `--watch` option it is possible to keep the documentation updated.

    > bin/make doc ../node-error --watch

But this process will never end, you have to stop it manually to end it.

And at last you may also add the `--browser` flag to open the documentation in
the browser after created.

The style of the documentation can be specified if a specific css is present
in the alinex make package. It have to be under the path `src/data` and be called
by the `<basename>.css` while basename is the package name before the first
hyphen.


### Command `build`

Genereate the base system out of the source code. This creates the `lib` folder
by copying, compiling and transforming files. Everything will be done parallel.

    > bin/make build ../node-error

With the `--watch` option it is possible to keep the documentation updated.

    > bin/make build ../node-error --watch


### Command `publish`

With the push command you can publish your newest changes to github and npm as a
new version. The version can be set by signaling if it should be a `--major`,
`--minor` or bugfix version if no switch given.

To publish the next bugfix version only call:

    > bin/make publish ../node-error

For the next minor version (second number) call:

    > bin/make publish ../node-error --minor

And for a new major version:

    > bin/make publish ../node-error --major


### Command: `clean`

Remove all automatically generated files. This will bring you to the initial
state of the system. To create a usable system you have to build it again.

To clean everything which you won't need for a production environment use
`--dist` or `--auto` to remove all automatically generated files in the
development environment.

To cleanup all safe files:

    > bin/make clean ../node-error

Or on the development system remove all created files:

    > bin/make clean ../node-error --auto

And at last for production remove development files:

    > bin/make clean ../node-error --dist


Command overview
-------------------------------------------------

The following table will give a short overview of what really is done on each
command. This is not a full list of options and execute commands but an overview
of the major parts.

    | Command | Option | Execute (pseudo code)                                 |
    +---------+--------+-------------------------------------------------------+
    | create  | -      | mkdir; git init; touch files...; create github        |
    |         |        | git add; git commit; git push                         |
    | push    | -      | git push origin master                                |
    |         | commit | + git add; git commit // before                       |
    | pull    | -      | git pull                                              |
    | test    | -      | lint; npm test; istanbul                              |
    |         | watch  | + keep watching                                       |
    | doc     | -      | docker                                                |
    |         | watch  | + keep watching                                       |
    | build   | -      | npm install; npm update; npm dedupe                   |
    |         | watch  | + keep watching                                       |
    | publish | -      | git tag; git push; npm publish                        |
    | clean   | -      | rm -r; npm prune                                      |
    |         | dist   | + rm -r more files                                    |
    |         | auto   | + rm -r more files                                    |


License
-------------------------------------------------

Copyright 2013-2014 Alexander Schilling

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

>  <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
