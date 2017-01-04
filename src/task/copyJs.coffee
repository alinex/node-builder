# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node packages
path = require 'path'
async = require 'async'
# alinex packages
fs = require 'alinex-fs'
# internal mhelper modules
builder = require '../index'


# Copy js
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
# - `uglify` - (boolean) should uglify be used
module.exports = (dir, options, cb) ->
  src = path.join dir, 'src'
  lib = path.join dir, 'lib'
  # find files to compile
  fs.find src,
    filter:
      include: '*.js'
  , (err, files) ->
    return cb err if err
    return cb() unless files.length
    builder.info dir, options, "copy javascript files"
    async.each files, (file, cb) ->
      dest = path.join lib, file[src.length..]
      unless options.uglify
        builder.noisy dir, options, "copy file #{file}"
        fs.copy file, dest, cb
        return
      mapfile = path.basename(file, '.js') + '.map'
      builder.task 'uglify', dir,
        verbose: options.verbose
        dir: dir
        fromjs: file
        tojs: dest
        tomap: mapfile
      , cb
    , cb
