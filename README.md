Alinex Builder
=================================================

[![Build Status](https://travis-ci.org/alinex/node-builder.svg?branch=master)](https://travis-ci.org/alinex/node-builder)
[![Coverage Status](https://coveralls.io/repos/alinex/node-builder/badge.png?branch=master)](https://coveralls.io/r/alinex/node-builder?branch=master)
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

After global installation you may directly call `builder` from anywhere to work
in the current or defined directory:

``` sh
builder --help
```

Or you may integrate it into your own package:

``` sh
npm install alinex-builder --save-dev
./node_modules/.bin/builder --help
```

By integrating it you won't need all the development tools within your package.

Always have a look at the latest [changes](Changelog.md).

### Bash Code completion

If you like, you can add code completion for bash by copying the output of:

``` text
> builder bashrc-script

###-begin-cli.coffee-completions-###
#
# yargs command completion script
#
# Installation: builder completion >> ~/.bashrc
#    or builder completion >> ~/.bash_profile on OSX.
#
_yargs_completions()
{
    local cur_word args type_list

    cur_word="${COMP_WORDS[COMP_CWORD]}"
    args=$(printf "%s " "${COMP_WORDS[@]}")

    # ask yargs to generate completions.
    type_list=`builder --get-yargs-completions $args`

    COMPREPLY=( $(compgen -W "${type_list}" -- ${cur_word}) )

    # if no match was found, fall back to filename completion
    if [ ${#COMPREPLY[@]} -eq 0 ]; then
      COMPREPLY=( $(compgen -f -- "${cur_word}" ) )
    fi

    return 0
}
complete -F _yargs_completions builder
###-end-cli.coffee-completions-###
```

Put these lines into your `~/.bashrc` file.


Usage
-------------------------------------------------

You can simple call the `builder` command with one of the configured commands:

    > builder <command> [<options>]...

    Initializing...
    Run the command...
    ...
    Goodbye

To list all the possible commands:

    > builder --help

This will show the possible commands which are defined. And to know more about
a specific command or it's options you may call the help on the command:

    > builder <command> --help

If not installed globally you may run it as:

``` sh
node_modules/.bin/builder <command> [<options>]...
```

Multiple directory names can be given. They specify on which project to work on.
It should point to the base package directory of a module. If not specified the
command will run from the current directory.

To run multiple commands, call the program for each one.

### Include in own package

Within your `package.json` it may look like:

``` json
{
  "scripts": {
    "prepublish": "node_modules/.bin/builder compile --uglify",
    "test": "node_modules/.bin/builder test"
  }
}
```

### General options

`-v` or `--verbose` will display a lot of information of what is going on.
This information will sometimes look discarded because of the parallel
processing of some tasks.

1. show the big actions going on
2. detailed actions with commandline calls
3. also show command output and more details

`-C` or `--no-colors` can be used to disable the colored output.

`-q` or `-quiet` is used to remove the unneccessary output like header and
footer.


Commands
----------------------------------------------------------------

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
builder create ../node-test
```

This process is interactive and will ask you some more details. After that you
may directly start to add your code.


### push

This will push the changes to the origin repository. With the `--message` option
it will also add and commit all other changes before doing so.

``` sh
builder push                  # from within the package directory
```

or to also commit the last changes

``` sh
builder push --message "commit message"
```

The push is only possible if you have the newest changes merged into your repository.
On any problems try to `pull` first before pushing your changes.

If you want to only commit some changes you have to do this on your own.

### pull

Like `push` this will fetch the newest changes from git origin and merge them with
your local changes.

``` sh
builder pull                  # from within the package directory
```

If a merge conflict occurs, you have to edit the files and solve it before a
proper push will be working again.

### link

This task will link a local package installed in a parallel directory into the
packages node_modules directory.

``` sh
builder link                  # link all alinex-... packages to their node-... folders
builder link --link alinex-config --local node-config  # or link only the config package
```

Like seen above, you can use the two options `--link` and `--local` to specify
the link. You may only use the directory name or the full path if it's not in the
default path beside your package.

### compile

This task is used to compile the sources into a runtime optimized library.

``` sh
builder compile               # from within the package directory
builder ./node-error compile  # or from anywhere else
```

``` text
Remove old directories
Compile man pages
Compile coffee script
```

Or give an directory and use uglify to compress the extension.

``` sh
builder compile --uglify
```

This command may also compiled the linked packages and does the following steps:

- compile coffee -> js (maybe with uglify)
- copy js (maybe with uglify)
- compile md -> man pages

Mostly this task will be added as prepublish script to the `package.json` like:

``` json
{
  "scripts": {
    "prepublish": "node_modules/.bin/builder compile -u"
  }
}
```

Also this will make man files from mardown documents in `src/man` if they
are referenced in the package.json.


### test

As a first test a coffeelint check will be run. Only if this won't have any
errors the automatic tests will be run.

If the [istanbul](http://gotwarlost.github.io/istanbul/) module is installed
a code coverage report will be build.
And at last code metrics will be analyzed but only on the compiled version at
the moment. You will find this reports under '/reports' directory as html.

``` sh
builder test                  # from within the package directory
builder ./node-util test      # or from anywhere else
```

This will:

- lint the coffee script code
- run mocha tests
- collect and build coverage report (option --coverage)
- send results from travis to coveralls (option --coveralls)
- run metric analyses of compiled js
- open reports in browser (option --browser)

So you may also create an html coverage report and open it:

``` sh
builder test --coverage --browser
```

If you want to stop after the  first error occurs use the `--bail` flag.

And at last you can add the `--browser` flag to open the coverage report
automatically in the browser. Also `--coveralls` may be added to send the
results from the coverage from travis to coveralls.

This task can also be added to the `package.json` to be called using `npm test`:

``` json
{
  "scripts": {
    "test": "node_modules/.bin/builder test"
  }
}
```

Attention, the metrics are build out of the compiled JavaScript. So you need to
compile your code first before the metrics are updated.

### doc

Generate the documentation this will create the documentation in the `doc`
folder. It includes the API documentation with code. Each module will get his
own documentation space with an auto generated index page.

This tool will extract the documentation from the markup and code files in
any language and generate HTML pages with the documentation beside the
code.

``` sh
builder doc                   # from within the package directory
builder ./node-error doc      # or from anywhere else
```

It is also possible to update the documentation stored on any website. To
configure this for GitHub pages, you have to do nothing, for all others you
need to specify an `doc-publish` script in `package.json`. This may be an
rsync copy job like `rsync -av --delete doc root@myserver:/var/www`.
Start the document creation with publication using:

``` sh
builder doc --publish
```

And at last you may also add the `--browser` flag to open the documentation in
the browser after created. This will wait some seconds for the remote server to
update if published.

The style of the documentation can be specified if a specific css is present
in the alinex make package. It have to be under the path `src/data` and be called
by the `<basename>.css` while basename is the package name before the first
hyphen.

### changes

This will list all changes in

- packages since last version tag
- in current commit
- and things are staged only

Use this to check if you should make a new publication or if it can wait.

``` sh
builder changes
```

``` text
Initializing...
Run changes command...

Results for node-builder

Changes since last publication as v1.2.9:
- Converted changes command to new builder.
- Use new command based cli interface.
- Upgraded lots of packages.
- Add correct exit code on test.
Changes not staged for commit:
- modified: src/command/changes.coffee
NPM Update check:
- alinex-core          😍  UPDATE!   Your local install is out of date. http://alinex.github.io/node-alinex/
                          npm install --save alinex-core (from 0.2.0 to 0.2.4)
- coffee-coverage      😕  NOTUSED?  Still using coffee-coverage?
- coffeelint           😕  NOTUSED?  Still using coffeelint?
- coveralls            😕  NOTUSED?  Still using coveralls?
- debounce             😕  NOTUSED?  Still using debounce?
- docker               😍  UPDATE!   Your local install is out of date. from 1.0.0-alpha.1 to 1.0.0-alpha.2
                          npm install --save docker (from 1.0.0-alpha.1 to 1.0.0-alpha.2)
- istanbul             😕  NOTUSED?  Still using istanbul?
- marked-man           😕  NOTUSED?  Still using marked-man?
- node-sass            😕  NOTUSED?  Still using node-sass?
- npm-check            😕  NOTUSED?  Still using npm-check?
- plato                😕  NOTUSED?  Still using plato?
- replace              😕  NOTUSED?  Still using replace?
- typescript           😕  NOTUSED?  Still using typescript?
- uglify-js            😕  NOTUSED?  Still using uglify-js?
To upgrade all use: /usr/lib/node_modules/alinex-builder/node_modules/.bin/npm-check /home/alex/github/node-builder -u
```

Sometimes you may skip the unused packages:

``` sh
builder changes --skip-unused
```

``` text
Initializing...
Run changes command...
Skip check for unused packages.

Results for node-builder

Changes since last publication as v1.2.9:
- Converted changes command to new builder.
- Use new command based cli interface.
- Upgraded lots of packages.
- Add correct exit code on test.
Changes not staged for commit:
- modified: src/command/changes.coffee
NPM Update check:
- alinex-core   😍  UPDATE!   Your local install is out of date. from 0.2.0 to 0.2.2
                    npm install --save alinex-core (from 0.2.0 to 0.2.4)
- docker        😍  UPDATE!   Your local install is out of date. from 1.0.0-alpha.1 to 1.0.0-alpha.2
                    npm install --save docker (from 1.0.0-alpha.1 to 1.0.0-alpha.2)
Use `npm install` or `/home/alex/github/node-builder/node_modules/.bin/npm-check -u` to upgrade.
```

### publish

With the push command you can publish your newest changes to github and npm as a
new version. The version can be set by signaling if it should be a `--major`,
`--minor` or bugfix version if no switch given. Alternatively you can specify the
new veriosn directly using `--version`.

To publish the next bugfix version only call:

``` sh
builder publish               # from within the package directory
builder ./node-error publish  # or from anywhere else
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
builder publish --minor
```

And for a new major version:

``` sh
builder publish --major
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
builder clean                 # from within the package directory
builder ./node-error clean    # or from anywhere else
```

Or on the development system remove all created files:

``` sh
builder clean --auto
```

And at last for production remove development files:

``` sh
builder clean --dist
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
