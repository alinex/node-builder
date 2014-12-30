# Task to list all unpublished changes
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
debug = require('debug')('make:changes')
async = require 'async'
fs = require 'fs'
path = require 'path'
chalk = require 'chalk'
{exec} = require 'child_process'

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
    console.log chalk.grey "List changes since last publication"
  unless fs.existsSync path.join dir, '.git'
    return cb "Only git repositories can be checked, yet. But #{dir} is no git repository."
  # run the pull options
  console.log "Changes since last publication:"
  cmdline = "git log `git tag | tail -1`..HEAD --format=oneline"
  debug "exec #{dir}> #{cmdline}"
  exec cmdline, { cwd: dir }, (err, stdout, stderr) ->
    console.log chalk.grey stdout.trim() if stdout and options.verbose
    console.error chalk.magenta stderr.trim() if stderr
    cb err
