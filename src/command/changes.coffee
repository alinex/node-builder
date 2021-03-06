# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# include base modules
chalk = require 'chalk'
path = require 'path'
async = require 'async'
# include alinex modules
fs = require 'alinex-fs'
# internal mhelper modules
builder = require '../index'


# Setup
# -------------------------------------------------

exports.title = 'show changes since last release'
exports.description = """
List all changes since last published version. This contains local file changes,
last commits and updates of depending packages.

This information is useful before publishing to check if everything is ready and
what goes into the new version.
"""

exports.options =
  'skip-unused':
    alias: 's'
    type: 'boolean'
    describe: 'Skip check for unused packages'


# Handler
# ------------------------------------------------

exports.handler = (options, cb) ->
  # step over directories
  builder.dirs options, (dir, options, cb) ->
    builder.task 'compile', dir, options, (err) ->
      return cb err if err
      async.parallel [
        (cb) -> git dir, options, cb
        (cb) -> builder.task 'npmChanges', dir, options, cb
      ], (err, results) ->
        builder.results dir, options, "Results", results
        cb err
  , cb


# Helper
# ------------------------------------------------

git = (dir, options, cb) ->
  fs.exists path.join(dir, '.git'), (exists) ->
    return cb() unless exists # no git repository
    async.parallel [
      (cb) -> gitChanges dir, options, cb
      (cb) -> gitStatus dir, options, cb
    ], cb

gitChanges = (dir, options, cb) ->
  builder.info dir, options, "check git commits"
  builder.exec dir, options, 'git last publication',
    cmd: 'git'
    args: [ 'describe', '--abbrev=0' ]
    cwd: dir
  , (err, proc) ->
    tag = proc.stdout().trim()
    msg = "Changes since last publication as #{tag}:\n"
    builder.exec dir, options, 'git log',
      cmd: 'git'
      args: ['log', "#{tag}..HEAD", "--format=oneline"]
      cwd: dir
    , (err, proc) ->
      return cb err if err
      if proc.stdout()
        msg += "- #{chalk.yellow line[41..]}\n" for line in proc.stdout().trim().split /\n/
      else
        msg += chalk.yellow("Nothing changed.") + "\n"
      cb err, msg

gitStatus = (dir, options, cb) ->
  builder.info dir, options, "check git status"
  msg = ''
  builder.exec dir, options, 'git status',
    cmd: 'git'
    args: ['status']
    cwd: dir
  , (err, proc) ->
    return cb err if err
    if proc.stdout()
      for line in proc.stdout().trim().split /\n/
        msg += "#{line.trim()}\n" if line.match /^Changes/
        msg += "- #{chalk.yellow line.trim().replace /\s+/g, ' '}\n" if line.match /^\t/
    else
      msg += chalk.yellow("Nothing changed.") + "\n"
    cb err, msg
