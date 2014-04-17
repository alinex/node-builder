# Task to compile source files like needed
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
async = require 'async'
fs = require 'fs-extra'
path = require 'path'
colors = require 'colors'
{execFile} = require 'child_process'
coffee = require 'coffee-script'

# Main routine
# -------------------------------------------------
#
# __Arguments:__
#
# * `dir`
#   Directory to search for files.
# * `filter`
#   Specification for result list.
# * `callback(err, files)`
#   The callback will be called just if an error occurred or after finished.
#   The files list contains all matching entries.
filefind = module.exports.filefind = (dir, filter, cb) ->
  # make the filter parameter optional
  if typeof filter is 'function' && !cb
    cb = filter
    filter = null
  # check for existing directory
  fs.lstat dir, (err, stats) ->    
    return cb err if err
    if stats.isDirectory()
      # read files
      fs.readdir dir, (err, files) ->
        return cb err if err
        # check files and add to list
        async.map files, (file, cb) ->
          filefind path.join(dir, file), filter, cb
        , (err, result) ->
          return err if err
          # join filelists together
          list = []
          for files in result
            list = list.concat files if files
          cb null, list
    else
      # it's a file entry      
      file = dir
      # check filter rules
      unless filter
        cb null, [ file ]
      if filter instanceof RegExp
        return cb() unless filter.test file
      else if typeof filter is 'function'
        return cb() unless filter file
      # include file in list
      cb null, [ file ]

findbin = module.exports.findbin = (bin, dir, cb) ->
  unless cb
    cb = dir
    dir = path.dirname __dirname
  file = path.join dir, 'node_modules', '.bin', bin
  # search for file
  fs.exists file, (exists) ->
    return cb null, file if exists
    # find in parent
    parent = path.join dir, '..', '..'
    if parent is dir
      return cb "Could not find #{bin} program."
    findbin bin, parent, cb
