Alinex Development Utils
=================================================

The builder helps you to develop node modules.


Usage
-------------------------------------------------

    builder [-vC] -c command... [dir]...

You can give the following commands:

    - list - show the list of possible commands
    - create - create a new package
    - update - update and installation of package with dependent packages
    - compile - compile code
    - pull - pull newest version from repository
    - push - push changes to repository
    - publish - publish package in npm
    - doc - create documentation pages
    - test - run automatic tests
    - clean - cleanup files
    - changes - list unpublished changes

And the available options are:

    -c, --command   command to execute (use list to see more)           [required]
    -C, --nocolors  turn of color output
    -v, --verbose   run in verbose mode
    --private       create: private repository
    --package       create: set package name
    -m, --message   push: text for commit message
    -u, --uglify    compile: run uglify for each file
    --minor         publish: change to next minor version
    --major         publish: change to next major version
    --try           publish: don't really publish but check if it is possible
    --force         publish: also if tests have errors or submodules not
                    up-to-date
    --coverage      test: create coverage report
    --coveralls     test: send coverage to coveralls
    --watch         test,doc: keep process running while watching for changes
    --browser       test,doc: open in browser
    --publish       doc: push to github pages
    --dist          clean: all which is not needed in production
    --auto          clean: all which is created automatically
    -h, --help      Show help


Commands and options
-------------------------------------------------

The tool will be called with

    builder [general options] -c <command> [command options] [dirs]

With the option `--help` a screen explaining all commands and options will be
displayed. The major commands will be described here.

Multiple directory names can be given. They specify on which project to work on.
It should point to the base package directory of a module. If not specified the
command will run from the current directory.

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

    > builder -c create ./node-error --package alinex-error
    > bulder -c create ./private-module --private

This process is interactive and will ask you some more details. After that you
may directly start to add your code.


### Command `push`

This will push the changes to the origin repository. With the `--message` option
it will also add and commit all other changes before doing so.

    > builder -c push                  # from within the package directory
    > builder -c push ./node-error     # or from anywhere else

or to also commit the last changes

    > builder -c push ./node-error --message "commit message"


### Command `pull`

Like `push` this will fetch the newest changes from git origin.

    > builder -c pull                  # from within the package directory
    > builder -c pull ./node-error     # or from anywhere else

    Pull from origin
    Von https://github.com/alinex/node-make
     * branch            master     -> FETCH_HEAD


### Command `compile`

This task is used to compile the sources into for runtime optimized library.

    > builder -c compile               # from within the package directory
    > builder -c compile ./node-error  # or from anywhere else

    Remove old directories
    Compile man pages
    Compile coffee script


Or give an directory and use uglify to compress the **just now experimental**
extension. It works for live server but will break source maps for node-error
and makes your coverage report unreadable.

    > builder -c compile ../node-error --uglify

Mostly this task will be added as prepublish script to the `package.json` like:

    "scripts": {
      "prepublish": "node_modules/.bin/builder -c compile -u"
    }

Also this will make man files from mardown documents in `src/man` if they
are referenced in the package.json.


### Command `update`

This task is a handy addition to include the npm install and npm update commands:

    > builder -c update               # from within the package directory
    > builder -c update ./node-error  # or from anywhere else

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
    > builder -c test ./node-error     # or from anywhere else

    Linting coffee code
    Run mocha tests

      Simple mocha test
        ✓ should add two numbers

      1 passing (9ms)

Or to contineously watch it:

    > builder -c test ./node-error --watch

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
    > builder -c doc ./node-error      # or from anywhere else

    Create html documentation
    Done.

It is also possible to update the documentation stored on any website. To
configure this for GitHub pages, you have to do nothing, for all others you
need to specify an `doc-publish` script in `package.json`. This may be an
rsync copy job like `rsync -av --delete doc root@myserver:/var/www`.
Start the document creation with publication using:

    > builder -c doc ./node-error --publish

With the `--watch` option it is possible to keep the documentation updated.

    > bin/make doc ../node-error --watch

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
    > builder -c publish ./node-error  # or from anywhere else

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

    > builder -c publish ../node-error --minor

And for a new major version:

    > builder -c publish ../node-error --major

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
    > builder -c clean ./node-error    # or from anywhere else

Or on the development system remove all created files:

    > builder -c clean ../node-error --auto

And at last for production remove development files:

    > builder -c clean ../node-error --dist


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
