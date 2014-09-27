# Task to pull changes from git origin
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
debug = require('debug')('make:pull')
async = require 'async'
fs = require 'fs'
path = require 'path'
chalk = require 'chalk'
{execFile} = require 'child_process'

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
  # check for existing git repository
  if options.verbose
    console.log chalk.grey "Check for configured git"
  unless fs.existsSync path.join dir, '.git'
    return cb "Only git repositories can be pulled, yet. But #{dir} is no git repository."
  # run the pull options
  console.log "Pull from origin"
  debug "exec #{dir}> git pull -t -p origin master"
  execFile "git", [ 'pull', '-t', '-p', 'origin', 'master' ]
  , { cwd: dir }, (err, stdout, stderr) ->
    console.log chalk.grey stdout.trim() if stdout and options.verbose
    console.error chalk.magenta stderr.trim() if stderr
    cb err
