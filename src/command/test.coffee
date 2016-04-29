# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node modules
path = require 'path'
async = require 'async'
# include alinex modules
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
    type: 'boolean'
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

exports.handler = (options, cb) ->
  options.coverage = true if options.coveralls
  # step over directories
  builder.dirs options, (dir, options, cb) ->
    async.parallel [
      (cb) ->
        builder.task 'lintCoffee', dir, options, cb
      (cb) ->
        builder.task 'testMocha', dir, options, (err, results) ->
          return cb err, results if err
          builder.task 'testCoveralls', dir, options, (err) ->
            return cb err, results if err or not (options.browser and options.coverage)
            builder.task 'browser', dir,
              verbose: options.verbose
              target: path.join dir, 'report', 'lcov-report', 'index.html'
            , (err) ->
              cb err, results
      (cb) ->
        builder.task 'metrics', dir, options, (err) ->
          return cb err if err or not options.browser
          builder.task 'browser', dir,
            verbose: options.verbose
            target: path.join dir, 'report', 'metrics', 'index.html'
          , cb
    ], (err, results) ->
      builder.results dir, options, "Results for #{path.basename dir}", results
      cb err
  , cb
