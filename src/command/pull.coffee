# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# include base modules
path = require 'path'
# include alinex modules
fs = require 'alinex-fs'
# internal mhelper modules
builder = require '../index'


# Setup
# -------------------------------------------------

exports.title = 'pull newest version from repository'
exports.description = """
Pull the newest changes from the origin repository.
"""

# Handler
# ------------------------------------------------

exports.handler = (args, cb) ->
  # step over directories
  builder.dirs args, (dir, args, cb) ->
    # check for existing git repository
    fs.exists path.join(dir, '.git'), (exists) ->
      return cb() unless exists # no git repository
      builder.task 'gitPull', dir, args, cb
  , cb
