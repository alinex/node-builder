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


# Lint coffee script files
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
# - `nocolors` - (boolean) used to harmonize with called command
module.exports = (dir, options, cb) ->
  fs.exists "#{dir}/coffeelint.json", (exists) ->
    return cb() unless exists
    fs.npmbin 'coffeelint', path.dirname(path.dirname __dirname), (err, cmd) ->
      if err
        console.error chalk.yellow "Skipped lint because coffeelint is missing"
        return cb()
      builder.info dir, options, "linting coffee script"
      # Run external options
      msg = "Lint coffee problems:\n"
      builder.exec dir, options, 'coffee lint',
        cmd: cmd
        args: [
          '-f', path.join dir, 'coffeelint.json'
          'src'
        ]
        cwd: dir
        env:
          PATH: process.env.PATH
          NODE: process.env.NODE
      , (err, proc) ->
        if proc.stdout()
          for line in proc.stdout().trim().split /\n/
            if line.match /[1-9]\d* errors/
              return cb new Error line.trim(), msg.trim()
            else if line.match /⚡/
              msg += chalk.yellow "#{line.trim()}\n"
        return cb err, '' if msg.split(/\n/).length < 3
        cb null, msg.trim()
