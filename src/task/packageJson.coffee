# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node packages
path = require 'path'
# alinex packages
fs = require 'alinex-fs'
# internal mhelper modules
builder = require '../index'


# Helper
# ------------------------------------------------

module.exports = (dir, args, cb) ->
  builder.debug dir, args, "read package json"
  file = path.join dir, 'package.json'
  try
    pack = JSON.parse fs.readFileSync file
  catch error
    return cb new Error "Could not load #{file} as valid JSON: #{error.message}"
  cb null, pack
