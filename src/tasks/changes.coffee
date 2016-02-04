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
    (cb) -> npm dir, options, cb
    (cb) -> git dir, options, cb
  ], (err, results) ->
    return cb err if err
    console.log results.join('').trim()
    cb()

npm = (dir, options, cb) ->
  fs.npmbin 'npm-check', path.dirname(path.dirname __dirname), (err, cmd) ->
    # run the pull options
    msg = "NPM Update check:\n"
    Exec.run
      cmd: cmd
      cwd: dir
    , (err, proc) ->
      return cb err if err
      if proc.stdout()
        for line in proc.stdout().trim().split /\n/
          continue if line.match /Use npm-check/
          msg += chalk.yellow "- #{line.trim()}\n" if line.match /^\w/
          if match = line.match /to go (from .*)/
            msg = msg.replace /(\s*http.*)?\n.*?$/, chalk.grey " #{match[1]}\n"
      console.error chalk.magenta proc.stderr().trim() if proc.stderr()
      if msg
        msg += chalk.grey "Use `#{chalk.underline 'npm install'}` or
        `#{chalk.underline cmd + ' -u'}` to upgrade.\n"
      cb err, msg

git = (dir, options, cb) ->
  # check for existing git repository
  if options.verbose
    console.log chalk.grey "Check for configured git"
  fs.exists path.join(dir, '.git'), (exists) ->
    return cb() unless exists # no git repository
    async.parallel [
      (cb) -> gitChanges dir, options, cb
      (cb) -> gitStatus dir, options, cb
    ], (err, results) ->
      return cb err if err
      cb null, results.join ''

gitChanges = (dir, options, cb) ->
  # run the pull options
  Exec.run
    cmd: 'git'
    args: [ 'describe', '--abbrev=0' ]
    cwd: dir
  , (err, proc) ->
    return cb err if err
    tag = proc.stdout().trim()
    msg = "Changes since last publication as #{tag}:\n"
    Exec.run
      cmd: 'git'
      args: ['log', "#{tag}..HEAD", "--format=oneline"]
      cwd: dir
    , (err, proc) ->
      return cb err if err
      if proc.stdout()
        msg += chalk.yellow "- #{line[41..]}\n" for line in proc.stdout().trim().split /\n/
      else
        msg += chalk.yellow "Nothing changed.\n"
      console.error chalk.magenta proc.stderr().trim() if proc.stderr()
      cb err, msg

gitStatus = (dir, options, cb) ->
  msg = ''
  # run the pull options
  Exec.run
    cmd: 'git'
    args: ['status']
    cwd: dir
  , (err, proc) ->
    return cb err if err
    if proc.stdout()
      for line in proc.stdout().trim().split /\n/
        msg += "#{line.trim()}\n" if line.match /^Changes/
        msg += chalk.yellow "- #{line.trim().replace /\s+/g, ' '}\n" if line.match /^\t/
    else
      msg += chalk.yellow "Nothing changed.\n"
    console.error chalk.magenta proc.stderr().trim() if proc.stderr()
    cb err, msg
