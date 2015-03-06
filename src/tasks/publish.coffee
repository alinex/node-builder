# Publish new version to GitHub and npm
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
debug = require('debug')('make:publish')
async = require 'async'
path = require 'path'
chalk = require 'chalk'
{execFile} = require 'child_process'
request = require 'request'
moment = require 'moment'
# include alinex modules
fs = require 'alinex-fs'

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
  # check that all test cases are correct
  checkTests dir, (err) ->
    return cb err if err
    # create new version
    file = path.join dir, 'package.json'
    pack = JSON.parse fs.readFileSync file
    options.oldVersion = pack.version
    # calculate new version
    if options.verbose
      console.log chalk.grey "Old version is #{options.oldVersion}"
    version = pack.version.split /\./
    if options.major
      version[0]++
      version[1] = version[2] = 0
    else if options.minor
      version[1]++
      version[2] = 0
    else
      version[2]++
    options.newVersion = pack.version = version.join '.'
    if options.verbose
      console.log chalk.grey "New version is #{pack.version}"
    # write new version number into package.json
    console.log "Change package.json"
    fs.writeFile file, JSON.stringify(pack, null, 2), (err) ->
      return cb err if err
      async.series [
        (cb) -> updateChangelog dir, options, cb
        (cb) -> commitChanges dir, options, cb
        (cb) -> pushOrigin dir, options, cb
        (cb) -> gitTag dir, options, cb
        (cb) -> pushNpm dir, options, cb
      ], (err) ->
        throw err if err
        console.log chalk.green "Created v#{pack.version}."
        cb()

# ### check for .only tests
checkTests = (dir) ->
  fs.find path.join(dir, 'test', 'mocha'),
    type: 'file'
  , (err, list) ->
    return cb err if err
    async.each list, (file, cb) ->
      # check for .only tests
      fs.readFile file, 'utf-8', (err, content) ->
        return err if err
        if content.match /(describe|it)\.only/
          return cb file
        cb()
    , (err, file) ->
      return cb() unless err
      if typeof err is 'string'
        return cb new Error "Tests with .only were found in #{err}. But a full test is neccessary to publish."
      cb err

# ### add changes since last version to Changelog
updateChangelog = (dir, options, cb) ->
  if options.verbose
    console.log chalk.grey "Read git log"
  args = [ 'log', '--pretty=format:%s' ]
  unless options.oldVersion is '0.0.0'
    args.push "v#{options.oldVersion}..HEAD"
  debug "exec #{dir}> git #{args.join ' '}"
  execFile "git", args, { cwd: dir }, (err, stdout, stderr) ->
    console.log chalk.grey stderr.trim() if stdout and options.verbose
    console.error chalk.magenta stderr.trim() if stderr
    return cb err if err
    file = path.join dir, 'Changelog.md'
    lines = fs.readFileSync(file, 'utf-8').split /\n/
    newlines = stdout.trim().split(/\n/).map (val) -> "- #{val}"
    changelog = lines[..5].join('\n') + """

      Version #{options.newVersion} (#{moment().format('YYYY-MM-DD')})
      -------------------------------------------------
      #{newlines.join '\n'}

      """ + lines[5..].join('\n')
    console.log "Write new changelog"
    fs.writeFile file, changelog, (err) ->
      return cb err if err
      cb()

# ### Commit changes in Changelog and package.json
commitChanges = (dir, options, cb) ->
  console.log "Commit new version information"
  debug "exec #{dir}> git add package.json Changelog.md"
  execFile "git", [
    'add'
    'package.json', 'Changelog.md'
  ], { cwd: dir }, (err, stdout, stderr) ->
    console.log chalk.grey stdout.trim() if stdout and options.verbose
    console.error chalk.magenta stderr.trim() if stderr
    return cb err if err
    debug "exec #{dir}> git commit \"Added information for version #{options.newVersion}\""
    execFile "git", [
      'commit'
      '-m', "Added information for version #{options.newVersion}"
    ], { cwd: dir }, (err, stdout, stderr) ->
      console.log chalk.grey stdout.trim() if stdout and options.verbose
      console.error chalk.magenta stderr.trim() if stderr
      return cb err if err
      cb()

# ### Push to git origin
pushOrigin = (dir, options, cb) ->
  console.log "Push to git origin"
  debug "exec #{dir}> git push origin master"
  execFile "git", [
    'push'
    'origin', 'master'
  ], { cwd: dir }, (err, stdout, stderr) ->
    console.log chalk.grey stdout.trim() if stdout and options.verbose
    console.error chalk.magenta stderr.trim() if stderr
    return cb err if err
    cb()

# ### Add version tag to git
gitTag = (dir, options, cb) ->
  file = path.join dir, 'package.json'
  pack = JSON.parse fs.readFileSync file
  changelog = ''
  if pack.homepage?
    changelog = " see more in [Changelog.md](#{pack.homepage}/Changelog.md.html)"
  console.log "Push new tag to git origin"
  debug "exec #{dir}> git tag -a v#{options.newVersion} -m \"Created version #{options.newVersion}#{changelog}\""
  execFile "git", [
    'tag'
    '-a', "v#{options.newVersion}"
    '-m', "Created version #{options.newVersion}#{changelog}"
  ], { cwd: dir }, (err, stdout, stderr) ->
    console.log chalk.grey stdout.trim() if stdout and options.verbose
    console.error chalk.magenta stderr.trim() if stderr
    return cb err if err
    debug "exec #{dir}> git push origin v#{options.newVersion}"
    execFile "git", [
      'push'
      'origin', "v#{options.newVersion}"
    ], { cwd: dir }, (err, stdout, stderr) ->
      console.log chalk.grey stdout.trim() if stdout and options.verbose
      console.error chalk.magenta stderr.trim() if stderr
      return cb err if err
      cb()

# ### Push new version to npm
pushNpm = (dir, options, cb) ->
  console.log "Push to npm"
  debug "exec #{dir}> npm install"
  execFile 'npm', [ 'install' ], { cwd: dir }, (err, stdout, stderr) ->
    console.log chalk.grey stdout.trim() if stdout and options.verbose
    console.error chalk.magenta stderr.trim() if stderr
    return cb err if err
    debug "exec #{dir}> npm publish"
    execFile 'npm', [ 'publish' ], { cwd: dir }, (err, stdout, stderr) ->
      console.log chalk.grey stdout.trim() if stdout and options.verbose
      console.error chalk.magenta stderr.trim() if stderr
      return cb err if err
      cb()
