# Cleanup all automatic generated files
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
debug = require('debug')('make:clean')
async = require 'async'
fs = require 'alinex-fs'
path = require 'path'
colors = require 'colors'
{execFile} = require 'child_process'

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
    dirs.push path.join dir, 'node_modules'
  if options.dist
    dirs.push path.join dir, 'src'
  async.each dirs, (dir, cb) ->
    fs.exists dir, (exists) ->
      return cb() unless exists
      if options.verbose
        console.log "Removing #{dir}".grey
      fs.remove dir, cb
  , (err) ->
    return cb err if err
    cleanDistribution dir, options, (err) ->
      return cb err if err
      cleanModules dir, options, (err) ->
        cb err

cleanDistribution = (dir, options, cb) ->
  return cb() unless options.dist or true
  console.log "Remove development modules"
  debug "exec #{dir}> npm prune --production"
  execFile "npm", [ 'prune', '--production' ]
  , { cwd: dir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and options.verbose
    console.error stderr.trim().magenta if stderr
    cb err

cleanModules = (dir, options, cb) ->
  return cb() unless options.dist
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
    if options.verbose
      item.push '-print'
    debug "exec #{dir}> find #{item}"
    execFile 'find', item, { cwd: dir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and options.verbose
      console.error stderr.trim().magenta if stderr
      cb err
  , cb
