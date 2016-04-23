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

exports.title = 'pull newest version from repository'
exports.description = """
Pull the newest changes from the origin repository.
"""

#exports.options =
#  'skip-unused':
#    alias: 's'
#    type: 'boolean'
#    describe: 'Skip check for unused packages.'


# Handler
# ------------------------------------------------

exports.handler = (args, cb) ->
#  for name, def of exports.options
#    console.log def.describe ? name if args[name]
  # check for directories
  list = args._[1..]
  list.push path.dirname(path.dirname __dirname) unless list.length
  list = list.map (e) -> path.resolve e
  if args.verbose
    console.log chalk.grey "working on the following directories:\n -> " + list.join '\n -> '
  # execute
  async.eachLimit list, 3, (dir, cb) ->
    git dir, args, cb
  , cb


# Helper
# ------------------------------------------------

git = (dir, args, cb) ->
  # check for existing git repository
  if args.verbose
    console.log chalk.grey "#{path.basename dir}: git - check if configured"
  fs.exists path.join(dir, '.git'), (exists) ->
    return cb() unless exists # no git repository
    # run the pull options
    if args.verbose > 1
      console.log chalk.grey "#{path.basename dir}: git - pull from origin"
    Exec.run
      cmd: 'git'
      args: [ 'pull', '-t', '-p', 'origin', 'master' ]
      cwd: dir
      retry:
        times: 3
    , (err, proc) ->
      if proc.stdout() and args.verbose > 2
        console.log()
        console.log chalk.bold "Pull for #{path.basename dir} "
        console.log()
        console.log chalk.grey proc.stdout().trim()
        console.log chalk.magenta proc.stderr().trim() if proc.stderr()
        console.log()
      if args.verbose
        console.log chalk.grey "#{path.basename dir}: git - done"
      cb err, true
