# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# include base modules
path = require 'path'
# include alinex modules
fs = require 'alinex-fs'
async = require 'alinex-async'
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

exports.handler = (args, cb) ->
  # step over directories
  builder.dirs args, (dir, args, cb) ->
    # check for existing source files
    fs.exists "#{dir}/src", (exists) ->
      return cb new Error "No source files found" unless exists
      # remove old lib dir
      builder.debug dir, args, "remove #{dir}/lib"
      fs.remove "#{dir}/lib", (err) ->
        return cb err if err
        # compile
        async.parallel [
          (cb) -> builder.task 'compileCoffee', dir, args, cb
          (cb) -> builder.task 'compileMan', dir, args, cb
        ], cb
  , cb
