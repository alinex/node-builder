
# Task to pull changes from git origin
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
fs = require 'fs'
path = require 'path'
chalk = require 'chalk'
# include alinex modules
async = require 'alinex-async'
Exec = require 'alinex-exec'


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
    cb new Error "No supported repository to be pulled detected."

git = (dir, options, cb) ->
  # check for existing git repository
  if options.verbose
    console.log chalk.grey "Check for configured git"
  fs.exists path.join(dir, '.git'), (exists) ->
    return cb() unless exists # no git repository
    # run the pull options
    console.log "Pull from git origin"
    Exec.run
      cmd: 'git'
      args: [ 'pull', '-t', '-p', 'origin', 'master' ]
      cwd: dir
    , (err, proc) ->
      console.log chalk.grey proc.stdout().trim() if proc.stdout() and options.verbose
      console.error chalk.magenta proc.stderr().trim() if proc.stderr()
      cb err, true
