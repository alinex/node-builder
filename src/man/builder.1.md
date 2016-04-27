Alinex Development Utils
=================================================

The builder helps you to develop node modules.


Usage
-------------------------------------------------

    builder <command> [options] [dir]...

You can give the following commands:

    create   create a new package (interactive)  changes  show changes since last release
    clean    cleanup files
    compile  compile code
    doc      create api documentation
    link     replace released package with locally linked module
    publish  publish package in npm
    pull     pull newest version from repository
    push     push changes to remote repository
    test     run automatic tests

General Options:

    --help, -h      Show help                                            [boolean]
    --nocolors, -C  turn of color output                                 [boolean]
    --verbose, -v   run in verbose mode (multiple makes more verbose)      [count]
    --quiet, -q     don't output header and footer                       [boolean]

Examples:

    builder test -vb            to run the tests till first failure
    builder test -v --coverage  to run all the tests and also show
    --browser                   coverage info
    builder changes             show overview of changes
    builder publish --minor     to publish on npm new minor version

You may use environment variables prefixed with 'BUILDER_' to set any of
the options like 'BUILDER_VERBOSE' to set the verbose level.

For help for a specific command call:

    builder <command> --help

This will show also the specific options, only available for this command.


Commands and options
-------------------------------------------------

The tool will be called with

    builder [dirs] [general options] -c <command> [command options]

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

### General options

`-v` or `--verbose` will display a lot of information of what is going on.
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

    > builder ./node-error -c create --package alinex-error
    > builder ./private-module -c create --private

This process is interactive and will ask you some more details. After that you
may directly start to add your code.


### Command `push`

This will push the changes to the origin repository. With the `--message` option
it will also add and commit all other changes before doing so.

    > builder -c push                  # from within the package directory
    > builder ./node-error -c push     # or from anywhere else

or to also commit the last changes

    > builder -c push ./node-error --message "commit message"


### Command `pull`

Like `push` this will fetch the newest changes from git origin.

    > builder -c pull                  # from within the package directory
    > builder ./node-error -c pull     # or from anywhere else

    Pull from origin
    Von https://github.com/alinex/node-make
     * branch            master     -> FETCH_HEAD


### Command `link`

This task will link a local package installed in a parallel directory into the
packages node_modules directory.

    > builder -c link                  # link all node-... as alinex-...  packages
    > builder -c link --locale config  # or link only the config package


### Command `compile`

This task is used to compile the sources into for runtime optimized library.

    > builder -c compile               # from within the package directory
    > builder ./node-error -c compile  # or from anywhere else

    Remove old directories
    Compile man pages
    Compile coffee script


Or give an directory and use uglify to compress the **just now experimental**
extension. It works for live server but will break source maps for node-error
and makes your coverage report unreadable.

    > builder ./node-error -c compile  --uglify

Mostly this task will be added as prepublish script to the `package.json` like:

    "scripts": {
      "prepublish": "node_modules/.bin/builder -c compile -u"
    }

Also this will make man files from mardown documents in `src/man` if they
are referenced in the package.json.


### Command `update`

This task is a handy addition to include the npm install and npm update commands:

    > builder -c update               # from within the package directory
    > builder ./node-error -c update  # or from anywhere else

At the end this task will list all direct subpackages which are outdated and may
be updated in the package.json.

    update and installation of package with dependent packages
    update ./
    Install through npm
    Update npm packages
    List outdated packages
    Package               Current  Wanted     Latest  Location
    Nothing to upgrade in this package found.
    Done.


### Command `test`

As a first test a coffeelint check will be run. Only if this won't have any
errors the automatic tests will be run.

If the [istanbul](http://gotwarlost.github.io/istanbul/) module is installed
a code coverage report will be build.

    > builder -c test                  # from within the package directory
    > builder ./node-error -c test     # or from anywhere else

    Linting coffee code
    Run mocha tests

      Simple mocha test
        ✓ should add two numbers

      1 passing (9ms)

Or to contineously watch it:

    > builder ./node-error -c test --watch

You may also create an html coverage report:

    > builder -c test --coverage

And at last you can add the `--browser` flag to open the coverage report
automatically in the browser. Also `--coveralls` may be added to send the
results to coveralls.

This task can also be added to the `package.json` to be called using `npm test`:

    "scripts": {
      "test": "node_modules/.bin/builder test"
    }


### Command: `doc`

Generate the documentation this will create the documentation in the `doc`
folder. It includes the API documentation with code. Each module will get his
own documentation space with an auto generated index page.

This tool will extract the documentation from the markup and code files in
any language and generate HTML pages with the documentation beside the
code.

    > builder -c doc                   # from within the package directory
    > builder ./node-error -c doc      # or from anywhere else

    Create html documentation
    Done.

It is also possible to update the documentation stored on any website. To
configure this for GitHub pages, you have to do nothing, for all others you
need to specify an `doc-publish` script in `package.json`. This may be an
rsync copy job like `rsync -av --delete doc root@myserver:/var/www`.
Start the document creation with publication using:

    > builder ./node-error -c doc --publish

With the `--watch` option it is possible to keep the documentation updated.

    > builder ./node-error -c doc  --watch

But this process will never end, you have to stop it manually to end it.

And at last you may also add the `--browser` flag to open the documentation in
the browser after created.

The style of the documentation can be specified if a specific css is present
in the alinex make package. It have to be under the path `src/data` and be called
by the `<basename>.css` while basename is the package name before the first
hyphen.


### Command `changes`

This will list all changes (checkins) which are done since the last publication.
Use this to check if you should make a new publication or if it can wait.

    > builder -c changes

    Changes since last publication:
    - Small bugfix in creating docs for non alinex packages.
    - Fixed internal links in documentation.
    - Changed created script calls to support newer make.
    - Updated to use newest make version in created files.
    - Fixed create task which was completely buggy since last rewrite.


### Command `publish`

With the push command you can publish your newest changes to github and npm as a
new version. The version can be set by signaling if it should be a `--major`,
`--minor` or bugfix version if no switch given.

To publish the next bugfix version only call:

    > builder -c publish               # from within the package directory
    > builder ./node-error -c publish  # or from anywhere else

    Change package.json
    Write new changelog
    Commit new version information
    Push to git origin
    To https://github.com/alinex/node-make
       a06c5ec..c93df17  master -> master
    Push new tag to git origin
    To https://github.com/alinex/node-make
     * [new tag]         v0.4.6 -> v0.4.6
    Push to npm
    Created v0.4.6.


For the next minor version (second number) call:

    > builder ./node-error -c publish --minor

And for a new major version:

    > builder ./node-error -c publish --major

And you may use the switches `--try` to not really publish but to check if it will
be possible and `--force` to always publish also if it is not possible because of
failed tests or not up-to-date dependent packages.


### Command: `clean`

Remove all automatically generated files. This will bring you to the initial
state of the system. To create a usable system you have to build it again.

To clean everything which you won't need for a production environment use
`--dist` or `--auto` to remove all automatically generated files in the
development environment.

To cleanup all safe files:

    > builder -c clean                 # from within the package directory
    > builder ./node-error -c clean    # or from anywhere else

Or on the development system remove all created files:

    > builder ./node-error -c clean --auto

And at last for production remove development files:

    > builder ./node-error -c clean --dist


Configuration
-------------------------------------------------

### Document Template

You may specify a different document layout by creating a file named like the
main part of your package (name till the first hyphen). Use the file
`/var/src/docstyle/default.css` as a default and store your own in
`/var/local/docstyle/<basename>.css`.

Also the javascript may be changed for each package basename in `<basename>.js`
like done for the css.


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
