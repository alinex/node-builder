# Task to compile source files like needed
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
async = require 'async'
fs = require 'fs-extra'
path = require 'path'
colors = require 'colors'
{execFile} = require 'child_process'

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
  # check for existing source files
  src = path.join command.dir, 'src'
  unless fs.existsSync src
    return cb "No source files found."
  # cleanup old files
  lib = path.join command.dir, 'lib'
  console.log "Remove old lib directory"
  fs.remove lib, (err) ->
    return cb err if err
    # run coffee script compile  
    #tmp = 
    console.log "Compile coffee script files"
    execFile "node_modules/.bin/coffee", [ '-c', '-m', '-o', lib, src ]
    , { cwd: command.dir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and commander.verbose
      console.error stderr.trim().magenta if stderr
      cb err

# compile 
