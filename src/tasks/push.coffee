# Task to push changes to git origin
# =================================================


# Node modules
# -------------------------------------------------

# include alinex modules
Spawn = require 'alinex-spawn'
# include base modules
async = require 'async'
fs = require 'fs'
path = require 'path'
chalk = require 'chalk'

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
  async.parallel [
    (cb) -> git dir, options, cb
  ], (err, results) ->
    return cb err if err
    for r in results
      return cb() if r
    cb new Error "No supported repository to be pushed detected."

git = (dir, options, cb) ->
  # check for existing git repository
  if options.verbose
    console.log chalk.grey "Check for configured git"
  fs.exists path.join(dir, '.git'), (exists) ->
    return cb() unless exists # no git repository
    # run commit if specified
    commit dir, options, (err) ->
      return cb err if err
      # run the push options
      console.log "Push to origin"
      proc = new Spawn
        cmd: 'git'
        args: [ 'push', '--tags', '--prune', 'origin', 'master' ]
        cwd: dir
      proc.run (err, stdout, stderr) ->
        console.log chalk.grey stdout.trim() if stdout and options.verbose
        console.error chalk.magenta stderr.trim() if stderr
        cb err, true

commit = (dir, options, cb) ->
  if options.message
    console.log "Adding changed files to git"
    proc = new Spawn
      cmd: 'git'
      args: [ 'add', '-A' ]
      cwd: dir
    proc.run (err, stdout, stderr) ->
      console.log chalk.grey stdout.trim() if stdout and options.verbose
      console.error chalk.magenta stderr.trim() if stderr
      return cb err if err
      proc = new Spawn
        cmd: 'git'
        args: [ 'commit', '-m', options.message ]
        cwd: dir
      proc.run (err, stdout, stderr) ->
        console.log chalk.grey stdout.trim() if stdout and options.verbose
        console.error chalk.magenta stderr.trim() if stderr
        cb err
  else
    proc = new Spawn
      cmd: 'git'
      args: [ 'status' ]
      cwd: dir
      env:
        LANG: 'C'
    proc.run (err, stdout, stderr) ->
      return cb err if err
      return cb() if ~stdout.indexOf 'nothing to commit'
      console.log stdout
      cb new Error "Skipped push for #{dir} because not all changes are committed, use '--message <message>'."
