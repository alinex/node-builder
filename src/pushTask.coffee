# Task to push changes to git origin
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
async = require 'async'
fs = require 'fs'
path = require 'path'
colors = require 'colors'
{exec,execFile} = require 'child_process'

# Main routine
# -------------------------------------------------
#
# __Arguments:__
#
# * `command`
#   Command specific parameters and options.
# * `callback(err)`
#   The callback will be called just if an error occurred or with `null` if
#   execution finished.
module.exports.run = (command, cb) ->
  # check for existing git repository
  if command.verbose
    console.log "Check for configured git".grey
  unless fs.existsSync path.join command.dir, '.git'
    return cb "Only git repositories can be pushed."
  # run the push command
  commit command, (err) ->
    return cb err if err
    console.log "Push to origin"
    execFile "git", [ 'push', '--tags', '--prune', 'origin', 'master' ]
    , { cwd: command.dir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and command.verbose
      console.error stderr.trim().magenta if stderr
      cb err

commit = (command, cb) ->
  if command.message
    console.log "Adding changed files to git"
    execFile "git", [ 'add', '-A' ]
    , { cwd: command.dir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and command.verbose
      console.error stderr.trim().magenta if stderr
      return cb err if err
      execFile "git", [ 'commit', '-m', command.message ]
      , { cwd: command.dir }, (err, stdout, stderr) ->
        console.log stdout.trim().grey if stdout and command.verbose
        console.error stderr.trim().magenta if stderr
        cb err
  else
    exec 'LANG=C git status', { cwd: command.dir }, (err, stdout, stderr) ->
      return cb err if err
      return cb() if ~stdout.indexOf 'nothing to commit'
      console.log stdout
      cb "Skipped push because not all changes are committed, use '--message <message>'."
