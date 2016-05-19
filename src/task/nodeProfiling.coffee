# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# general modules
chalk = require 'chalk'
async = require 'async'
# alinex modules
fs = require 'alinex-fs'
# internal mhelper modules
builder = require '../index'


# Install using npm
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
module.exports = (dir, options, cb) ->
  return cb() unless options.prof
  builder.info dir, options, "analyze node profiling"
  # find all profiling logs
  fs.find dir,
    include: 'isolate-*-v8.log'
  , (err, list) ->
    return cb err if err
    unless list
      console.error chalk.magenta "No profiling information generated"
      return cb()
    # analyze profiling
    list.unshift '--prof-process'
    builder.exec dir, options, 'node analyze profiling',
      cmd: 'node'
      args: list
      cwd: dir
      retry:
        times: 3
    , (err, proc) ->
      # store to file
      fs.writeFile "#{dir}/report/profiling.txt", proc.stdout(), 'UTF8', (err) ->
        return cb err if err
        cb()
        # remove files
        async.each list[1..], (file, cb) ->
          fs.remove file, cb
        , ->
