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
module.exports = (dir, args, cb) ->
  builder.noisy dir, args, "uglify #{args.fromjs} -> #{args.tojs}"
  # run the pull options
  fs.npmbin 'uglifyjs', path.dirname(path.dirname __dirname), (err, cmd) ->
    return cb err if err
    param = [
      args.fromjs,
      '--source-map', args.tomap
      '-o', args.tojs
      '-m', '-c'
    ]
    param.push '--in-source-map', args.frommap if args.frommap
    builder.exec 'run uglify', dir, args,
      cmd: cmd
      args: param
      cwd: args.dir
    , cb
