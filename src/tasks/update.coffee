# Install a package with newest node-modules
# =================================================


# Node modules
# -------------------------------------------------

# include alinex modules
Spawn = require 'alinex-spawn'
# include base modules
async = require 'async'
fs = require 'alinex-fs'
path = require 'path'
chalk = require 'chalk'
{spawn,exec, execFile} = require 'child_process'

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
  async.series [
    (cb) -> switchRepository dir, options, cb
    (cb) -> npmInstall dir, options, cb
    (cb) -> npmUpdate dir, options, cb
    (cb) -> npmOutdated dir, options, cb
    (cb) -> switchRepository dir, {registry:'https://registry.npmjs.org/'}, cb
  ], cb

switchRepository = (dir, options, cb) ->
  # check for changed registry
  file = path.join dir, 'package.json'
  try
    pack = JSON.parse fs.readFileSync file
  catch err
    return cb new Error "Could not load #{file} as valid JSON."
  # change or change back
  registry = if options.registry then options.registry else pack.publishConfig?.registry
  registry ?= 'https://registry.npmjs.org/'
  # get old registry
  proc = new Spawn
    priority: 9
    cmd: 'npm'
    args: [ 'set', 'registry', registry ]
    cwd: dir
    input: 'inherit'
    check: (proc) -> new Error "Got exit code of #{proc.code}" if proc.code
  proc.run cb

# ### Install necessary modules
npmInstall = (dir, options, cb) ->
  # Run external command
  console.log "Install through npm"
  proc = new Spawn
    priority: 9
    cmd: 'npm'
    args: [ 'install' ]
    cwd: dir
    input: 'inherit'
    check: (proc) -> new Error "Got exit code of #{proc.code}" if proc.code
  proc.run cb

# ### Update all modules
npmUpdate = (dir, options, cb) ->
  # Run external command
  console.log "Update npm packages"
  proc = new Spawn
    priority: 9
    cmd: 'npm'
    args: [ 'update' ]
    cwd: dir
    input: 'inherit'
    check: (proc) -> new Error "Got exit code of #{proc.code}" if proc.code
  proc.run cb

# ### List outdated modules
npmOutdated = (dir, options, cb) ->
  # Run external command
  console.log "List outdated packages"
  fs.npmbin 'npm-check', path.dirname(path.dirname __dirname), (err, cmd) ->
    proc = new Spawn
      priority: 9
      cmd: cmd
      args: ['-p']
      cwd: dir
      input: 'inherit'
      check: (proc) -> new Error "Got exit code of #{proc.code}" if proc.code
    proc.run (err, stdout) ->
      lines = stdout.split /\n/
      if lines.length is 1
        console.log chalk.grey "Nothing to upgrade or fix in this package found."
        return cb()
      for line in lines[0..lines.length-2]
        continue unless line = line.trim()
        console.log line
      cb new Error "You may upgrade the listed modules using: #{cmd} -u"