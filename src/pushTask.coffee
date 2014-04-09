# Task to push changes to git origin
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
  # check for existing git repository
  if commander.verbose
    console.log "Check for configured git".grey
  unless fs.existsSync path.join command.dir, '.git'
    return cb "Only git repositories can be pushed."
  # run the push command
  commit commander, command, (err) ->
    return cb err if err
    console.log "Push to origin"
    execFile "git", [ 'push', '--tags', '--prune', 'origin', 'master' ]
    , { cwd: command.dir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and commander.verbose
      console.error stderr.trim().magenta if stderr
      cb err

commit = (commander, command, cb) ->
  if command.commit
    console.log "Adding changed files to git"
    execFile "git", [ 'add', '-A' ]
    , { cwd: command.dir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and commander.verbose
      console.error stderr.trim().magenta if stderr
      return cb err if err
      execFile "git", [ 'commit', '-m', command.commit ]
      , { cwd: command.dir }, (err, stdout, stderr) ->
        console.log stdout.trim().grey if stdout and commander.verbose
        console.error stderr.trim().magenta if stderr
        cb err
  else
    execFile "git", [ 'status' ], { cwd: command.dir }, (err, stdout, stderr) ->
      return cb err if err
      return cb() if ~stdout.indexOf 'nothing to commit'
      console.log stdout
      cb "Skipped push because not all changes are committed, use '--commit message'."
