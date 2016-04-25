# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node packages
path = require 'path'
chalk = require 'chalk'
# alinex packages
fs = require 'alinex-fs'
# internal mhelper modules
builder = require '../index'


# Create metrics report
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
module.exports = (dir, options, cb) ->
  fs.npmbin 'plato', path.dirname(path.dirname __dirname), (err, cmd) ->
    if err
      console.error chalk.yellow "Skipped metrics because plato is missing"
      return cb()
    builder.debug dir, options, "create metrics report"
    # Run external options
    builder.exec dir, options, 'metrics report',
      cmd: cmd
      args: [
        '-r'
        "-d", path.join dir, 'report/metrics'
        'lib'
      ]
      cwd: dir
    , (err) -> cb err
