# Push new version  to GitHub and npm
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
async = require 'async'
fs = require 'fs'
path = require 'path'
colors = require 'colors'
{spawn} = require 'child_process'

# Main routine
# -------------------------------------------------
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
module.exports.run = (commander, command, cb) ->
  coffeelint commander, command, (err) ->
    return cb err if err
    test commander, command, cb

# ### Run lint against coffee script
coffeelint = (commander, command, cb) ->
  # Check for existing command
  coffeelint = path.join GLOBAL.ROOT_DIR, "node_modules/.bin/coffeelint"
  unless fs.existsSync coffeelint
    console.log "Skipped lint because coffeelint is missing".yellow
    return cb?()
  # Run external command
  if commander.verbose
    console.log "Linting code".grey
  if commander.colors
    proc = spawn coffeelint, [
      '-f', path.join GLOBAL.ROOT_DIR, 'coffeelint.json'
      'src'
    ], { cwd: command.dir, stdio: 'inherit' }
  else
    proc = spawn coffeelint, [
      '-f', path.join GLOBAL.ROOT_DIR, 'coffeelint.json'
      'src'
    ], { cwd: command.dir }
    proc.stdout.on 'data', (data) ->
  #    unless ~data.toString().indexOf "Done."
      if commander.verbose
        console.log data.toString().trim()
    proc.stderr.on 'data', (data) ->
      console.error data.toString().trim()
  # Error management
  proc.on 'error', cb
  proc.on 'exit', (status) ->
    if status != 0
      status = new Error "Coffeelint exited with status #{status}"
    cb status


# ###
test = (commander, command, cb) ->
  if commander.verbose
    console.log "Read package.json".grey
  pack = JSON.parse fs.readFileSync path.join command.dir, 'package.json'
  return cb() unless pack.scripts?.test?
  console.log "Run test scripts"
  args = pack.scripts.test.split /\s+/
  cmd = args.shift()
  proc = spawn cmd, args, { cwd: command.dir, stdio: 'inherit' }
  # Error management
  proc.on 'error', cb
  proc.on 'exit', (status) ->
    if status != 0
      status = new Error "Coffeelint exited with status #{status}"
    cb status

