# Push new version  to GitHub and npm
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
debug = require('debug')('builder:test')
path = require 'path'
chalk = require 'chalk'
{spawn,exec, execFile} = require 'child_process'
fs = require 'alinex-fs'
async = require 'alinex-async'

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
  coffeelint dir, options, (err) ->
    return cb err if err
#    debug "exec #{dir}> npm install"
#    execFile 'npm', [ 'install' ], { cwd: dir }
#    , (err, stdout, stderr) ->
#      console.log stdout.trim().grey if stdout and options.verbose
#      console.error stderr.trim().magenta if stderr and options.verbose
#      return cb err if err
    testMocha dir, options, (err) ->
      return cb err if err
      coverage dir, options, (err) ->
        return cb err if err
        url = path.join GLOBAL.ROOT_DIR, dir, 'coverage', 'lcov-report', 'index.html'
        return openUrl options, url, cb if options.coverage and options.browser
        cb()


# ### Open the given url in the default browser
openUrl = (options, target, cb) ->
  if options.verbose
    console.log chalk.grey "Open #{target} in browser"
  opener = switch process.platform
    when 'darwin' then 'open'
    # if the first parameter to start is quoted, it uses that as the title
    # so we pass a blank title so we can quote the file we are opening
    when 'win32' then 'start ""'
    # use Portlands xdg-open everywhere else
    else path.join GLOBAL.ROOT_DIR, 'bin/xdg-open'
  debug "exec> #{opener} \"#{encodeURI target}\""
  return exec opener + ' "' + encodeURI(target) + '"', cb


# ### Run lint against coffee script
coffeelint = (dir, options, cb) ->
  # Check for existing options
  fs.npmbin 'coffeelint', path.dirname(path.dirname __dirname), (err, cmd) ->
    if err
      console.log chalk.yellow "Skipped lint because coffeelint is missing"
      return cb?()
    # Run external options
    console.log "Linting coffee code"
    debug "exec #{dir}> #{cmd} -f #{path.join GLOBAL.ROOT_DIR, 'coffeelint.json'} src"
    if options.nocolors
      proc = spawn cmd, [
        '-f', path.join GLOBAL.ROOT_DIR, 'coffeelint.json'
        'src'
      ], { cwd: dir, stdio: 'inherit' }
    else
      proc = spawn cmd, [
        '-f', path.join GLOBAL.ROOT_DIR, 'coffeelint.json'
        'src'
      ], { cwd: dir }
      proc.stdout.on 'data', (data) ->
        if options.verbose
          console.log data.toString().trim()
      proc.stderr.on 'data', (data) ->
        console.error chalk.magenta data.toString().trim()
    # Error management
    proc.on 'error', cb
    proc.on 'exit', (status) ->
      if status != 0
        status = "Coffeelint exited with status #{status}"
      cb status


# ### Run tests like defined in package.json
# It will add the -w flag if `--watch` is set.
testMocha = (dir, options, cb) ->
  # check if there are any mocha tests
  mochadir = path.join dir, 'test', 'mocha'
  unless fs.existsSync mochadir
    console.log chalk.magenta "No mocha test dir found at #{mochadir}."
    return cb()
  # Check for existing options
  fs.npmbin 'istanbul', path.dirname(path.dirname __dirname), (err, cmd) ->
    return cb err if err
    mocha = if options.coverage then '_mocha' else 'mocha'
    fs.npmbin mocha, path.dirname(path.dirname __dirname), (err, mocha) ->
      return cb err if err
      # Run external command
      console.log "Run mocha tests"
      args = []
      if options.coverage
        args.push 'cover', mocha, '--', '--require', 'coffee-coverage/register-istanbul'
      else
        cmd = mocha
        args.push '-w' if options.watch
      args.push '--compilers', 'coffee:coffee-script/register'
      args.push '--reporter', 'spec'
      args.push '-c' # colors
      args.push '--recursive'
      args.push '--bail' if options.bail
      args.push 'test/mocha'
      debug "exec #{dir}> #{cmd} #{args.join ' '}"
      proc = spawn cmd, args, { cwd: dir, stdio: 'inherit', env: process.env }
      # Error management
      proc.on 'error', cb
      proc.on 'exit', (status) ->
        if status != 0
          status = "Test exited with status #{status}"
        cb status

# ### Create local coverage report
coverage = (dir, options, cb) ->
  return cb() unless options.coverage
  # check if there are any mocha tests
  mochadir = path.join dir, 'test', 'mocha'
  unless fs.existsSync mochadir
    return cb "Coverage only works on mocha tests."
  # Check for existing options
  fs.npmbin 'istanbul', path.dirname(path.dirname __dirname), (err, cmd) ->
    return cb err if err
    # Run external command
    console.log "Create coverage report"
    debug "exec #{dir}> #{cmd} report"
    proc = spawn cmd, ['report'], { cwd: dir }
    if options.verbose
      proc.stderr.on 'data', (data) ->
        console.error chalk.grey data.toString().trim()
    # Error management
    proc.on 'error', cb
    proc.on 'exit', (status) ->
      if status != 0
        return cb "Istanbul exited with status #{status}"
      if options.coveralls
        return coveralls dir, options, cb
      cb()

# ### Send coverage data to coveralls
coveralls = (dir, options, cb) ->
  file = path.join dir, 'coverage', 'lcov.info'
  coveralls = path.join GLOBAL.ROOT_DIR, 'node_modules/coveralls/bin/coveralls.js'
  debug "exec> cat #{file} | #{coveralls} --verbose"
  exec "cat #{file} | #{coveralls} --verbose", (err, stdout, stderr) ->
    console.log stdout.toString().trim() if stdout
    cb err
