# Cleanup all automatic generated files
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
async = require 'async'
fs = require 'fs-extra'
path = require 'path'
colors = require 'colors'
{execFile} = require 'child_process'

# Main routine
# -------------------------------------------------
#
# __Arguments:__
#
# * `commander`
#   Commander instance for reading options.
# * `command`
#   Command specific parameters and options.
# * `callback(err)`
#   The callback will be called just if an error occurred or with `null` if
#   execution finished.
module.exports.run = (commander, command, cb) ->
  console.log "Remove unnecessary folders"
  dirs = [
    path.join command.dir, 'doc'
    path.join command.dir, 'lib'
  ]
  if command.all
    dirs.push path.join command.dir, 'node_modules'
  async.each dirs, (dir, cb) ->
    fs.exists dir, (exists) ->
      return cb() unless exists
      if commander.verbose
        console.log "Removing #{dir}".grey
      fs.remove dir, cb
  , (err) ->
    return cb err if err
    cleanDistribution commander, command, (err) ->
      return cb err if err
      cleanModules commander, command, (err) ->
        cb err

cleanDistribution = (commander, command, cb) ->
  cb() unless command.dist
  console.log "Remove development modules"
  cb()

cleanModules = (commander, command, cb) ->
  cb() unless command.dist
  console.log "Remove left over of node_modules"
  cb()

