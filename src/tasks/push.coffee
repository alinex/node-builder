# Task to push changes to git origin
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
path = require 'path'
chalk = require 'chalk'
# include alinex modules
async = require 'alinex-async'
fs = require 'alinex-fs'
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
      Exec.run
        cmd: 'git'
        args: [ 'push', '--tags', 'origin', 'master' ]
        cwd: dir
      , (err, proc) ->
        console.log chalk.grey proc.stdout().trim() if proc.stdout() and options.verbose
        console.error chalk.magenta proc.stderr().trim() if proc.stderr()
        cb err, true

commit = (dir, options, cb) ->
  if options.message
    console.log "Adding changed files to git"
    Exec.run
      cmd: 'git'
      args: [ 'add', '-A' ]
      cwd: dir
    , (err, proc) ->
      console.log chalk.grey proc.stdout().trim() if proc.stdout() and options.verbose
      console.error chalk.magenta proc.stderr().trim() if proc.stderr()
      return cb err if err
      Exec.run
        cmd: 'git'
        args: [ 'commit', '-m', options.message ]
        cwd: dir
        check:
          noExitCode: true
      , (err, proc) ->
        # ignore error because it will get
        console.log chalk.grey proc.stdout().trim() if proc.stdout() and options.verbose
        console.error chalk.magenta proc.stderr().trim() if proc.stderr()
        cb err
  else
    Exec.run
      cmd: 'git'
      args: [ 'status' ]
      cwd: dir
      env:
        LANG: 'C'
    , (err, proc) ->
      return cb err if err
      return cb() if ~proc.stdout().indexOf 'nothing to commit'
      console.log proc.stdout()
      cb new Error "Skipped push for #{dir} because not all changes are committed,
      use '--message <message>'."
