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
    compile dir, args, cb
  , cb

compile = (dir, args, cb) ->
  async.parallel [
    # check for existing source files
    (cb) ->
      fs.exists "#{dir}/src", (exists) ->
        return cb new Error "No source files found" unless exists
        # remove old lib dir
        builder.debug dir, args, "remove lib"
        fs.remove "#{dir}/lib", (err) ->
          return cb err if err
          # compile
          async.parallel [
            (cb) -> builder.task 'compileCoffee', dir, args, cb
            (cb) -> builder.task 'copyJs', dir, args, cb
            (cb) -> builder.task 'compileMan', dir, args, cb
          ], cb
    # check for linked libraries
    (cb) ->
      fs.find "#{dir}/node_modules",
        type: 'link'
        maxdepth: 1
      , (err, list) ->
        return cb err if err
        async.each list, (subdir, cb) ->
          compile subdir, args, cb
        , cb
  ], cb
