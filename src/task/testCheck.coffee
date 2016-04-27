# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node packages
path = require 'path'
# alinex packages
fs = require 'alinex-fs'
async = require 'alinex-async'
# internal mhelper modules
builder = require '../index'


# check for .only tests
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
module.exports = (dir, options, cb) ->
  builder.info dir, options, "check tests"
  fs.find path.join(dir, 'test', 'mocha'),
    type: 'file'
  , (err, list) ->
    return cb err if err
    async.each list, (file, cb) ->
      # check for .only tests
      fs.readFile file, 'utf-8', (err, content) ->
        return err if err
        if content.match /(describe|it)\.only/
          return cb new Error "Found .only test in #{file}"
        cb()
    , cb
