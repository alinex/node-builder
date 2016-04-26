# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# internal mhelper modules
builder = require '../index'


# Setup
# -------------------------------------------------

exports.title = 'create api documentation'
exports.description = """
Create a html api documentation and maybe upload it to github pages.
"""

exports.options =
  publish:
    type: 'boolean'
    describe: 'publish documentation'


# Handler
# ------------------------------------------------

exports.handler = (options, cb) ->
  # step over directories
  builder.dirs options, (dir, options, cb) ->
    builder.task 'docUpdate', dir, options, cb
  , cb
