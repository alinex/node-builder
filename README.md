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

### Command: `clean`

Remove all automatically generated files. This will bring you to the initial
state of the system. To create a usable system you have to build it again.

It will delete compiled files, generated documentation and the generated log
files. With the `--all` option it will also delete config files, data and
node_modules.

### Command: `doc`

Generate the documentation this will create the documentation in the `doc`
folder. It includes the API documentation with code. Each module will get his
own documentation space with an auto generated index page.

This tool will extract the documentation from the markup and code files in
any language and generate HTML pages with the documentation beside the
code.

With the `--watch` option it is possible to keep the documentation updated.

### Command `create`

Genereate the base system out of the source code. This creates the `lib` folder
by copiing, compiling and transforming files. Everything will be done parallel.

### Command `test`

### Command `build`

With the `--watch` option it is possible to keep the documentation updated.

### Command `push`


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
