# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node packages
async = require 'async'
# alinex packages
fs = require 'alinex-fs'
# internal mhelper modules
builder = require '../index'


# Compile coffee -> js
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
# - `uglify` - (boolean) should uglify be used
module.exports = (dir, options, cb) ->
  fs.exists "#{dir}/src", (exists) ->
    return cb new Error "No source files found at #{dir}/src" unless exists
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
