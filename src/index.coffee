# Startup script
# =================================================
# This file is used to manage the whole build environment.
#
# ### Main routine
#
# This file defines the command line interface with the defined commands. They
# will be run in parallel as possible.
#
# It will work with an boolean `success` value which is handed through the
# functions to define if everything went correct or something was not possible.
# If an real and unexpected error occur it will be thrown. All errors which
# aren't caught will end in an error and abort with exit code 2.
#
# ### Task libraries
#
# Each task is made available as separate task module with the `run` method
# to be called for each alinex package. The given command on the command line
# call may trigger multiple tasks which are done.
#
# Each task will get a `command` object which holds all the information from the
# command line call.


# Node Modules
# -------------------------------------------------

# include base modules
yargs = require 'yargs'
fs = require 'fs'
path = require 'path'
chalk = require 'chalk'
async = require 'async'
# include alinex modules
errorHandler = require 'alinex-error'
errorHandler.install()
errorHandler.config.stack.modules = true


# Setup build environment
# -------------------------------------------------

# Root directory of the core application
GLOBAL.ROOT_DIR = path.dirname __dirname
# Read in package configuration
GLOBAL.PKG = JSON.parse fs.readFileSync path.join ROOT_DIR, 'package.json'

# set the process title
process.title = 'alinex-make'

# list of possible commands
commands =
  list: "show the list of possible commands"
  create: "create a new package"
  install: "installation of package with dependent packages"
  compile: "compile code"
  pull: "pull newest version from repository"
  push: "push changes to repository"
  publish: "publish package in npm"
  doc: "create documentation pages"
  test: "run automatic tests"
  clean: "cleanup files"


# Start argument parsing
# -------------------------------------------------
argv = yargs
.usage("""
  Utility to help simplify tasks in development.

  Usage: $0 [-vC] -c command... [dir]...
  """)
# examples
.example('$0 -c compile -c test', 'to rerun the tests after code changes')
.example('$0 -c install --update -c test -c push -c publish --minor -c doc --publish',
  'to do the complete publishing cycle')
# commands
.demand('c')
.alias('c', 'command')
.describe('c', 'command to execute (use list to see more)')
# general options
.boolean('C')
.alias('C', 'nocolors')
.describe('C', 'turn of color output')
.boolean('v')
.alias('v', 'verbose')
.describe('v', 'run in verbose mode')
# create options
.describe('private', 'create: private repository')
.describe('package', 'create: set package name')
# push options
.alias('m', 'message')
.describe('m', 'push: text for commit message')
# compile options
.alias('u', 'uglify')
.describe('u', 'compile: run uglify for each file')
# install options
.describe('update', 'install: update packages to newest possible version')
# publish options
.describe('minor', 'publish: change to next minor version')
.describe('major', 'publish: change to next major version')
# publish options
.describe('coverage', 'test: create coverage report')
.describe('coveralls', 'test: send coverage to coveralls')
.describe('watch', 'test,doc: keep process running while watching for changes')
.describe('browser', 'test,doc: open in browser')
# doc options
.describe('publish', 'doc: push to github pages')
# clean options
.describe('dist', 'clean: all which is not needed in production')
.describe('auto', 'clean: all which is created automatically')
# general help
.help('h')
.alias('h', 'help')
.showHelpOnFail(false, "Specify --help for available options")
.check (argv, options) ->
  # optimize the arguments for processing
  argv._ = ['./'] unless argv._.length
  argv.command = [argv.command] unless Array.isArray argv.command
  # additional checks
  for command in argv.command
    unless command in Object.keys commands
      return "Unknown command: #{argv.command}"
  true
.argv
argv.done = []
# implement some global switches
chalk.enabled = false if argv.nocolors
# add additional dependent commands
cmds = []
for command in argv._
  switch command
    when 'publish'
      cmds.push 'push'
  cmds.push command
argv._ = cmds


# Run the commands
# -------------------------------------------------
async.eachSeries argv.command, (command, cb) ->
  # skip if command already done
  return cb() if command in argv.done
  console.log chalk.blue.bold commands[command]
  # list possible commands
  if command is 'list'
    console.log "\nThe following commands are possible:\n"
    console.log "- #{key} - #{title}" for key, title of commands
    return cb()
  # load task library
  lib = require "./#{command}Task"
  # run modules in parallel for each directory
  async.eachSeries argv._, (dir, cb) ->
    console.log chalk.blue "#{command} #{dir}"
    lib.run dir, argv, cb
  , (err) ->
    return cb err if err
    argv.done.push command
    if command is 'install'
      argv.done.push 'compile' # this is called by npm
    cb()
, (err) ->
  throw err if err
  # check for existing command
  console.log chalk.green "Done."
