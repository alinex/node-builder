# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node packages
path = require 'path'
# use uglifyjs binary
# alinex packages
fs = require 'alinex-fs'
# internal mhelper modules
builder = require '../index'


# Uglify js
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
# - `fromjs` - (string) source js
# - `tojs` - (string) destination js
# - `frommap` - (string, optional) source map
# - `tomap` - (string) destination map
module.exports = (dir, options, cb) ->
  builder.noisy dir, options, "uglify #{options.fromjs} -> #{options.tojs}"
  # run the pull options
  fs.npmbin 'uglifyjs', path.dirname(path.dirname __dirname), (err, cmd) ->
    return cb err if err
    args = [
      options.fromjs,
      '--source-map', options.tomap
      '-o', options.tojs
      '-m', '-c'
    ]
    args.push '--in-source-map', options.frommap if options.frommap
    builder.exec dir, options, 'run uglify',
      cmd: cmd
      args: args
      cwd: options.dir
    , cb
