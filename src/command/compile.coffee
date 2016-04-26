# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

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

exports.handler = (options, cb) ->
  # step over directories
  builder.dirs options, (dir, options, cb) ->
    compile dir, options, cb
  , cb

compile = (dir, options, cb) ->
  async.parallel [
    # check for existing source files
    (cb) ->
      fs.exists "#{dir}/src", (exists) ->
        return cb new Error "No source files found" unless exists
        # remove old lib dir
        builder.debug dir, options, "remove lib"
        fs.remove "#{dir}/lib", (err) ->
          return cb err if err
          # compile
          async.parallel [
            (cb) -> builder.task 'compileCoffee', dir, options, cb
            (cb) -> builder.task 'copyJs', dir, options, cb
            (cb) -> builder.task 'compileMan', dir, options, cb
          ], cb
    # check for linked libraries
    (cb) ->
      fs.exists "#{dir}/node_modules", (exists) ->
        return cb() unless exists
        fs.find "#{dir}/node_modules",
          type: 'link'
          maxdepth: 1
        , (err, list) ->
          return cb err if err
          async.each list, (subdir, cb) ->
            compile subdir, options, cb
          , cb
  ], cb
