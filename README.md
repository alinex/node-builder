Alinex Builder
=================================================

[![Build Status](https://travis-ci.org/alinex/node-builder.svg?branch=master)](https://travis-ci.org/alinex/node-builder)
[![Dependency Status](https://gemnasium.com/alinex/node-builder.png)](https://gemnasium.com/alinex/node-builder)

This package contains some helper commands for development of the alinex
node packages. Realized as a superset of npm and other command line tools.

It may help a lot while developing to automatize the consequently done tasks.

- easy to use build tool
- supporting complete process
- specialized for the alinex modules
- usable for other modules, too
- working with multiple packages at once

> It is one of the modules of the [Alinex Universe](http://alinex.github.io/code.html)
> following the code standards defined in the [General Docs](http://alinex.github.io/develop).


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


Install
-------------------------------------------------

[![NPM](https://nodei.co/npm/alinex-builder.png?downloads=true&downloadRank=true&stars=true)
 ![Downloads](https://nodei.co/npm-dl/alinex-builder.png?months=9&height=3)
](https://www.npmjs.com/package/alinex-builder)

It may be installed globally as an universal helper or integrated into a package
as development dependency.

Install the package globally using npm:

``` sh
sudo npm install -g alinex-builder --production
builder --help
```

After global installation you may directly call `builder` from anywhere like shown
above.

Or you may integrate it into your own package:

``` sh
npm install alinex-builder --save-devs
./node_modules/.bin/builder --help
```

By integrating it you won't need all the development tools within your package.

Always have a look at the latest [changes](Changelog.md).


Usage
-------------------------------------------------

The tool will be called with:

``` sh
builder [dirs] [general options] -c <commands> [command options]
```

But if not installed globally you may run:

``` sh
node_modules/.bin/builder [dirs] [general options] -c <commands>
```

With the option `--help` a screen explaining all commands and options will be
displayed. The major commands will be described here.

Multiple directory names can be given. They specify on which project to work on.
It should point to the base package directory of a module. If not specified the
command will run from the current directory.
You may change the order of the options like you want but keep the directories
before them. If you give a directory just behind a command it is interpreted
as additional command instead as directory.

If you want to give multiple commands add a second `-c` option or just put them
one behind the other in one option.

Within your `package.json` it may look like:

``` json
{
  "scripts": {
    "prepublish": "node_modules/.bin/builder -c compile --uglify",
    "test": "node_modules/.bin/builder -c test"
  }
}
```

### General options

`-v`or `--verbose` will display a lot of information of what is going on.
This information will sometimes look discarded because of the parallel
processing of some tasks.

`-C` or `--no-colors` can be used to disable the colored output.


### create

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

``` sh
builder ./node-error -c create --package alinex-error
builder ./private-module -c create --private
```

This process is interactive and will ask you some more details. After that you
may directly start to add your code.


### push

This will push the changes to the origin repository. With the `--message` option
it will also add and commit all other changes before doing so.

``` sh
builder -c push                  # from within the package directory
builder ./node-error -c push     # or from anywhere else
```

or to also commit the last changes

``` sh
builder ./node-error -c push --message "commit message"
```


### pull

Like `push` this will fetch the newest changes from git origin.

``` sh
builder -c pull                  # from within the package directory
builder ./node-error -c pull     # or from anywhere else
```

``` text
Pull from origin
Von https://github.com/alinex/node-make
* branch            master     -> FETCH_HEAD
```

### link

This task will link a local package installed in a parallel directory into the
packages node_modules directory.

``` sh
builder -c link                  # link all node-... as alinex-...  packages
builder -c link --locale config  # or link only the config package
```

### compile

This task is used to compile the sources into for runtime optimized library.

``` sh
builder -c compile               # from within the package directory
builder ./node-error -c compile  # or from anywhere else
```

``` text
Remove old directories
Compile man pages
Compile coffee script
```

Or give an directory and use uglify to compress the extension.

``` sh
builder ./node-error -c compile --uglify
```

Mostly this task will be added as prepublish script to the `package.json` like:

``` json
{
  "scripts": {
    "prepublish": "node_modules/.bin/builder -c compile -u"
  }
}
```

Also this will make man files from mardown documents in `src/man` if they
are referenced in the package.json.


### update

This task is a handy addition to include the npm install and npm update commands:

``` sh
builder -c update               # from within the package directory
builder ./node-error -c update  # or from anywhere else
```

At the end this task will list all direct subpackages which are outdated and may
be updated in the package.json.

``` text
update and installation of package with dependent packages
update ./
Install through npm
Update npm packages
List outdated packages
Package               Current  Wanted     Latest  Location
Nothing to upgrade in this package found.
Done.
```

### test

As a first test a coffeelint check will be run. Only if this won't have any
errors the automatic tests will be run.

If the [istanbul](http://gotwarlost.github.io/istanbul/) module is installed
a code coverage report will be build.
And at last code metrics will be analyzed but only on the compiled version at
the moment. You will find this reports under '/reports' directory as html.

``` sh
builder -c test                  # from within the package directory
builder ./node-error -c test     # or from anywhere else
```

``` text
Linting coffee code
Run mocha tests

Simple mocha test
✓ should add two numbers

1 passing (9ms)
```

Or to contineously watch it:

``` sh
builder ./node-error -c test --watch
```

You may also create an html coverage report:

``` sh
builder -c test --coverage
```

If you want to stop after the  first error occurs use the `--bail` flag.

And at last you can add the `--browser` flag to open the coverage report
automatically in the browser. Also `--coveralls` may be added to send the
results to coveralls.

This task can also be added to the `package.json` to be called using `npm test`:

``` json
{
  "scripts": {
    "test": "node_modules/.bin/builder test"
  }
}
```

Often you would also need the following combination:

``` sh
builder -v -c compile test           # to check your just finished code changes
```

### doc

Generate the documentation this will create the documentation in the `doc`
folder. It includes the API documentation with code. Each module will get his
own documentation space with an auto generated index page.

This tool will extract the documentation from the markup and code files in
any language and generate HTML pages with the documentation beside the
code.

``` sh
builder -c doc                   # from within the package directory
builder ./node-error -c doc      # or from anywhere else
```

``` text
Create html documentation
Done.
```

It is also possible to update the documentation stored on any website. To
configure this for GitHub pages, you have to do nothing, for all others you
need to specify an `doc-publish` script in `package.json`. This may be an
rsync copy job like `rsync -av --delete doc root@myserver:/var/www`.
Start the document creation with publication using:

``` sh
builder ./node-error -c doc --publish
```

With the `--watch` option it is possible to keep the documentation updated.

``` sh
builder  ./node-error -c doc --watch
```

But this process will never end, you have to stop it manually to end it.

And at last you may also add the `--browser` flag to open the documentation in
the browser after created.

The style of the documentation can be specified if a specific css is present
in the alinex make package. It have to be under the path `src/data` and be called
by the `<basename>.css` while basename is the package name before the first
hyphen.


### changes

This will list all changes in
- packages
- since last version tag
- in current committe
- and things are staged only

Use this to check if you should make a new publication or if it can wait.

``` sh
builder -c changes
```

``` text
NPM Update check:
- docker            😕  NOTUSED?  Possibly never referenced in the code.
- alinex-config     😍  UPDATE!   Your local install is out of date. http://alinex.github.io/node-config/
- marked-man        😕  NOTUSED?  Possibly never referenced in the code.
- coffee-coverage   😕  NOTUSED?  Possibly never referenced in the code.
- coffeelint        😕  NOTUSED?  Possibly never referenced in the code.
- coveralls         😕  NOTUSED?  Possibly never referenced in the code.
- istanbul          😕  NOTUSED?  Possibly never referenced in the code.
- npm-check         😕  NOTUSED?  Possibly never referenced in the code.
- replace           😕  NOTUSED?  Possibly never referenced in the code.
- uglify-js         😕  NOTUSED?  Possibly never referenced in the code.
Changes since last publication as v1.1.13:
- Upgraded config module.
Changes to be committed:
- modified: src/tasks/changes.coffee
Changes not staged for commit:
- modified: README.md
- modified: src/tasks/changes.coffee
```


### publish

With the push command you can publish your newest changes to github and npm as a
new version. The version can be set by signaling if it should be a `--major`,
`--minor` or bugfix version if no switch given.

To publish the next bugfix version only call:

``` sh
builder -c publish               # from within the package directory
builder ./node-error -c publish  # or from anywhere else
```

The output will be:

``` text
push changes to repository
push node-builder
Push to origin
remote: This repository moved. Please use the new location:
remote:   https://github.com/alinex/node-builder.git
To https://github.com/alinex/node-make
   46f16d7..34a0a61  master -> master
cleanup files
clean node-builder
Remove unnecessary folders
update and installation of package with dependent packages
update node-builder
Install through npm
Update npm packages
List outdated packages
Package               Current  Wanted     Latest  Location
Nothing to upgrade in this package found.
run automatic tests
test node-builder
Linting coffee code
Run mocha tests
  Simple mocha test
    ✓ should add two numbers
  1 passing (5ms)
create documentation pages
doc node-builder
Create html documentation
Cloning git repository
Nach »/tmp/alinex-make-2088206155« wird geklont
Checkout gh-pages branch
Zu neuem Zweig »gh-pages« gewechselt
Update documentation
Push to git origin
To https://github.com/alinex/node-builder
   bfc73a0..1114a9b  gh-pages -> gh-pages
publish package in npm
publish node-builder
Change package.json
Write new changelog
Commit new version information
Push to git origin
remote: This repository moved. Please use the new location:
remote:   https://github.com/alinex/node-builder.git
To https://github.com/alinex/node-make
   34a0a61..0fef12e  master -> master
Push new tag to git origin
remote: This repository moved. Please use the new location:
remote:   https://github.com/alinex/node-builder.git
To https://github.com/alinex/node-make
 * [new tag]         v1.0.9 -> v1.0.9
Push to npm
Created v1.0.9.
Done.
```

Like seen above this will also push last changes, cleanup, reinstall the package
compile with compression and run all tests before publishing. And the documentation
will be updated afterwards, too.

For the next minor version (second number) call:

``` sh
builder ./node-error -c publish --minor
```

And for a new major version:

``` sh
builder ./node-error -c publish --major
```

And you may use the switches `--try` to not really publish but to check if it will
be possible and `--force` to always publish also if it is not possible because of
failed tests or not up-to-date dependent packages.


### clean

Remove all automatically generated files. This will bring you to the initial
state of the system. To create a usable system you have to build it again.

To clean everything which you won't need for a production environment use
`--dist` or `--auto` to remove all automatically generated files in the
development environment.

To cleanup all safe files:

``` sh
builder -c clean                 # from within the package directory
builder ./node-error -c clean    # or from anywhere else
```

Or on the development system remove all created files:

``` sh
builder ./node-error -c clean --auto
```

And at last for production remove development files:

``` sh
builder ./node-error -c clean --dist
```


Configuration
-------------------------------------------------

The only thing you may configure using configuration files is the layout of the
documentation.

### Document Template

You may specify a different document layout by creating a file named like the
main part of your package (name till the first hyphen). Use the file
`/var/src/docstyle/default.css` as a default and store your own in
`/var/local/docstyle/<basename>.css`.

Also the javascript may be changed for each package basename in `<basename>.js`
like done for the css.


License
-------------------------------------------------

Copyright 2013-2016 Alexander Schilling

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

>  <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
