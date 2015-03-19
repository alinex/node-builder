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
fs = require 'fs'
yargs = require 'yargs'
path = require 'path'
chalk = require 'chalk'
async = require 'async'
# include alinex modules
Spawn = require 'alinex-spawn'
errorHandler = require 'alinex-error'
errorHandler.install()
errorHandler.config.stack.modules = true


# Setup build environment
# -------------------------------------------------

# Root directory of the core application
GLOBAL.ROOT_DIR = path.dirname __dirname
# Read in package configuration
GLOBAL.PKG = JSON.parse fs.readFileSync path.join ROOT_DIR, 'package.json'
# setup search path for configs

# list of possible commands
commands =
  list: "show the list of possible commands"
  create: "create a new package"
  update: "update and installation of package with dependent packages"
  compile: "compile code"
  pull: "pull newest version from repository"
  push: "push changes to repository"
  publish: "publish package in npm"
  doc: "create documentation pages"
  test: "run automatic tests"
  clean: "cleanup files"
  changes: "list unpublished changes"


# Start argument parsing
# -------------------------------------------------
argv = yargs
.usage("""
  Utility to help simplify tasks in development.

  Usage: $0 [-vC] -c command... [dir]...
  """)
# examples
.example('$0 -c compile -c test', 'to rerun the tests after code changes')
.example('$0 -c publish --minor',
  'to do the complete publishing cycle')
# commands
.demand('c')
.alias('c', 'command')
.array('c')
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
# publish options
.boolean('minor')
.describe('minor', 'publish: change to next minor version')
.boolean('major')
.describe('major', 'publish: change to next major version')
.boolean('try')
.describe('try', 'publish: don\'t really publish but check if it is possible')
.boolean('force')
.describe('force', 'publish: also if tests have errors or submodules not up-to-date')
# test options
.boolean('coverage')
.describe('coverage', 'test: create coverage report')
.boolean('coveralls')
.describe('coveralls', 'test: send coverage to coveralls')
.boolean('watch')
.describe('watch', 'test,doc: keep process running while watching for changes')
.boolean('browser')
.describe('browser', 'test,doc: open in browser')
# doc options
.boolean('publish')
.describe('publish', 'doc: push to github pages')
# clean options
.boolean('dist')
.describe('dist', 'clean: all which is not needed in production')
.boolean('auto')
.describe('auto', 'clean: all which is created automatically')
# general help
.help('h')
.alias('h', 'help')
.showHelpOnFail(false, "Specify --help for available options")
.epilogue("For more information, look into the man page.")
.check (argv, options) ->
  # optimize the arguments for processing
  argv._ = ['./'] unless argv._.length
  argv.command = [argv.command] unless Array.isArray argv.command
  # additional checks
  for command in argv.command
    unless command in Object.keys commands
      return "Unknown command: #{argv.command}"
  true
.strict()
.argv
# implement some global switches
chalk.enabled = false if argv.nocolors
# add additional dependent commands
cmds = []
for command in argv.command
  switch command
    when 'publish'
      # backward order because of unshift
      cmds.unshift 'test'
      cmds.unshift 'compile'
      cmds.unshift 'update'
      cmds.unshift 'clean'
      argv.auto = true
      cmds.unshift 'push'
      # and at last add the command itself and document publish
      cmds.push command
      cmds.push 'doc'
      argv.publish = true
    else
      cmds.push command


# Init config
# -------------------------------------------------



# Run the commands
# -------------------------------------------------
async.each cmds, (command, cb) ->
  # load library because it may be away later
  lib = require "./tasks/#{command}"
  cb()
, (err) ->
  throw err if err

  async.eachSeries argv._, (dir, cb) ->
    console.log chalk.blue.bold "Working on #{dir}"
    argv.done = []
    async.eachSeries cmds, (command, cb) ->
      # skip if command already done
      return cb() if command in argv.done
      # list possible commands
      if command is 'list'
        console.log "\nThe following commands are possible:\n"
        console.log "- #{key} - #{title}" for key, title of commands
        return cb()
      console.log chalk.blue commands[command]
      # check for try
      if argv.try and command is 'publish'
        console.log chalk.yellow "Publishing is possible but won't be called because of --try flag."
        return cb()
      # load task library
      lib = require "./tasks/#{command}"
      lib.run dir, argv, (err) ->
        argv.done.push command
        # log done comamnds
        if command is 'update'
          argv.done.push 'compile' # this is called by npm
        # return error
        cb if argv.force then null else err
    , (err) ->
      # protocol error on dir
      console.error chalk.bold chalk.red err if err
      # go on
      cb()
  , (err) ->
    console.log chalk.green "Done."
