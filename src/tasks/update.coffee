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
    (cb) -> npmUpdate dir, options, cb
  ], cb

# ### Run lint against coffee script
npmInstall = (dir, options, cb) ->
  # Run external command
  console.log "Install through npm"
  proc = new Spawn
    cmd: 'npm'
    args: [ 'install' ]
    cwd: dir
    input: 'inherit'
    check: (proc) -> new Error "Got exit code of #{proc.code}" if proc.code
  proc.run cb

# ### Run lint against coffee script
npmUpdate = (dir, options, cb) ->
  # Run external command
  console.log "Update npm packages"
  proc = new Spawn
    cmd: 'npm'
    args: [ 'update' ]
    cwd: dir
    input: 'inherit'
    check: (proc) -> new Error "Got exit code of #{proc.code}" if proc.code
  proc.run cb
