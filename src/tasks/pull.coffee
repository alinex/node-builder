
# Task to pull changes from git origin
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
  # check for existing git repository
  if options.verbose
    console.log chalk.grey "Check for configured git"
  async.parallel [
    (cb) -> git dir, options, cb
  ], (err, results) ->
    return cb err if err
    for r in results
      return cb() if r
    cb new Error "No supported repository to be pulled detected."

git = (dir, options, cb) ->
  fs.exists path.join(dir, '.git'), (exists) ->
    return cb() unless exists # no git repository
    # run the pull options
    console.log "Pull from git origin"
    proc = new Spawn
      cmd: 'git'
      args: [ 'pull', '-t', '-p', 'origin', 'master' ]
      cwd: dir
    proc.run (err, stdout, stderr, code) ->
      console.log chalk.grey stdout.trim() if stdout and options.verbose
      console.error chalk.magenta stderr.trim() if stderr
      cb err, true
