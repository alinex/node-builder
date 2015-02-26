# Task to list all unpublished changes
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
    cb new Error "No supported repository to be checked detected."

git = (dir, options, cb) ->
  # check for existing git repository
  if options.verbose
    console.log chalk.grey "Check for configured git"
  fs.exists path.join(dir, '.git'), (exists) ->
    return cb() unless exists # no git repository
    # run the pull options
    console.log "Changes since last publication:"
    proc = new Spawn
      cmd: 'git'
      args: [ 'tag' ]
      cwd: dir
    proc.run (err, stdout, stderr) ->
      tags = stdout.split /\n/
      return cb err if err
      proc = new Spawn
        cmd: 'git'
        args: [ 'log', "#{tags[tags.length-2]}..HEAD", "--format=oneline" ]
        cwd: dir
      proc.run (err, stdout, stderr) ->
        return cb err if err
        if stdout
          console.log chalk.yellow "- #{line[41..]}" for line in stdout.trim().split /\n/
        else
          console.log chalk.yellow "Nothing changed."
        console.error chalk.magenta stderr.trim() if stderr
        cb err, true
