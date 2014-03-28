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


# Node Modules
# -------------------------------------------------

errorHandler = require './errorHandler'
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

  console.log command._description.blue.bold
  # load task library
  lib = require './' + command._name + 'Task'
  # run modules in parallel
  if commander.verbose?
    console.log "Processing".bold
  lib.run commander, command, (err) ->
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
.option('-P, --password <name>', 'Password to use on github')
.action (dir, options) ->
  options.dir = dir
  options.package ?= path.basename dir
  options.user = 'alinex'
  run commander, options, -> process.exit 0

# ### Push to GitHub and npm
commander.command('push <dir>')
.description('Create new node module')
.option('--major', 'Create new major version')
.option('--minor', 'Create new minor version')
.action (dir, options) ->
  options.dir = dir
  run commander, options, -> process.exit 0

# ### Push to GitHub and npm
commander.command('doc <dir>')
.description('Create new API documentation for module')
.option('-w, --watch', 'Keep the process running, watch for changes and process updated files')
.option('-p, --publish', 'Push to github pages')
.option('-b, --browser', 'Open in browser')
.action (dir, options) ->
  options.dir = dir
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








process.exit


















# Find local development packages
# -------------------------------------------------
# This is done looking into all direct included npm packages and collecting
# all that hare added using a symbolic link.
#
# The list of packages maybe filtered by specifying a specific one using the
# `-p` or `--package` option.
getDevelPackages = (command, cb) ->
  return packages if packages?.length
  packages['.'] = GLOBAL.PKG if not command.package or command.package is 'core'
  async.each fs.readdirSync(path.join GLOBAL.MODULES), (file, cb) ->
    info = path.join GLOBAL.MODULES, file, 'package.json'
    fs.exists info, (exists) ->
      return cb() unless exists
      fs.lstat info, (err, stats) ->
        return cb err if err
        info = JSON.parse fs.readFileSync info
        if stats.isSymbolicLink() and ( not command.package or command.package is  info.name )
          packages[path.join GLOBAL.MODULES, file] = info
        cb()
  , (err) ->
    throw err if err
    cb packages

# Storage of collected packages
packages = []



# Run task library (for each package)
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
#
# First this will call the `pre` method if exported  with the core package data
# to do some preprocessing before calling the `run` method of the task library
# for each module including the core.  Also if a `post` function is exported
# this will be executed at the end.
runPack = (commander, command, cb) ->
  colors.mode = 'none' unless commander.colors

  console.log command._description.blue.bold
  # load task library
  lib = require './' + command._name + 'Task'
  # create list of jobs
  jobs = []
  # run pre processing if defined
  if lib.pre?
    jobs.push (cb) ->
      if commander.verbose?
        console.log "Preprocessing".bold
      lib.pre commander, command, PKG.name, '.', cb
  # run modules in parallel
  getDevelPackages command, (packages) ->
    modules = []
    for dir, info of packages
      modules.push [info.name, dir]
    jobs.push (cb) ->
      if commander.verbose?
        console.log "Processing".bold
      async.each modules, (entry, cb) ->
        lib.run commander, command, entry[0], entry[1], cb
      , cb
    # run post processing if defined
    if lib.post?
      jobs.push (cb) ->
        if commander.verbose?
          console.log "Postprocessing".bold
        lib.post commander, command, PKG.name, '.', cb
    # run queue
    async.series jobs, (err) ->
      errorHandler.exit err if err
      console.log 'Done'.green
      cb()


# Command definition
# -------------------------------------------------

# ### Clean up automatic generated files
commander.command('clean')
.description('Cleanup all automatic generated data')
.option('-w, --watch', 'Keep the process running, watch for changes and process updated files')
.option('-p, --package <name>', 'Only work on the given module', )
.action (options) -> runPack commander, options, -> process.exit 0

# ### Build running system
#
# Therefore server and client files will be transformed/compiled.
commander.command('build')
.description('Build running system')
.option('-w, --watch', 'Keep the process running, watch for changes and process updated files')
.option('-p, --package <name>', 'Only work on the given module', )
.action (options) -> runPack commander, options, -> process.exit 0

# ### Run test and lint
commander.command('test')
.description('Run automatic tests')
.option('-w, --watch', 'Keep the process running, watch for changes and process updated files')
.option('-p, --package <name>', 'Only work on the given module', )
.action (options) -> runPack commander, options, -> process.exit 0

# ### Create new module
commander.command('github')
.description('Update GitHub repository')
.option('-P, --password <password>', 'GitHub password')
.action ->
  unless commander.name
    console.error "To update the GitHub repository the --password for user #{ 'xxx' } is needed.".red
    process.exit -1
  run commander, { options: options }
  , 'create', 'Update GitHub repository', ->
    process.exit 0




# ### Copy config files
#
# Copy default config files if not existent.
commander.command('config')
.description('Copy config files')
.action ->
  run commander, null, 'config', 'Copy config files', ->
    process.exit 0

# ###
commander.command('inspector')
.description('Start system using inspector')
.action ->
#  if commander.required?
#    run commander, 'build', 'Build running system', ->
#    process.exit 0

  process.exit if success then 0 else 1

# ###
commander.command('run')
.description('Start development system')
.action ->
  success = true
  if commander.required?
    await run commander, null, 'build', 'Build running system', defer success

  process.exit if success then 0 else 1

# ###
commander.command('pack')
.description('Package system to be deployed')
.action ->
  success = true
  if commander.required?
    await run commander, null, 'build', 'Build running system', defer success
  if success
    await run commander, null, 'pack', 'Package system to be deployed', defer success
  process.exit if success then 0 else 1

# ###
commander.command('deploy')
.description('Deploy package onto server')
.action ->
  success = true
  if commander.required?
    await run commander, null, 'build', 'Build running system', defer success
  run commander, null, 'deploy', 'Deploy package onto server'
  process.exit if success then 0 else 1


