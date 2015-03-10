# Install a package with newest node-modules
# =================================================


# Node modules
# -------------------------------------------------

# include alinex modules
Spawn = require 'alinex-spawn'
# include base modules
async = require 'async'
fs = require 'alinex-fs'
path = require 'path'
chalk = require 'chalk'
{spawn,exec, execFile} = require 'child_process'

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
    (cb) -> npmInstall dir, options, cb
    (cb) -> npmUpdate dir, options, cb
    (cb) -> npmOutdated dir, options, cb
  ], cb

# ### Install necessary modules
npmInstall = (dir, options, cb) ->
  # Run external command
  console.log "Install through npm"
  proc = new Spawn
    priority: 9
    cmd: 'npm'
    args: [ 'install' ]
    cwd: dir
    input: 'inherit'
    check: (proc) -> new Error "Got exit code of #{proc.code}" if proc.code
  proc.run cb

# ### Update all modules
npmUpdate = (dir, options, cb) ->
  # Run external command
  console.log "Update npm packages"
  proc = new Spawn
    priority: 9
    cmd: 'npm'
    args: [ 'update' ]
    cwd: dir
    input: 'inherit'
    check: (proc) -> new Error "Got exit code of #{proc.code}" if proc.code
  proc.run cb

# ### List outdated modules
npmOutdated = (dir, options, cb) ->
  # Run external command
  console.log "List outdated packages"
  proc = new Spawn
    priority: 9
    cmd: 'npm'
    args: [ 'outdated' ]
    cwd: dir
    input: 'inherit'
    check: (proc) -> new Error "Got exit code of #{proc.code}" if proc.code
  proc.run (err, stdout) ->
    num = -1 # start negative because header line is always there
    for line in stdout.split /\n/
      continue if not line or line.match /\s>\s/
      console.log line
      num++
    if num
      return cb new Error "You may upgrade the listet modules."
    console.log chalk.grey "Nothing to upgrade in this package found."
    cb()
