# Task to run build process
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
  # npm install
  # --watch
  if commander.verbose
    console.log "Read package.json".grey
  pack = JSON.parse fs.readFileSync path.join command.dir, 'package.json'
  unless pack.scripts?.prepubish?
    console.error "Skipped because no prepublication script added".yellow
    return cb()
  console.log "Run prepublication script"
  args = pack.scripts.test.split /\s+/
  cmd = args.shift()
  proc = spawn cmd, args, { cwd: command.dir, stdio: 'inherit' }
  # Error management
  proc.on 'error', cb
  proc.on 'exit', (status) ->
    if status != 0
      status = new Error "Coffeelint exited with status #{status}"
    cb status

