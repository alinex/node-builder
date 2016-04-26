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


# NPM changes
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
module.exports = (dir, options, cb) ->
  builder.debug dir, options, "check npm packages"
  fs.npmbin 'npm-check', path.dirname(path.dirname __dirname), (err, cmd) ->
    msg = "NPM Update check:\n"
    params = []
    params.push '-s' if options['skip-unused']
    builder.exec dir, options, 'npm-check',
      cmd: cmd
      args: params
      cwd: dir
      check:
        exitCode:
          args: [0, 1]
    , (err, proc) ->
      return cb err if err
      upgrade = false
      if proc.stdout()
        for line in proc.stdout().trim().split /\n/
          continue if line.match /Use npm-check/
          if line.match /^\w/
            msg += chalk.yellow "- #{line.trim()}\n"
            if match = line.match /to go (from .*)/
              msg = msg.replace /(\s*http.*)?\n.*?$/, chalk.grey " #{match[1]}\n"
            unless line.match /NOTUSED\?/
              upgrade = true
      return cb err, '' if msg.split(/\n/).length < 3
      msg += chalk.grey "Use `#{chalk.underline cmd + ' -u'}` to upgrade.\n" if upgrade
      cb null, msg
