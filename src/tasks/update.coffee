# Install a package with newest node-modules
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
path = require 'path'
chalk = require 'chalk'
# include alinex modules
async = require 'alinex-async'
fs = require 'alinex-fs'
Exec = require 'alinex-exec'

# Main routine
# -------------------------------------------------
#
# __Arguments:__
#
# * `dir`
#   Directory to operate on
# * `options`
#   Command specific parameters and options.
# * `callback(err)`
#   The callback will be called just if an error occurred or with `null` if
#   execution finished.
module.exports.run = (dir, options, cb) ->
  async.series [
    (cb) -> switchRepository dir, options, cb
    (cb) -> npmInstall dir, options, cb
    (cb) -> npmUpdate dir, options, cb
    (cb) -> npmOutdated dir, options, cb
    (cb) -> switchRepository dir, {registry: 'https://registry.npmjs.org/'}, cb
  ], cb

switchRepository = (dir, options, cb) ->
  # check for changed registry
  file = path.join dir, 'package.json'
  try
    pack = JSON.parse fs.readFileSync file
  catch error
    return cb new Error "Could not load #{file} as valid JSON: #{error.message}"
  # change or change back
  registry = if options.registry then options.registry else pack.publishConfig?.registry
  registry ?= 'https://registry.npmjs.org/'
  # get old registry
  Exec.run
    cmd: 'npm'
    args: [ 'set', 'registry', registry ]
    cwd: dir
    check:
      noExitCode: true
  , cb

# ### Install necessary modules
npmInstall = (dir, options, cb) ->
  # Run external command
  console.log "Install through npm"
  async.retry 3, (cb) ->
    Exec.run
      cmd: 'npm'
      args: [ 'install' ]
      cwd: dir
      check:
        noExitCode: true
    , cb
  , cb

# ### Update all modules
npmUpdate = (dir, options, cb) ->
  # Run external command
  console.log "Update npm packages"
  Exec.run
    cmd: 'npm'
    args: [ 'update' ]
    cwd: dir
    check:
      noExitCode: true
  , cb

# ### List outdated modules
npmOutdated = (dir, options, cb) ->
  # Run external command
  console.log "List outdated packages"
  fs.npmbin 'npm-check', path.dirname(path.dirname __dirname), (err, cmd) ->
    Exec.run
      cmd: cmd
      args: ['-p']
      cwd: dir
      check:
        noExitCode: true
    , (err, proc) ->
      lines = proc.stdout().split /\n/
      if lines.length is 1
        console.log chalk.grey "Nothing to upgrade or fix in this package found."
        return cb()
      for line in lines[0..lines.length-2]
        continue unless line = line.trim()
        console.log line
      cmd = path.dirname(path.dirname __dirname) + '/bin/npm-upgrade'
      cb new Error "You may upgrade the listed modules using: #{chalk.underline cmd + ' ' + dir}"
