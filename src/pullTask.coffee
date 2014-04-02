# Task to pull changes from git origin
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
async = require 'async'
fs = require 'fs'
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
  if commander.verbose
    console.log "Read package.json".grey
  pack = JSON.parse fs.readFileSync path.join command.dir, 'package.json'
  unless pack.repository.type is 'git'
    return cb "Only git repositories can be pulled."
  console.log "Pull from origin"
  execFile "git", [ 'pull', 'origin', 'master' ]
  , { cwd: command.dir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and commander.verbose
    console.error stderr.trim().magenta if stderr
    cb err
