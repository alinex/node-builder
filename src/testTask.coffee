# Push new version  to GitHub and npm
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
async = require 'async'
fs = require 'fs'
path = require 'path'
colors = require 'colors'
{spawn,exec, execFile} = require 'child_process'

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
  coffeelint command, (err) ->
    return cb err if err
    execFile 'npm', [ 'install' ], { cwd: command.dir }
    , (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and command.verbose
      console.error stderr.trim().magenta if stderr and command.verbose
      return cb err if err
      test command, (err) ->
        return cb err if err
        coverage command, (err) ->
          return cb err if err
          url = path.join GLOBAL.ROOT_DIR, command.dir, 'coverage', 'lcov-report', 'index.html'
          return openUrl command, url, cb if command.browser
          cb()


# ### Open the given url in the default browser
openUrl = (command, target, cb) ->
  if command.verbose
    console.log "Open #{target} in browser".grey
  opener = switch process.platform
    when 'darwin' then 'open'
    # if the first parameter to start is quoted, it uses that as the title
    # so we pass a blank title so we can quote the file we are opening
    when 'win32' then 'start ""'
    # use Portlands xdg-open everywhere else
    else path.join GLOBAL.ROOT_DIR, 'bin/xdg-open'
  return exec opener + ' "' + escape(target) + '"', cb


# ### Run lint against coffee script
coffeelint = (command, cb) ->
  # Check for existing command
  bin = path.join GLOBAL.ROOT_DIR, "node_modules/.bin/coffeelint"
  unless fs.existsSync bin
    console.log "Skipped lint because coffeelint is missing".yellow
    return cb?()
  # Run external command
  if command.verbose
    console.log "Linting code".grey
  if command.colors
    proc = spawn bin, [
      '-f', path.join GLOBAL.ROOT_DIR, 'coffeelint.json'
      'src'
    ], { cwd: command.dir, stdio: 'inherit' }
  else
    proc = spawn bin, [
      '-f', path.join GLOBAL.ROOT_DIR, 'coffeelint.json'
      'src'
    ], { cwd: command.dir }
    proc.stdout.on 'data', (data) ->
      if command.verbose
        console.log data.toString().trim()
    proc.stderr.on 'data', (data) ->
      console.error data.toString().trim().magenta
  # Error management
  proc.on 'error', cb
  proc.on 'exit', (status) ->
    if status != 0
      status = "Coffeelint exited with status #{status}"
    cb status


# ### Run tests like defined in package.json
# It will add the -w flag if `--watch` is set.
test = (command, cb) ->
  if command.verbose
    console.log "Read package.json".grey
  pack = JSON.parse fs.readFileSync path.join command.dir, 'package.json'
  unless pack.scripts?.test?
    console.log "Skipped because no tests defined in package.json".yellow
    return cb()
  execFile 'npm', [ 'install' ], { cwd: command.dir }
  , (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and command.verbose
    console.error stderr.trim().magenta if stderr and command.verbose
    return cb err if err
    console.log "Run test scripts"
    args = pack.scripts.test.split /\s+/
    cmd = args.shift()
    args.push '-w' if command.watch
    proc = spawn cmd, args, { cwd: command.dir, stdio: 'inherit' }
    # Error management
    proc.on 'error', cb
    proc.on 'exit', (status) ->
      if status != 0
        status = "Test exited with status #{status}"
      cb status

# ### Create local coverage report
coverage = (command, cb) ->
  bin = path.join command.dir, "node_modules/.bin/istanbul"
  unless fs.existsSync bin
    console.log "Skipped coverage because istanbul is missing".yellow
    return cb?()
  if command.verbose
    console.log "Read package.json".grey
  pack = JSON.parse fs.readFileSync path.join command.dir, 'package.json'
  unless pack.scripts?.test?
    console.log "Skipped because no tests defined in package.json".yellow
    return cb()
  args = pack.scripts.test.split /\s+/
  tool = args.shift().replace /\/mocha$/, '/_mocha'
  args.unshift 'cover', tool, '--'
  proc = spawn bin, args, { cwd: command.dir }
  proc.stdout.on 'data', (data) ->
    if command.verbose
      console.log data.toString().trim()
  proc.stderr.on 'data', (data) ->
    console.error data.toString().trim().magenta
  # Error management
  proc.on 'error', cb
  proc.on 'exit', (status) ->
    if status != 0
      status = new Error "Istanbul exited with status #{status}"
    cb status


