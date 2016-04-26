# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node modules
chalk = require 'chalk'
path = require 'path'
# include alinex modules
async = require 'alinex-async'
# internal mhelper modules
builder = require '../index'


# Setup
# -------------------------------------------------

exports.title = 'run automatic tests'
exports.description = """
Pull the newest changes from the origin repository.
"""

exports.options =
  bail:
    alias: 'b'
    type: 'string'
    describe: 'stop on first error in unit tests'
  coverage:
    type: 'boolean'
    describe: 'create coverage reports'
  coveralls:
    type: 'boolean'
    describe: 'send coverage to coveralls'
  browser:
    type: 'boolean'
    describe: 'open results in browser'


# Handler
# ------------------------------------------------

exports.handler = (args, cb) ->
  args.coverage = true if args.coveralls
  # step over directories
  builder.dirs args, (dir, args, cb) ->
    async.parallel [
      (cb) ->
        builder.task 'lintCoffee', dir, args, cb
      (cb) ->
        builder.task 'testMocha', dir, args, (err, results) ->
          return cb err, results if err or not (args.browser and args.coverage)
          builder.task 'browser', dir,
            verbose: args.verbose
            target: path.join dir, 'report', 'lcov-report', 'index.html'
          , (err) ->
            cb err, results
      (cb) ->
        builder.task 'metrics', dir, args, (err) ->
          return cb err if err or not args.browser
          builder.task 'browser', dir,
            verbose: args.verbose
            target: path.join dir, 'report', 'metrics', 'index.html'
          , cb
    ], (err, results) ->
      return cb err if err
      # output results
      console.log()
      console.log chalk.bold "Results for #{path.basename dir} "
      console.log()
      console.log results.join('').trim()
      console.log()
      cb()
  , cb
