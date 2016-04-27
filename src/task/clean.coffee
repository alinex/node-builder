# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node modules
path = require 'path'
# alinex modules
fs = require 'alinex-fs'
async = require 'alinex-async'
# internal mhelper modules
builder = require '../index'


# Clean directories
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
# - `dist` - (boolean) remove files unneccessary for production
# - `auto` - (boolean) remove auto generated files
module.exports = (dir, options, cb) ->
  builder.info dir, options, "cleanup directory"
  # check what to remove
  remove = [
    path.join dir, 'doc'
    path.join dir, 'coverage'
    path.join dir, 'report'
  ]
  if options.auto
    remove.push path.join dir, 'lib'
    remove.push path.join dir, 'var/lib'
    remove.push path.join dir, 'man'
    remove.push path.join dir, 'node_modules'
  if options.dist
    remove.push path.join dir, 'test'
    remove.push path.join dir, 'src'
    remove.push path.join dir, 'var/src'
    remove.push path.join dir, 'coffeelint.json'
    remove.push path.join dir, '.travis'
    remove.push path.join dir, '.git'
    remove.push path.join dir, '.gitignore'
    remove.push path.join dir, '.npmignore'
  # start removing
  async.parallel [
    (cb) ->
      async.each remove, (rmdir, cb) ->
        fs.exists rmdir, (exists) ->
          return cb() unless exists
          builder.debug dir, options, "remove #{rmdir[dir.length+1..]}"
          fs.remove rmdir, cb
      , cb
    (cb) ->
      return cb() unless options.dist
      builder.exec dir, options, "remove development only modules",
        cmd: 'npm'
        args: [ 'prune', '--production' ]
        cwd: dir
      , cb
    (cb) ->
      return cb() unless options.dist
      builder.debug dir, options, "remove unneccessary files"
      selection = [
        include: 'LICENSE'
      ,
        maxdepth: 2
        type: 'dir'
        include: 'example?(s)'
      ]
      async.each selection, (spec, cb) ->
        builder.debug dir, options, "Remove #{spec.include}"
        fs.remove dir, spec, cb
      , cb
  ], cb
