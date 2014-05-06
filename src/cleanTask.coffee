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
# * `command`
#   Command specific parameters and options.
# * `callback(err)`
#   The callback will be called just if an error occurred or with `null` if
#   execution finished.
module.exports.run = (command, cb) ->
  console.log "Remove unnecessary folders"
  dirs = [
    path.join command.dir, 'doc'
    path.join command.dir, 'coverage'
  ]
  if command.auto
    dirs.push path.join command.dir, 'lib'
    dirs.push path.join command.dir, 'node_modules'
  if command.dist
    dirs.push path.join command.dir, 'src'
  async.each dirs, (dir, cb) ->
    fs.exists dir, (exists) ->
      return cb() unless exists
      if command.verbose
        console.log "Removing #{dir}".grey
      fs.remove dir, cb
  , (err) ->
    return cb err if err
    cleanDistribution command, (err) ->
      return cb err if err
      cleanModules command, (err) ->
        cb err

cleanDistribution = (command, cb) ->
  cb() unless command.dist or true
  console.log "Remove development modules"
  execFile "npm", [ 'prune', '--production' ]
  , { cwd: command.dir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and command.verbose
    console.error stderr.trim().magenta if stderr
    cb err

cleanModules = (command, cb) ->
  cb() unless command.dist
  console.log "Remove left over of node_modules"
  find = [
    # Remove example folders
    [ 
      '-mindepth', 2
      '-type', 'd'
      '-regex', '.*/node_modules/[^/]*/examples?'
    ],
    # Remove markup files excluding LICENSE info
    [
      '-mindepth', 2
      '-type', 'f'
      '-name', '*.md'
      '-not', '-iname', 'LICENSE*'
    ]
  ]
  async.eachSeries find, (item, cb) ->
    console.log "Remove #{item}"
    item.unshift '.', '-depth'
    item.push '-exec', 'rm', '-r', '{}', ';'
    if command.verbose
      item.push '-print'
    execFile 'find', item, { cwd: command.dir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and command.verbose
      console.error stderr.trim().magenta if stderr
      cb err
  , cb
