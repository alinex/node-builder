# Task to run build process
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
async = require 'async'
fs = require 'fs'
path = require 'path'
colors = require 'colors'
{spawn,execFile} = require 'child_process'

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
  console.log "Install npm modules"
  execFile 'npm', [ 'install' ], { cwd: command.dir }
  , (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and commander.verbose
    console.error stderr.trim().magenta if stderr and commander.verbose
    return cb err if err
    console.log "Update npm modules"
    execFile 'npm', [ 'update' ], { cwd: command.dir }
    , (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and commander.verbose
      console.error stderr.trim().magenta if stderr and commander.verbose
      return cb err if err
      console.log "Reduce module duplication"
      execFile 'npm', [ 'dedupe' ], { cwd: command.dir }
      , (err, stdout, stderr) ->
        console.log stdout.trim().grey if stdout and commander.verbose
        console.error stderr.trim().magenta? if stderr and commander.verbose
        return cb err if err or command.watch
        unless pack.scripts?.prepublish?
          console.log "Skipped watching because no prepublish defined in package.json".yellow
          return cb()
        console.log "Start watching... stop using ctrl-c".bold
        args = pack.scripts.prepublish.split /\s+/
        cmd = args.shift()
        args.unshift '-w'
        proc = spawn cmd, args, { cwd: command.dir, stdio: 'inherit' }
        # Error management
        proc.on 'error', cb
        proc.on 'exit', (status) ->
          if status != 0
            status = new Error "Coffeescript compile failed with status #{status}"
          cb status
