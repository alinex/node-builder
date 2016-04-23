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

exports.title = 'push changes to remote repository'
exports.description = """
Push the newest changes to the origin repository. This includes all tags.
"""

exports.options =
  message:
    alias: 'm'
    type: 'string'
    describe: 'Commit message for local changes.'


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
    status dir, args, (err) ->
      unless err
        return push dir, args, cb
      unless args.messgae
        return cb err
      commit dir, args, (err) ->
        return cb err if err
        push dir, args, cb

status = (dir, args, cb) ->
  if args.verbose > 1
    console.log chalk.grey "#{path.basename dir}: git - check status"
  Exec.run
    cmd: 'git'
    args: [ 'status' ]
    cwd: dir
    env:
      LANG: 'C'
  , (err, proc) ->
    return cb err if err
    return cb() if ~proc.stdout().indexOf 'nothing to commit'
    console.log proc.stdout() if args.verbose > 2
    cb new Error "Skipped push for #{dir} because not all changes are committed,
    use '--message <message>' to commit or see changes using `builder -c changes`."

commit = (dir, args, cb) ->
  if args.verbose > 1
    console.log chalk.grey "#{path.basename dir}: git - commit"
  Exec.run
    cmd: 'git'
    args: [ 'add', '-A' ]
    cwd: dir
  , (err, proc) ->
    if proc.stdout() and args.verbose > 2
      console.log()
      console.log chalk.bold "Commit for #{path.basename dir} "
      console.log()
      console.log chalk.grey proc.stdout().trim()
      console.error chalk.magenta proc.stderr().trim() if proc.stderr()
      console.log()
    return cb err if err
    Exec.run
      cmd: 'git'
      args: [ 'commit', '-m', args.message ]
      cwd: dir
      retry:
        times: 3
      check:
        noExitCode: true
    , (err, proc) ->
      # ignore error because it will get
      console.log chalk.grey proc.stdout().trim() if proc.stdout() and options.verbose
      console.error chalk.magenta proc.stderr().trim() if proc.stderr()
      cb err


push = (dir, args, cb) ->
  if args.verbose > 1
    console.log chalk.grey "#{path.basename dir}: git - push to origin"
  Exec.run
    cmd: 'git'
    args: [ 'push', '--tags', 'origin', 'master' ]
    cwd: dir
    retry:
      times: 3
  , (err, proc) ->
    if proc.stdout() and args.verbose > 2
      console.log()
      console.log chalk.bold "Push for #{path.basename dir} "
      console.log()
      console.log chalk.grey proc.stdout().trim()
      console.log chalk.magenta proc.stderr().trim() if proc.stderr()
      console.log()
    if args.verbose
      console.log chalk.grey "#{path.basename dir}: git - done"
    cb err, true
