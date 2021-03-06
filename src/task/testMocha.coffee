# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node packages
path = require 'path'
chalk = require 'chalk'
# alinex packages
fs = require 'alinex-fs'
util = require 'alinex-util'
# used through shell
# - require 'istanbul'
# - require 'mocha'
# - require 'coffee-coverage'
# internal mhelper modules
builder = require '../index'


# Run mocha tests
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
# - `coverage` - (boolean) collect data for coverage report
module.exports = (dir, options, cb) ->
  fs.exists "#{dir}/test/mocha", (exists) ->
    return cb() unless exists
    fs.npmbin 'istanbul', path.dirname(path.dirname __dirname), (err, istanbul) ->
      if err and options.coverage
        console.error chalk.yellow "Skipped coverage because istanbul is missing"
        return cb()
      mocha = if options.coverage then '_mocha' else 'mocha'
      fs.npmbin mocha, path.dirname(path.dirname __dirname), (err, mocha) ->
        if err
          console.error chalk.yellow "Skipped tests because mocha is missing"
          return cb()
        builder.info dir, options, "Run mocha tests"
        # Run external options
        msg = "Mocha Test results:\n"
        cmd = mocha
        args = []
        if options.coverage
          args.unshift 'cover', mocha, '--', '--require', 'coffee-coverage/register-istanbul'
          args.unshift '--dir=./report'
          cmd = istanbul
        if options.prof
          args.unshift cmd
          args.unshift '--prof'
          cmd = 'node'
        args.push '--compilers', 'coffee:coffee-script/register'
        args.push '--reporter', 'spec'
        args.push '-c' # colors
        args.push '--recursive'
        args.push '--bail' if options.bail
        args.push 'test/mocha'
        env = util.clone process.env
        env.DEBUG = process.env.TEST_DEBUG if process.env.TEST_DEBUG
        env.DEBUG_COLORS = 1 unless options.nocolors
        builder.exec dir, options, 'mocha tests',
          cmd: cmd
          args: args
          cwd: dir
          env: env
          interactive: true
        , (err, proc) ->
          skip = true
          for line in proc.stdout().split /\n/
            continue unless line
            skip = false if line.match /\d passing/
            continue if skip
            msg += line + '\n'
          return cb err, '' if msg.split(/\n/).length < 2
          cb err, if options.verbose > 2 then null else msg
