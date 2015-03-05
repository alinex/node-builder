# Cleanup all automatic generated files
# =================================================


# Node modules
# -------------------------------------------------

# include alinex modules
Spawn = require 'alinex-spawn'
# include base modules
async = require 'async'
fs = require 'alinex-fs'
path = require 'path'
chalk = require 'chalk'

# Main routine
# -------------------------------------------------
#
# __Arguments:__
#
# * `dir`
#   Directory to operate on
# * `options`
#   Command specific parameters and options.
# * `callback(err)`
#   The callback will be called just if an error occurred or with `null` if
#   execution finished.
module.exports.run = (dir, options, cb) ->
  console.log "Remove unnecessary folders"

  dirs = [
    path.join dir, 'doc'
    path.join dir, 'coverage'
  ]
  if options.auto
    dirs.push path.join dir, 'lib'
    dirs.push path.join dir, 'man'
    dirs.push path.join dir, 'node_modules'
  if options.dist
    dirs.push path.join dir, 'src'
  async.each dirs, (dir, cb) ->
    fs.exists dir, (exists) ->
      return cb() unless exists
      if options.verbose
        console.log chalk.grey "Removed #{dir}"
      fs.remove dir, cb
  , (err) ->
    return cb err if err
    cleanDistribution dir, options, (err) ->
      return cb err if err
      cleanModules dir, options, (err) ->
        cb err

cleanDistribution = (dir, options, cb) ->
  return cb() unless options.dist
  console.log "Remove development modules"
  proc = new Spawn
    cmd: 'npm'
    args: [ 'prune', '--production' ]
    cwd: dir
  proc.run (err, stdout, stderr) ->
    console.log chalk.grey stdout.trim() if stdout and options.verbose
    console.error chalk.magenta stderr.trim() if stderr
    cb err

cleanModules = (dir, options, cb) ->
  return cb() unless options.dist
  console.log "Remove left over of node_modules"
  selection = [
    include: 'LICENSE'
  ,
    maxdepth: 2
    type: 'dir'
    include: 'example?(s)'
  ]
  async.each selection, (spec, cb) ->
    fs.remove dir, spec, cb
  , cb
