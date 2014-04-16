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
  # check for existing source files
  src = path.join command.dir, 'src'
  unless fs.existsSync src
    return cb "No source files found."
  # cleanup old files
  lib = path.join command.dir, 'lib'
  console.log "Remove old lib directory"
  fs.remove lib, (err) ->
    return cb err if err
    coffee commander, command, cb

# ### Compile coffee script
coffee = (commander, command, cb) ->  
  src = path.join command.dir, 'src'
  lib = path.join command.dir, 'lib'
  console.log "Compile coffee script files"
  cmd = path.join GLOBAL.ROOT_DIR, "node_modules/.bin/coffee"
  execFile cmd, [ '-c', '-m', '-o', lib, src ]
  , { cwd: command.dir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and commander.verbose
    console.error stderr.trim().magenta if stderr    
    cb err if err or not command.uglify
    # run uglify afterwards
    uglify commander, lib, lib, cb

uglify = (commander, from, to, cb) ->
  console.log "Uglify js in #{from} to #{to}"
  list = []
  for file in walk from
    file = file[from.length..]
    continue unless file.match /\.js$/
    list.push
      js: path.join from, file
      map: path.join from, path.basename(file, path.extname file) + '.map'
      tojs: path.join to, file
      tomap: path.join to, path.basename(file, path.extname file) + '.map'
  async.each list, (item, cb) ->
    cmd = path.join GLOBAL.ROOT_DIR, "node_modules/.bin/uglifyjs"
    console.log item
    execFile cmd, [ 
      item.js,
      '--in-source-map', item.map
      '--source-map', item.tomap
      '-o', item.tojs
    ], (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and commander.verbose
      console.error stderr.trim().magenta if stderr    
      cb err
  , (err) -> cb err

walk = (dir) ->
  results = []
  list = fs.readdirSync dir
  list.forEach (file) ->
    file = path.join dir, file
    stat = fs.statSync file
    if stat && stat.isDirectory()
      results = results.concat walk file
    else 
      results.push file
  results
