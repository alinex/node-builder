# Task to pull changes from git origin
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
debug = require('debug')('make:pull')
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
# * `command`
#   Command specific parameters and options.
# * `callback(err)`
#   The callback will be called just if an error occurred or with `null` if
#   execution finished.
module.exports.run = (dir, command, cb) ->
  # check for existing git repository
  if command.verbose
    console.log "Check for configured git".grey
  unless fs.existsSync path.join dir, '.git'
    return cb "Only git repositories can be pulled, yet. But #{dir} is no git repository."
  # run the pull command
  console.log "Pull from origin"
  debug "exec #{dir}> git pull -t -p origin master"
#  console.log '--------------------', command
  execFile "git", [ 'pull', '-t', '-p', 'origin', 'master' ]
  , { cwd: dir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and command.verbose
    console.error stderr.trim().magenta if stderr
    cb err
