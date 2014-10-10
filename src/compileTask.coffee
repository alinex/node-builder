# Task to compile source files like needed
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
debug = require('debug')('make:compile')
async = require 'async'
fs = require 'alinex-fs'
path = require 'path'
chalk = require 'chalk'
{exec,execFile} = require 'child_process'
coffee = require 'coffee-script'

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
  # check for existing source files
  src = path.join dir, 'src'
  unless fs.existsSync src
    return cb "No source files found."
  # cleanup old files
  lib = path.join dir, 'lib'
  console.log "Remove old lib directory"
  fs.remove lib, (err) ->
    return cb err if err
    compileCoffee dir, options, (err) ->
      return cb err if err
      compileMan dir, options, cb

# ### Compile coffee script
compileCoffee = (dir, options, cb) ->
  src = path.join dir, 'src'
  lib = path.join dir, 'lib'
  # find files to compile
  fs.find src, { include: '*.coffee' }, (err, files) ->
    return cb err if err
    return cb() unless files
    console.log "Compile coffee script"
    async.each files, (file, cb) ->
      fs.readFile file, 'utf8', (err, data) ->
        return cb err if err
        jsfile = path.basename(file, '.coffee') + '.js'
        mapfile = path.basename(file, '.coffee') + '.map'
        console.log chalk.grey "Compile #{file}" if options.verbose
        compiled = coffee.compile data,
          filename: path.basename file
          generatedFile: jsfile
          sourceRoot: path.relative path.dirname(file), dir
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
          return cb err if err or not options.uglify
          console.log chalk.grey "Uglify #{jsfile}" if options.verbose
          uglify
            dir: path.dirname filepathjs
            fromjs: jsfile
            frommap: mapfile
            tojs: jsfile
            tomap: mapfile
          , cb
    , cb

# ### Compile coffee script
compileMan = (dir, options, cb) ->
  file = path.join dir, 'package.json'
  pack = JSON.parse fs.readFileSync file
  return cb() unless pack.man?
  console.log "Compile man pages"
  src = path.join dir, 'src'
  if typeof pack.man is 'string'
    input = "#{src}/#{pack.man}.md"
    unless fs.existsSync input
      return cb new Error "The file '#{input}' didn't exist."
    fs.mkdirs path.dirname("#{dir}/#{pack.man}"), (err) ->
      console.log chalk.grey "Create #{pack.man}" if options.verbose
      exec "#{__dirname}/../node_modules/.bin/marked-man #{input} > #{dir}/#{pack.man}", cb
  else
    console.log "Array definition for man pages not implemented, yet."
    cb()

# ### Run uglify for all javascript in directory
uglify = (item, cb) ->
  fs.npmbin 'uglifyjs', path.dirname(__dirname), (err, cmd) ->
    return cb err if err
    args = [
      item.fromjs,
      '--source-map', item.tomap
      '-o', item.tojs
    ]
    args.push '--in-source-map', item.frommap if item.frommap
    debug "exec #{item.dir}> #{cmd} #{args.join ' '}"
    execFile cmd, args, { cwd: item.dir }, (err, stdout, stderr) ->
      console.log chalk.grey stdout.trim() if stdout and options.verbose
      console.error chalk.magenta stderr.trim() if stderr
      cb err
