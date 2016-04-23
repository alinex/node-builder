# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# include base modules
chalk = require 'chalk'
path = require 'path'
# include alinex modules
async = require 'alinex-async'
fs = require 'alinex-fs'
Exec = require 'alinex-exec'

# Setup
# -------------------------------------------------

exports.title = 'show changes since last release'
exports.description = """
List all changes since last published version. This contains local file changes,
last commits and updates of depending packages.
"""

exports.options =
  'skip-unused':
    alias: 's'
    type: 'boolean'
    describe: 'Skip check for unused packages.'


# Handler
# ------------------------------------------------

exports.handler = (args, cb) ->
  for name, def of exports.options
    console.log def.describe ? name if args[name]
  # check for directories
  list = args._[1..]
  list.push path.dirname(path.dirname __dirname) unless list.length
  list = list.map (e) -> path.resolve e
  if args.verbose
    console.log chalk.grey "working on the following directories:\n -> " + list.join '\n -> '
  # gather information
  async.eachLimit list, 3, (dir, cb) ->
    async.parallel [
      (cb) -> git dir, args, cb
      (cb) -> npm dir, args, cb
    ], (err, results) ->
      return cb err if err
      # output results
      console.log()
      console.log chalk.bold "Results for #{path.basename dir} "
      console.log()
      console.log results.join('').trim()
      console.log()
      cb()
  , cb


# Helper
# ------------------------------------------------

npm = (dir, args, cb) ->
  # check for existing git repository
  if args.verbose
    console.log chalk.grey "#{path.basename dir}: npm packages - check"
  fs.npmbin 'npm-check', path.dirname(path.dirname __dirname), (err, cmd) ->
    msg = "NPM Update check:\n"
    params = []
    params.push '-s' if args['skip-unused']
    Exec.run
      cmd: cmd
      args: params
      cwd: dir
      check:
        exitCode:
          args: [0, 1]
    , (err, proc) ->
      console.log chalk.magenta err.message if err
      if proc.stdout()
        for line in proc.stdout().trim().split /\n/
          continue if line.match /Use npm-check/
          msg += chalk.yellow "- #{line.trim()}\n" if line.match /^\w/
          if match = line.match /to go (from .*)/
            msg = msg.replace /(\s*http.*)?\n.*?$/, chalk.grey " #{match[1]}\n"
      console.error chalk.magenta proc.stderr().trim() if proc.stderr()
      return cb err, '' if msg.split(/\n/).length < 3
      msg += chalk.grey "Use `#{chalk.underline 'npm install'}` or
      `#{chalk.underline cmd + ' -u'}` to upgrade.\n"
      if args.verbose
        console.log chalk.grey "#{path.basename dir}: npm packages - done"
      cb null, msg

git = (dir, args, cb) ->
  # check for existing git repository
  if args.verbose
    console.log chalk.grey "#{path.basename dir}: git - check if configured"
  fs.exists path.join(dir, '.git'), (exists) ->
    return cb() unless exists # no git repository
    async.parallel [
      (cb) -> gitChanges dir, args, cb
      (cb) -> gitStatus dir, args, cb
    ], (err, results) ->
      return cb err if err
      if args.verbose
        console.log chalk.grey "#{path.basename dir}: git - done"
      cb null, results.join ''


gitChanges = (dir, args, cb) ->
  if args.verbose > 1
    console.log chalk.grey "#{path.basename dir}: git - check commits"
  # run the pull args
  Exec.run
    cmd: 'git'
    args: [ 'describe', '--abbrev=0' ]
    cwd: dir
  , (err, proc) ->
    tag = proc.stdout().trim()
    msg = "Changes since last publication as #{tag}:\n"
    Exec.run
      cmd: 'git'
      args: ['log', "#{tag}..HEAD", "--format=oneline"]
      cwd: dir
    , (err, proc) ->
      return cb err if err
      if proc.stdout()
        msg += chalk.yellow "- #{line[41..]}\n" for line in proc.stdout().trim().split /\n/
      else
        msg += chalk.yellow "Nothing changed.\n"
      console.error chalk.magenta proc.stderr().trim() if proc.stderr()
      cb err, msg

gitStatus = (dir, args, cb) ->
  if args.verbose > 1
    console.log chalk.grey "#{path.basename dir}: git - check status"
  msg = ''
  # run the pull args
  Exec.run
    cmd: 'git'
    args: ['status']
    cwd: dir
  , (err, proc) ->
    return cb err if err
    if proc.stdout()
      for line in proc.stdout().trim().split /\n/
        msg += "#{line.trim()}\n" if line.match /^Changes/
        msg += chalk.yellow "- #{line.trim().replace /\s+/g, ' '}\n" if line.match /^\t/
    else
      msg += chalk.yellow "Nothing changed.\n"
    console.error chalk.magenta proc.stderr().trim() if proc.stderr()
    cb err, msg
