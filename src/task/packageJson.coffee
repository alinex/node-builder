# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node packages
path = require 'path'
memoize = require 'memoizee'
# alinex packages
fs = require 'alinex-fs'
# internal mhelper modules
builder = require '../index'


# Read package json
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
module.exports = memoize (dir, options, cb) ->
  builder.debug dir, options, "read package json"
  file = path.join dir, 'package.json'
  try
    pack = JSON.parse fs.readFileSync file
  catch error
    return cb new Error "Could not load #{file} as valid JSON: #{error.message}"
  cb null, pack
