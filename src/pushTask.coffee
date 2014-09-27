# Task to push changes to git origin
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
debug = require('debug')('make:push')
async = require 'async'
fs = require 'fs'
path = require 'path'
chalk = require 'chalk'
{exec,execFile} = require 'child_process'

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
    return cb "Only git repositories can be pushed, yet. But #{dir} is no git repository."
  # run the push options
  commit dir, options, (err) ->
    return cb err if err
    console.log "Push to origin"
    debug "exec #{dir}> git push --tags --prune origin master"
    execFile "git", [ 'push', '--tags', '--prune', 'origin', 'master' ]
    , { cwd: dir }, (err, stdout, stderr) ->
      console.log chalk.grey stdout.trim() if stdout and options.verbose
      console.error chalk.magenta stderr.trim() if stderr
      cb err

commit = (dir, options, cb) ->
  if options.message
    console.log "Adding changed files to git"
    debug "exec #{dir}> git add -A"
    execFile "git", [ 'add', '-A' ]
    , { cwd: dir }, (err, stdout, stderr) ->
      console.log chalk.grey stdout.trim() if stdout and options.verbose
      console.error chalk.magenta stderr.trim() if stderr
      return cb err if err
      debug "exec #{dir}> git commit -m #{JSON.stringify options.message}"
      execFile "git", [ 'commit', '-m', options.message ]
      , { cwd: dir }, (err, stdout, stderr) ->
        console.log chalk.grey stdout.trim() if stdout and options.verbose
        console.error chalk.magenta stderr.trim() if stderr
        cb err
  else
    debug "exec #{dir}> LANG=C git status"
    exec 'LANG=C git status', { cwd: dir }, (err, stdout, stderr) ->
      return cb err if err
      return cb() if ~stdout.indexOf 'nothing to commit'
      console.log stdout
      cb "Skipped push for #{dir} because not all changes are committed, use '--message <message>'."
