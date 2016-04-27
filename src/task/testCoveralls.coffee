# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node packages
path = require 'path'
chalk = require 'chalk'
{exec} = require 'child_process'
# alinex packages
fs = require 'alinex-fs'
# internal mhelper modules
builder = require '../index'


# Send to coveralls
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
# - `coveralls` - (boolean) send to coveralls
module.exports = (dir, options, cb) ->
  return cb() unless options.coveralls
  fs.exists "#{dir}/report/lcov.info", (exists) ->
    return cb() unless exists
    fs.npmbin 'coveralls', path.dirname(path.dirname __dirname), (err, coveralls) ->
      if err and options.coverage
        console.error chalk.yellow "Skipped coveralls service because not installed"
        return cb()
      builder.info dir, options, "Send to coveralls"
      exec "cat #{dir}/report/lcov.info | #{coveralls} --verbose", (err) ->
        cb err
