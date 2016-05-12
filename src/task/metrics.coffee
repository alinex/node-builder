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
<<<<<<< HEAD
  return cb() if options.coveralls
=======
  return cb() unless options.metrics
>>>>>>> eaafbf0ebd5d8ddd9df7fa6c574117c3a11f5b69
  fs.exists "#{dir}/lib", (exists) ->
    unless exists
      console.warn "#{path.basename dir}: Skipped metrics because not compiled."
      return cb()
    fs.npmbin 'plato', path.dirname(path.dirname __dirname), (err, cmd) ->
      if err
        console.error chalk.yellow "Skipped metrics because plato is missing"
        return cb()
      builder.info dir, options, "create metrics report"
      # Run external options
      builder.exec dir, options, 'metrics report',
        cmd: cmd
        args: [
          '-r'
          "-d", path.join dir, 'report/metrics'
          '-t', "#{path.basename dir} JS Analysis"
          'lib'
        ]
        cwd: dir
      , (err) -> cb err
