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

tools = require './tools'

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
    compileCoffee command, cb

# ### Compile coffee script
compileCoffee = (command, cb) ->
  src = path.join command.dir, 'src'
  lib = path.join command.dir, 'lib'
  # find files to compile
  tools.filefind src, /\.coffee$/, (err, files) ->
    return cb err if err
    return cb() unless files
    console.log "Compile coffee script"
    async.each files, (file, cb) ->
      fs.readFile file, 'utf8', (err, data) ->
        return cb err if err
        jsfile = path.basename(file, '.coffee') + '.js'
        mapfile = path.basename(file, '.coffee') + '.map'
        console.log "Compile #{file}".grey if command.verbose
        compiled = coffee.compile data,
          filename: path.basename file
          generatedFile: jsfile
          sourceRoot: path.relative path.dirname(file), command.dir
          sourceFiles: [ file ]
          sourceMap: true
        compiled.js += "\n//# sourceMappingURL=#{path.basename mapfile}"
        # write files
        filepathjs = path.join lib, path.dirname(file)[src.length..], jsfile
        filepathmap = path.join lib, path.dirname(file)[src.length..], mapfile
        async.parallel [
          (cb) -> 
            fs.mkdirs path.dirname(filepathjs), (err) ->
              return cb err if err
              fs.writeFile filepathjs, compiled.js, cb
          (cb) -> 
            fs.mkdirs path.dirname(filepathmap), (err) ->
              return cb err if err
              fs.writeFile filepathmap, compiled.v3SourceMap, cb
        ], (err) -> 
          return cb err if err or not command.uglify
          console.log "Uglify #{jsfile}".grey if command.verbose
          uglify
            dir: path.dirname filepathjs
            fromjs: jsfile
            frommap: mapfile
            tojs: jsfile
            tomap: mapfile
          , cb
    , cb

# ### Run uglify for all javascript in directory
uglify = (item, cb) ->
  tools.findbin 'uglifyjs', (err, cmd) ->
    return cb err if err
    args = [
      item.fromjs,
      '--source-map', item.tomap
      '-o', item.tojs
    ]    
    args.push '--in-source-map', item.frommap if item.frommap
    execFile cmd, args, { cwd: item.dir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and command.verbose
      console.error stderr.trim().magenta if stderr
      cb err
