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
# * `command`
#   Command specific parameters and options.
# * `callback(err)`
#   The callback will be called just if an error occurred or with `null` if
#   execution finished.
module.exports.run = (command, cb) ->
  # check for existing source files
  src = path.join command.dir, 'src'
  unless fs.existsSync src
    return cb "No source files found."
  # cleanup old files
  lib = path.join command.dir, 'lib'
  console.log "Remove old lib directory"
  fs.remove lib, (err) ->
    return cb err if err
    coffee command, cb

# ### Compile coffee script
compilecoffee = (command, cb) ->
  src = path.join command.dir, 'src'
  lib = path.join command.dir, 'lib'
  console.log "Compile coffee script files"
  cmd = path.join GLOBAL.ROOT_DIR, "node_modules/.bin/coffee"
  execFile cmd, [ '-c', '-m', '-o', lib, src ]
  , { cwd: command.dir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and command.verbose
    console.error stderr.trim().magenta if stderr
    cb err if err or not command.uglify
    # run uglify afterwards
    uglify comman, lib, lib, cb

# ### Run uglify for all javascript in directory
uglify = (command, from, to, cb) ->
  console.log "Uglify js in #{from} to #{to}"
  # collect files to work on
  list = []
  for file in walkSync from
    file = file[from.length..]
    continue unless file.match /\.js$/
    list.push
      js: path.join from, file
      map: path.join from, path.basename(file, path.extname file) + '.map'
      tojs: path.join to, file
      tomap: path.join to, path.basename(file, path.extname file) + '.map'
  # parallel uglify call
  async.each list, (item, cb) ->
    cmd = path.join GLOBAL.ROOT_DIR, "node_modules/.bin/uglifyjs"
    console.log item
    args = [
      item.js,
      '--source-map', item.tomap
      '-o', item.tojs
    ]
    if fs.existsSync item.map
      args.push '--in-source-map', item.map
    execFile cmd, args, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and command.verbose
      console.error stderr.trim().magenta if stderr
      cb err
  , (err) -> cb err

# ### Walk through directory and collect files
walkSync = (dir) ->
  results = []
  list = fs.readdirSync dir
  list.forEach (file) ->
    file = path.join dir, file
    stat = fs.statSync file
    if stat && stat.isDirectory()
      results = results.concat walkSync file
    else
      results.push file
  results
