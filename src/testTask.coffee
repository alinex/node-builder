# Push new version  to GitHub and npm
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
debug = require('debug')('make:test')
async = require 'async'
fs = require 'alinex-fs'
path = require 'path'
colors = require 'colors'
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
  coffeelint dir, options, (err) ->
    return cb err if err
    debug "exec #{dir}> npm install"
    execFile 'npm', [ 'install' ], { cwd: dir }
    , (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and options.verbose
      console.error stderr.trim().magenta if stderr and options.verbose
      return cb err if err
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
    console.log "Open #{target} in browser".grey
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
  fs.npmbin 'coffeelint', path.dirname(__dirname), (err, cmd) ->
    if err
      console.log "Skipped lint because coffeelint is missing".yellow
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
        console.error data.toString().trim().magenta
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
  dir = path.join dir, 'test', 'mocha'
  unless fs.existsSync dir
    console.log "No mocha test dir found at #{dir}.".magenta
    return cb()
  # Check for existing options
  fs.npmbin 'mocha', path.dirname(__dirname), (err, cmd) ->
    return cb err if err
    # Run external command
    console.log "Run mocha tests"
    args = [
      '--compilers', 'coffee:coffee-script/register'
      '--reporter', 'spec'
      '-c'
      'test/mocha'
    ]
    args.unshift '-w' if options.watch
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
  unless options.coverage
    return cb()
  # check if there are any mocha tests
  dir = path.join dir, 'test', 'mocha'
  unless fs.existsSync dir
    return cb "Coverage only works on mocha tests."
  # Check for existing options
  fs.npmbin 'istanbul', path.dirname(__dirname), (err, cmd) ->
    return cb err if err
    # Run external command
    console.log "Run istanbul coverage report"
    fs.npmbin '_mocha', path.dirname(__dirname), (err, mocha) ->
      return cb err if err
      args = [
        'cover'
        mocha
        '--'
        '--compilers', 'coffee:coffee-script/register'
        '--reporter', 'spec'
        '-c'
        'test/mocha'
      ]
      debug "exec #{dir}> #{cmd} #{args.join ' '}"
      proc = spawn cmd, args, { cwd: dir }
      if options.verbose
        proc.stderr.on 'data', (data) ->
          console.error data.toString().trim().grey
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
