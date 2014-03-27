# Push new version  to GitHub and npm
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
async = require 'async'
fs = require 'fs'
path = require 'path'
colors = require 'colors'
{execFile} = require 'child_process'
request = require 'request'

# Main routine
# -------------------------------------------------
#
# __Arguments:__
#
# * `commander`
#   Commander instance for reading options.
# * `command`
#   Command specific parameters and options.
# * `callback(err)`
#   The callback will be called just if an error occurred or with `null` if
#   execution finished.
module.exports.run = (commander, command, cb) ->
  file = path.join command.dir, 'package.json'
  pack = JSON.parse fs.readFileSync file
  command.oldVersion = pack.version
  # calculate new version
  if commander.verbose
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
  if commander.verbose
    console.log "New version is #{pack.version}".grey
  # write new version number into package.json
  console.log "Change package.json"
  fs.writeFile file, JSON.stringify(pack, null, 2), (err) ->
    return cb err if err
    async.series [
      (cb) -> updateChangelog commander, command, cb
      (cb) -> commitChanges commander, command, cb
      (cb) -> pushOrigin commander, command, cb
      (cb) -> gitTag commander, command, cb
      (cb) -> pushNpm commander, command, cb
    ], (err) ->
      throw err if err
      console.log "Created v#{pack.version}.".green
      cb()

# ### add changes since last version to Changelog
updateChangelog = (commander, command, cb) ->
  if commander.verbose
    console.log "Read git log".grey
  args = [ 'log', '--pretty=format:%s' ]
  unless command.oldVersion is '0.0.0'
    args.push "v#{command.oldVersion}..HEAD"
  execFile "git", args, { cwd: command.dir }, (err, stdout, stderr) ->
    console.error stderr.trim().magenta if stderr
    return cb err if err
    file = path.join command.dir, 'Changelog.md'
    lines = fs.readFileSync(file, 'utf-8').split /\n/
    changelog = lines[..5].join('\n') + """

      Version #{command.newVersion}
      -------------------------------------------------
      #{stdout.trim()}

      """ + lines[5..].join('\n')
    console.log "Write new changelog"
    fs.writeFile file, changelog, (err) ->
      return cb err if err
      cb()

# ### Commit changes in Changelog and package.json
commitChanges = (commander, command, cb) ->
  console.log "Commit new version information"
  execFile "git", [
    'add'
    'package.json', 'Changelog.md'
  ], { cwd: command.dir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and commander.verbose
    console.error stderr.trim().magenta if stderr
    return cb err if err
    execFile "git", [
      'commit'
      '-m', "Added information for version #{command.newVersion}"
    ], { cwd: command.dir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and commander.verbose
      console.error stderr.trim().magenta if stderr
      return cb err if err
      cb()

# ### Push to git origin
pushOrigin = (commander, command, cb) ->
  console.log "Push to git origin"
  execFile "git", [
    'push'
    'origin', 'master'
  ], { cwd: command.dir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and commander.verbose
    console.error stderr.trim().magenta if stderr
    return cb err if err
    cb()

# ### Add version tag to git
gitTag = (commander, command, cb) ->
  console.log "Push new tag to git origin"
  execFile "git", [
    'tag'
    '-a', "v#{command.newVersion}"
    '-m', "Created version #{command.newVersion}"
  ], { cwd: command.dir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and commander.verbose
    console.error stderr.trim().magenta if stderr
    return cb err if err
    execFile "git", [
      'push'
      'origin', "v#{command.newVersion}"
    ], { cwd: command.dir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and commander.verbose
      console.error stderr.trim().magenta if stderr
      return cb err if err
      cb()

# ### Push new version to npm
pushNpm = (commander, command, cb) ->
  console.log "Push to npm"
  execFile 'npm', [ 'install' ], { cwd: command.dir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and commander.verbose
    console.error stderr.trim().magenta if stderr
    return cb err if err
    execFile 'npm', [ 'publish' ], { cwd: command.dir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and commander.verbose
      console.error stderr.trim().magenta if stderr
      return cb err if err
      cb()
