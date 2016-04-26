# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node packages
path = require 'path'
# internal mhelper modules
builder = require '../index'


# Setup
# -------------------------------------------------

exports.title = 'create api documentation'
exports.description = """
Create a html api documentation and maybe upload it to github pages.
"""

exports.options =
  publish:
    type: 'boolean'
    describe: 'publish documentation'
  browser:
    type: 'boolean'
    describe: 'open api in browser'


# Handler
# ------------------------------------------------

exports.handler = (options, cb) ->
  # step over directories
  builder.dirs options, (dir, options, cb) ->
    builder.task 'docUpdate', dir, options, (err) ->
      return cb err if err
      builder.task 'docPublish', dir, options, (err) ->
        return cb err if err or not options.browser
        if options.publish
          builder.task "packageJson", dir, options, (err, pack) ->
            return cb err if err
            console.log "#{path.dirname dir}: waiting for github to update site... (10sec)"
            setTimeout ->
              builder.task "browser", dir,
                verbose: options.verbose
                target: pack.homepage
              , cb
            , 10000
        else
          builder.task "browser", dir,
            verbose: options.verbose
            target: path.join dir, 'doc', 'index.html'
          , cb
  , cb
