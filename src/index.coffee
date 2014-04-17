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

errorHandler = require 'alinex-error'
errorHandler.install()

# include base modules
commander = require 'commander'
fs = require 'fs'
path = require 'path'
colors = require 'colors'
async = require 'async'


# Setup build environment
# -------------------------------------------------

# Root directory of the core application
GLOBAL.ROOT_DIR = path.dirname __dirname
# Read in package configuration
GLOBAL.PKG = JSON.parse fs.readFileSync path.join ROOT_DIR, 'package.json'

# set the process title
process.title = 'alinex-make'


# Run task library
# -------------------------------------------------
# Load the defined task library and run it for all alinex packages.
#
# __Arguments:__
#
# * `commander`
#   Commander instance for reading options.
# * `command`
#   Command specific parameters and options.
# * `callback(err)`
#   The callback will be called just if an error occurred or with `null` if
#   execution finished.
run = (commander, command, cb) ->
  colors.mode = 'none' unless commander.colors
  command.colors = commander.colors
  command.verbose = commander.verbose
  console.log command._description.blue.bold
  # load task library
  lib = require './' + command._name + 'Task'
  # run modules in parallel
  lib.run command, (err) ->
    errorHandler.report err if err
    console.log "Done.".green
    cb()


# Command setup
# -------------------------------------------------
# Setup the command line interface with options.
#
# The call syntax looks like:
#
#     bin/make.sh [general options] <command> [command options] [additional arguments]
#
#process.argv[1] = 'bin/make.sh' if path.basename process.argv[1] is 'index.coffee'
commander
.version(PKG.name + ' V ' + PKG.version + ' by ' + PKG.copyright)
.option('-v, --verbose', 'Run in verbose mode')
.option('-C, --no-colors', 'Turn colors off')
.on '--help', ->
  console.log """
    ---------------------------------------------------------------------

      Command help:

        $ #{process.argv[1]} [command] --help

      This will show command specific help including special options
      and arguments which may be given after the command.

    """

# ### Create new module
commander.command('create <dir>')
.description('Create new node module')
.option('-p, --package <name>', 'Create the given module')
.option('-p, --private', 'Create a private repository')
.action (dir, options) ->
  options.dir = dir
  options.package ?= path.basename dir
  options.user = 'alinex'
  run commander, options, -> process.exit 0

# ### Push to GitHub
commander.command('push [dir]')
.description('Push to git origin')
.option('-m, --message <message>', 'Give comment to commit')
.action (dir, options) ->
  options.dir = dir ? '.'
  run commander, options, -> process.exit 0

# ### Push to GitHub
commander.command('pull [dir]')
.description('Pull from git origin')
.action (dir, options) ->
  options.dir = dir ? '.'
  run commander, options, -> process.exit 0

# ### Compile the code as necessary
commander.command('compile [dir]')
.description('Compile the code as necessary')
.option('-u, --uglify', 'Use uglify to compress')
.action (dir, options) ->
  options.dir = dir ? '.'
  run commander, options, -> process.exit 0

# ### Publish to GitHub and npm
commander.command('publish [dir]')
.description('Create new node module')
.option('--major', 'Create new major version')
.option('--minor', 'Create new minor version')
.action (dir, options) ->
  options.dir = dir ? '.'
  run commander, options, -> process.exit 0

# ### Build running system
commander.command('test [dir]')
.description('Run automatic tests')
.option('-w, --watch', 'Keep the process running, watch for changes and process again')
.option('-b, --browser', 'Open in browser')
.action (dir, options) ->
  options.dir = dir ? '.'
  run commander, options, -> process.exit 0

# ### Create documentation
commander.command('doc [dir]')
.description('Create new API documentation for module')
.option('-w, --watch', 'Keep the process running, watch for changes and process updated files')
.option('-p, --publish', 'Push to github pages')
.option('-b, --browser', 'Open in browser')
.action (dir, options) ->
  options.dir = dir ? '.'
  run commander, options, -> process.exit 0

# ### Cleanup automatic created files
commander.command('clean [dir]')
.description('Cleanup automatic generated files')
.option('-d, --dist', 'Clean all which is not needed in production')
.option('-a, --auto', 'Clean all which is automatically generated')
.action (dir, options) ->
  if options.dist and options.auto
    console.error "Don't use both switches --dist and --auto together, that destroys your code."
    process.exit 2
  options.dir = dir ? '.'
  run commander, options, -> process.exit 0



# Run commands
# -------------------------------------------------
# Call the command line parsing and the given command.
commander.parse process.argv

# check that it works properly
unless commander.args.length
  console.error "No valid command given show help using --help switch.".red
  process.exit -1
if typeof commander.args[commander.args.length-1] is 'string'
  console.error "Command '#{commander.args[0]}' not found use --help switch.".red
  process.exit -1

