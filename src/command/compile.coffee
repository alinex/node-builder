# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node packages
async = require 'async'
# include alinex modules
fs = require 'alinex-fs'
# internal modules
builder = require '../index'

# Setup
# -------------------------------------------------

exports.title = 'compile code'
exports.description = """
This will recreate the lib folder and copy or compile the sources into it.
"""

exports.options =
  uglify:
    alias: 'u'
    type: 'boolean'
    describe: 'run uglify for each file'


# Handler
# ------------------------------------------------

exports.handler = (options, cb) ->
  # step over directories
  builder.dirs options, (dir, options, cb) ->
    compile dir, options, cb
  , cb

compile = (dir, options, cb) ->
  async.parallel [
    # check for existing source files
    (cb) -> builder.task 'compile', dir, options, cb
    # check for linked libraries
    (cb) ->
      fs.exists "#{dir}/node_modules", (exists) ->
        return cb() unless exists
        fs.find "#{dir}/node_modules",
          type: 'dir'
          maxdepth: 1
        , (err, list) ->
          console.log list.length
          return cb()
          return cb err if err
          async.each list, (subdir, cb) ->
            compile subdir, options, cb
          , cb
  ], cb
