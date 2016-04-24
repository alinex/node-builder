# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# include base modules
path = require 'path'
# include alinex modules
fs = require 'alinex-fs'
# internal modules
builder = require '../index'

# Setup
# -------------------------------------------------

exports.title = 'push changes to remote repository'
exports.description = """
Push the newest changes to the origin repository. This includes all tags.
"""

exports.options =
  message:
    alias: 'm'
    type: 'string'
    describe: 'Commit message for local changes.'


# Handler
# ------------------------------------------------

exports.handler = (args, cb) ->
  # step over directories
  builder.dirs args, (dir, args, cb) ->
    # check for existing git repository
    fs.exists path.join(dir, '.git'), (exists) ->
      return cb() unless exists # no git repository
      # check status
      builder.task 'gitStatus', dir, args, (err, out) ->
        return cb err if err
        unless out
          return builder.task 'gitPush', dir, args, cb
        unless args.message
          return cb new Error "Can't push to master if not everything is commited."
        builder.task 'gitCommitAll', dir, args, (err) ->
          return cb err if err
          builder.task 'gitPush', dir, args, cb
  , cb
