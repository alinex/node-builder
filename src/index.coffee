# Main controlling class
# =================================================


# Node Modules
# -------------------------------------------------

# include base modules
path = require 'path'
chalk = require 'chalk'
# include alinex modules
async = require 'alinex-async'
config = require 'alinex-config'
Exec = require 'alinex-exec'


# Initialize
# -------------------------------------------------
exports.setup = (cb) ->
  async.each [Exec], (mod, cb) ->
    mod.setup cb
  , (err) ->
    return cb err if err
    # set module search path
    config.register 'scripter', path.dirname __dirname
    cb()

# Output Helper
# -------------------------------------------------
exports.command = (name, lib, args, cb) ->
  console.log "Run #{name} command..."
  if lib.options
    for name, def of lib.options
      console.log "#{def.describe ? name} = #{args[name]}" if args[name]
  try
    lib.handler args, cb
  catch error
    error.description = error.stack.split(/\n/)[1..].join '\n'
    cb error

exports.info = (dir, args, message) ->
  if args.verbose
    console.log chalk.grey "#{path.basename dir}: #{message}"

exports.debug = (dir, args, message) ->
  if args.verbose > 1
    console.log chalk.grey "#{path.basename dir}: #{message}"

exports.noisy = (dir, args, message) ->
  if args.verbose > 2
    console.log chalk.grey "#{path.basename dir}: #{message}"


# Controll flow helper
# -------------------------------------------------

exports.dirs = (args, fn, cb) ->
  # check for directories
  list = args._[1..]
  list.push path.dirname __dirname unless list.length
  list = list.map (e) -> path.resolve e
  # execute
  problems = []
  async.eachLimit list, 3, (dir, cb) ->
    exports.info dir, args, 'started'
    fn dir, args, (err) ->
      exports.info dir, args, 'done'
      problems.push "#{path.basename dir}: #{err.message}" if err
      cb()
  , ->
    return cb() unless problems.length
    cb new Error problems.join '\n'

exports.task = (task, dir, args, cb) ->
  try
    lib = require "./task/#{task}"
    lib dir, args, cb
  catch error
    cb error

exports.exec = (dir, args, type, exec, cb) ->
  exports.debug dir, args, "#{type}"
  exports.debug dir, args, "> #{exec.cmd} #{exec.args.join ' '}"
  Exec.run exec, (err, proc) ->
    if proc.stdout() and args.verbose > 2
      console.log()
      console.log "#{path.basename dir}: #{type}"
      console.log()
      console.log chalk.grey proc.stdout().trim().replace /s*\n+/g, '\n'
      console.error chalk.magenta proc.stderr().trim() if proc.stderr()
      console.log()
    cb err, proc

exports.results = (dir, options, title, results) ->
  # output results
  console.log()
  console.log chalk.bold title
  console.log()
  console.log resultsJoin(results).trim()
  console.log()

resultsJoin = (res) ->
  return res if typeof res is 'string'
  if Array.isArray res
    resultsJoin(res).join ''
  else
    ''
