# Install a package with newest node-modules
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
debug = require('debug')('make:test')
async = require 'async'
fs = require 'alinex-fs'
path = require 'path'
colors = require 'colors'
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
  ], (err) ->
    throw err if err
    cb()

# ### Run lint against coffee script
npmInstall = (dir, options, cb) ->
  # Run external command
  console.log "Install through npm"
  debug "exec #{dir}> npm install"
  if options.nocolors
    proc = spawn 'npm', [ 'install' ], { cwd: dir, stdio: 'inherit' }
  else
    proc = spawn 'npm', [ 'install' ], { cwd: dir }
    proc.stdout.on 'data', (data) ->
      if options.verbose
        console.log data.toString().trim()
    proc.stderr.on 'data', (data) ->
      console.error data.toString().trim().magenta
  # Error management
  proc.on 'error', cb
  proc.on 'exit', (status) ->
    argv.done.push 'compile' # this is called by npm
    if status != 0
      status = "npm exited with status #{status}"
    cb status

# ### Run lint against coffee script
npmUpdate = (dir, options, cb) ->
  return cb() unless options.update
  # Run external command
  console.log "Update npm packages"
  debug "exec #{dir}> npm update"
  if options.nocolors
    proc = spawn 'npm', [ 'update' ], { cwd: dir, stdio: 'inherit' }
  else
    proc = spawn 'npm', [ 'update' ], { cwd: dir }
    proc.stdout.on 'data', (data) ->
      if options.verbose
        console.log data.toString().trim()
    proc.stderr.on 'data', (data) ->
      if options.verbose
        console.error data.toString().trim().magenta
  # Error management
  proc.on 'error', cb
  proc.on 'exit', (status) ->
    if status != 0
      console.log "npm update exited with status #{status}".red
    cb()
