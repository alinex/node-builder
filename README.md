Alinex Development Utils
=================================================

This package contains some helper commands for development of the alinex
node packages.

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

  > npm install alinex-make



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


### Command: `doc`

Generate the documentation this will create the documentation in the `doc`
folder. It includes the API documentation with code. Each module will get his
own documentation space with an auto generated index page.

This tool will extract the documentation from the markup and code files in
any language and generate HTML pages with the documentation beside the
code.

    > bin/make doc ../node-error

It is also possible to update the documentation on github using an additional
switch:

    > bin/make doc ../node-error --publish

With the `--watch` option it is possible to keep the documentation updated.

    > bin/make doc ../node-error --watch

But this process will never end, you have to stop it manually to end it.

And at last you may also add the `--browser` flag to open the documentation in
the browser after created.


### Command `create`

Create a new package from scratch. This will create:

* the directory
* init git repository
* setup github repository
* make initial files

The create task needs the `--password` setting to access github
through the api. And you may specify the `--package` setting for the npm name
of the package. The also mandatory path will be used as the github repository
name, too.

An example call will look like:

    > bin/make create ../node-error alinex-error --password xxxxxxxxx --package

After that you may directly start to add your code.


### Command `test`

As a first test a coffeelint check will be run. Only if this won't have any
errors the automatic tests will be run.


### Command `build`

Genereate the base system out of the source code. This creates the `lib` folder
by copying, compiling and transforming files. Everything will be done parallel.

With the `--watch` option it is possible to keep the documentation updated.


### Command `push`

With the push command you can push your newest changes to github and npm as a
new version. The version can be set by signaling if it should be a `--major`,
`--minor` or bugfix version if no switch given.

To publish the next bugfix version only call:

    > bin/make push ../node-error


### Command: `clean`

Remove all automatically generated files. This will bring you to the initial
state of the system. To create a usable system you have to build it again.


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
