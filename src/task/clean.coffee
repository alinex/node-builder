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


# Push last changes to git
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
module.exports = (dir, args, cb) ->
  builder.debug dir, args, "cleanup directory"
  # check what to remove
  remove = [
    path.join dir, 'doc'
    path.join dir, 'coverage'
    path.join dir, 'report'
  ]
  if args.auto
    remove.push path.join dir, 'lib'
    remove.push path.join dir, 'var/lib'
    remove.push path.join dir, 'man'
    remove.push path.join dir, 'node_modules'
  if args.dist
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
          builder.noisy dir, args, "Remove #{rmdir[dir.length+1..]}"
          fs.remove rmdir, cb
      , cb
    (cb) ->
      return cb() unless args.dist
      builder.debug dir, args, "remove development modules"
      builder.exec dir, args, "development only modules",
        cmd: 'npm'
        args: [ 'prune', '--production' ]
        cwd: dir
      , cb
    (cb) ->
      return cb() unless args.dist
      builder.debug dir, args, "remove unneccessary files"
      selection = [
        include: 'LICENSE'
      ,
        maxdepth: 2
        type: 'dir'
        include: 'example?(s)'
      ]
      async.each selection, (spec, cb) ->
        builder.noisy dir, args, "Remove #{spec.include}"
        fs.remove dir, spec, cb
      , cb
  ], cb
