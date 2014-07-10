# Publish new version to GitHub and npm
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
debug = require('debug')('make:publish')
async = require 'async'
fs = require 'fs'
path = require 'path'
colors = require 'colors'
{execFile} = require 'child_process'
request = require 'request'
moment = require 'moment'

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
  file = path.join command.dir, 'package.json'
  pack = JSON.parse fs.readFileSync file
  command.oldVersion = pack.version
  # calculate new version
  if command.verbose
    console.log "Old version is #{command.oldVersion}".grey
  version = pack.version.split /\./
  if command.major
    version[0]++
    version[1] = version[2] = 0
  else if command.minor
    version[1]++
    version[2] = 0
  else
    version[2]++
  command.newVersion = pack.version = version.join '.'
  if command.verbose
    console.log "New version is #{pack.version}".grey
  # write new version number into package.json
  console.log "Change package.json"
  fs.writeFile file, JSON.stringify(pack, null, 2), (err) ->
    return cb err if err
    async.series [
      (cb) -> updateChangelog command, cb
      (cb) -> commitChanges command, cb
      (cb) -> pushOrigin command, cb
      (cb) -> gitTag command, cb
      (cb) -> pushNpm command, cb
    ], (err) ->
      throw err if err
      console.log "Created v#{pack.version}.".green
      cb()

# ### add changes since last version to Changelog
updateChangelog = (command, cb) ->
  if command.verbose
    console.log "Read git log".grey
  args = [ 'log', '--pretty=format:%s' ]
  unless command.oldVersion is '0.0.0'
    args.push "v#{command.oldVersion}..HEAD"
  debug "exec #{command.dir}> git #{args.join ' '}"
  execFile "git", args, { cwd: command.dir }, (err, stdout, stderr) ->
    console.log stderr.trim().grey if stdout and command.verbose
    console.error stderr.trim().magenta if stderr
    return cb err if err
    file = path.join command.dir, 'Changelog.md'
    lines = fs.readFileSync(file, 'utf-8').split /\n/
    newlines = stdout.trim().split(/\n/).map (val) -> "- #{val}"
    changelog = lines[..5].join('\n') + """

      Version #{command.newVersion} (#{moment().format('YYYY-MM-DD')})
      -------------------------------------------------
      #{newlines.join '\n'}

      """ + lines[5..].join('\n')
    console.log "Write new changelog"
    fs.writeFile file, changelog, (err) ->
      return cb err if err
      cb()

# ### Commit changes in Changelog and package.json
commitChanges = (command, cb) ->
  console.log "Commit new version information"
  debug "exec #{command.dir}> git add package.json Changelog.md"
  execFile "git", [
    'add'
    'package.json', 'Changelog.md'
  ], { cwd: command.dir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and command.verbose
    console.error stderr.trim().magenta if stderr
    return cb err if err
    debug "exec #{command.dir}> git commit \"Added information for version #{command.newVersion}\""
    execFile "git", [
      'commit'
      '-m', "Added information for version #{command.newVersion}"
    ], { cwd: command.dir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and command.verbose
      console.error stderr.trim().magenta if stderr
      return cb err if err
      cb()

# ### Push to git origin
pushOrigin = (command, cb) ->
  console.log "Push to git origin"
  debug "exec #{command.dir}> git push origin master"
  execFile "git", [
    'push'
    'origin', 'master'
  ], { cwd: command.dir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and command.verbose
    console.error stderr.trim().magenta if stderr
    return cb err if err
    cb()

# ### Add version tag to git
gitTag = (command, cb) ->
  file = path.join command.dir, 'package.json'
  pack = JSON.parse fs.readFileSync file
  changelog = ''
  if pack.homepage?
    changelog = " see more in [Changelog.md](#{pack.homepage}/Changelog.md.html)"
  console.log "Push new tag to git origin"
  debug "exec #{command.dir}> git tag -a v#{command.newVersion} -m \"Created version #{command.newVersion}#{changelog}\""
  execFile "git", [
    'tag'
    '-a', "v#{command.newVersion}"
    '-m', "Created version #{command.newVersion}#{changelog}"
  ], { cwd: command.dir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and command.verbose
    console.error stderr.trim().magenta if stderr
    return cb err if err
    debug "exec #{command.dir}> git push origin v#{command.newVersion}"
    execFile "git", [
      'push'
      'origin', "v#{command.newVersion}"
    ], { cwd: command.dir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and command.verbose
      console.error stderr.trim().magenta if stderr
      return cb err if err
      cb()

# ### Push new version to npm
pushNpm = (command, cb) ->
  console.log "Push to npm"
  debug "exec #{command.dir}> npm install"
  execFile 'npm', [ 'install' ], { cwd: command.dir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and command.verbose
    console.error stderr.trim().magenta if stderr
    return cb err if err
    debug "exec #{command.dir}> npm publish"
    execFile 'npm', [ 'publish' ], { cwd: command.dir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and command.verbose
      console.error stderr.trim().magenta if stderr
      return cb err if err
      cb()
