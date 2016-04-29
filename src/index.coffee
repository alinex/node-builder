# Main controlling class
# =================================================


# Node Modules
# -------------------------------------------------

# include base modules
path = require 'path'
chalk = require 'chalk'
async = require 'async'
# include alinex modules
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
exports.command = (name, lib, options, cb) ->
  console.log "Run #{name} command..."
  if lib.options
    for name, def of lib.options
      console.log "#{def.describe ? name} = #{options[name]}" if options[name]
  try
    lib.handler options, cb
  catch error
    error.description = error.stack.split(/\n/)[1..].join '\n'
    cb error

exports.info = (dir, options, message) ->
  if options.verbose
    console.log chalk.grey "#{path.basename dir}: #{message}"

exports.debug = (dir, options, message) ->
  if options.verbose > 1
    console.log chalk.grey "#{path.basename dir}: #{message}"

exports.noisy = (dir, options, message) ->
  if options.verbose > 2
    console.log chalk.grey "#{path.basename dir}: #{message}"


# Controll flow helper
# -------------------------------------------------

exports.dirs = (options, fn, cb) ->
  # check for directories
  list = options._[1..]
  list.push process.cwd() unless list.length
  list = list.map (e) -> path.resolve e
  # execute
  problems = []
  async.eachLimit list, 3, (dir, cb) ->
    exports.info dir, options, "started in #{dir}"
    fn dir, options, (err) ->
      exports.info dir, options, 'done'
      problems.push "#{path.basename dir}: #{err.message}" if err
      cb()
  , ->
    return cb() unless problems.length
    cb new Error problems.join '\n'

exports.task = (task, dir, options, cb) ->
  try
    lib = require "./task/#{task}"
    lib dir, options, cb
  catch error
    cb error

exports.exec = (dir, options, type, exec, cb) ->
  exports.debug dir, options, "#{type}"
  exports.debug dir, options, "> #{exec.cmd} #{exec.args.join ' '}"
  Exec.run exec, (err, proc) ->
    if proc.stdout() and options.verbose > 2
      console.log()
      console.log "#{path.basename dir}: #{type}"
      console.log()
      console.log chalk.grey proc.stdout().trim().replace /s*\n+/g, '\n'
      console.error chalk.magenta proc.stderr().trim() if proc.stderr()
      console.log()
    if err and proc.stderr() and options.verbose < 3
      exports.results dir, options, type, chalk.magenta proc.stderr()
    cb err, proc

exports.results = (dir, options, title, results) ->
  return unless results = resultsJoin(results).trim()
  # output results
  console.log()
  console.log chalk.bold title
  console.log()
  console.log results
  console.log()
  results

resultsJoin = (res) ->
  return res.trim() if typeof res is 'string'
  if Array.isArray res
    res.map (e) -> resultsJoin e
    .join '\n\n'
  else
    ''
