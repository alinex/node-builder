# Task to compile source files like needed
# =================================================


# Node modules
# -------------------------------------------------

# include alinex modules
fs = require 'alinex-fs'
Spawn = require 'alinex-spawn'
# include other modules
debug = require('debug')('make:compile')
path = require 'path'
async = require 'async'
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
  console.log "Remove old directories"
  async.each [path.join(dir, 'lib'), path.join(dir, 'man')], fs.remove, (err) ->
    return cb err if err
    # compile
    async.parallel [
      (cb) -> compileCoffee dir, options, cb
      (cb) -> compileMan dir, options, cb
    ], cb

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
              return cb err if err and err.code isnt 'EEXIST'
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

# ### Compile man pages
compileMan = (dir, options, cb) ->
  file = path.join dir, 'package.json'
  pack = JSON.parse fs.readFileSync file
  return cb() unless pack.man?
  console.log "Compile man pages"
  src = path.join dir, 'src'
  # create output directory
  fs.mkdirs path.join(dir, 'man'), (err) ->
    return cb err if err
    # make all manpages
    pack.man = [pack.man] if typeof pack.man is 'string'
    async.each pack.man, (name, cb) ->
      input = "#{src}/#{name}.md"
      fs.exists input, (exists) ->
        return cb new Error "The file '#{input}' didn't exist." unless exists
        console.log chalk.grey "Create #{pack.man}" if options.verbose
        fs.npmbin 'marked-man', (err, cmd) ->
          proc = new Spawn
            cmd: cmd
            args: [ input ]
          proc.run (err, stdout, stderr, code) ->
            return cb err if err
            fs.writeFile path.join(dir, name), stdout, cb
    , cb

# ### Run uglify for all javascript in directory
uglify = (item, cb) ->
  fs.npmbin 'uglifyjs', (err, cmd) ->
    return cb err if err
    args = [
      item.fromjs,
      '--source-map', item.tomap
      '-o', item.tojs
    ]
    args.push '--in-source-map', item.frommap if item.frommap
    debug "exec #{item.dir}> #{cmd} #{args.join ' '}"
    proc = new Spawn
      cmd: cmd
      args: args
      cwd: item.dir
    proc.run (err, stdout, stderr, code) ->
#    execFile cmd, args, { cwd: item.dir }, (err, stdout, stderr) ->
      console.log chalk.grey stdout.trim() if stdout and options.verbose
      console.error chalk.magenta stderr.trim() if stderr
      cb err
