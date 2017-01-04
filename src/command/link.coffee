# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# include base modules
path = require 'path'
async = require 'async'
# include alinex modules
fs = require 'alinex-fs'
# internal mhelper modules
builder = require '../index'


# Setup
# -------------------------------------------------

exports.title = 'replace released package with locally linked module'
exports.description = """
Link all or one local package version into the module instead of using the
version from the repository. This will be reverted on a clean auto or publish
command.
"""

exports.options =
  link:
    alias: 'l'
    type: 'string'
    describe: 'package name to link'
  local:
    type: 'string'
    describe: 'local path which is used'


# Handler
# ------------------------------------------------

exports.handler = (options, cb) ->
  # step over directories
  builder.dirs options, (dir, options, cb) ->
    # link all alinex packages if locally existing
    unless options.link
      return fs.find dir,
        filter:
          include: 'alinex-*'
          type: 'dir'
      , (err, list) ->
        return cb err if err
        async.each list, (link, cb) ->
          subname = path.basename(link).split('-')[2]
          return cb() unless subname
          local = path.resolve "#{link}/../../node-#{subname}"
          fs.exists local, (exists) ->
            return cb() unless exists
            setLink dir, options, link, local, cb
        , cb
    # link specified
    link = path.resolve "#{dir}/node_modules/", options.link
    local = if options.local
      path.resolve dir, options.local
    else
      name = path.basename(options.link).split '-'
      name = if name.length is 2 and name[0] is 'alinex'
        "node-#{name[1]}"
      else
        path.basename options.link
      path.resolve "#{path.dirname link}/../../#{name}"
    setLink dir, options, link, local, cb
  , cb

setLink = (dir, options, link, local, cb) ->
  builder.info dir, options, "set link #{link} -> #{local}"
  fs.remove link, ->
    fs.symlink local, link, cb
