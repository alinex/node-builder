# Task to list all unpublished changes
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
path = require 'path'
chalk = require 'chalk'
# include alinex modules
fs = require 'alinex-fs'
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
    cb new Error "No supported repository to be checked detected."

git = (dir, options, cb) ->
  # check for existing git repository
  if options.verbose
    console.log chalk.grey "Check for configured git"
  fs.exists path.join(dir, '.git'), (exists) ->
    return cb() unless exists # no git repository
    # run the pull options
    Exec.run
      cmd: 'git'
      args: [ 'describe', '--abbrev=0' ]
      cwd: dir
    , (err, proc) ->
      tag = proc.stdout().trim()
      console.log "Changes since last publication as #{tag}:"
      return cb err if err
      Exec.run
        cmd: 'git'
        args: [ 'log', "#{tag}..HEAD", "--format=oneline" ]
        cwd: dir
      , (err, proc) ->
        return cb err if err
        if proc.stdout()
          console.log chalk.yellow "- #{line[41..]}" for line in proc.stdout().trim().split /\n/
        else
          console.log chalk.yellow "Nothing changed."
        console.error chalk.magenta proc.stderr().trim() if proc.stderr()
        cb err, true
