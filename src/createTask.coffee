# Create new node module
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
async = require 'async'
fs = require 'fs-extra'
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
  async.series [
    (cb) -> createDir commander, command, cb
    (cb) -> initGit commander, command, cb
    (cb) -> createPackage commander, command, cb
    (cb) -> createReadme commander, command, cb
    (cb) -> createChangelog commander, command, cb
    (cb) -> createGitHub commander, command, cb
    (cb) -> initialCommit commander, command, cb
  ], (err) ->
    throw err if err
    console.log "You may now work with the new package.".yellow
    cb()

# ### Create the directory
createDir = (commander, command, cb) ->
  if commander.verbose
    console.log "Check for existing directory #{command.dir}".grey
  return cb() if fs.existsSync command.dir
  console.log "Create directory #{command.dir}"
  fs.mkdirs path.join(command.dir, 'src'), (err) ->
    return cb err if err
    file = path.join command.dir, '.npmignore'
    fs.writeFile file, """
      .project
      .settings
      *.sublime-*
      src
      doc
      """, cb

# ### Create initial git repository
initGit = (commander, command, cb) ->
  if commander.verbose
    console.log "Check for configured git".grey
  if fs.existsSync path.join command.dir, '.git'
    return cb()
  console.log "Init new git repository"
  execFile "git", [ 'init' ], { cwd: command.dir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and commander.verbose
    console.error stderr.trim().magenta if stderr
    file = path.join command.dir, '.gitignore'
    return cb err if err or fs.existsSync file
    fs.writeFile file, """
      .project
      .settings
      *.sublime-*
      /node_modules/
      /doc/
      /lib/
      """, cb

# ### Create new package.json
createPackage = (commander, command, cb) ->
  if commander.verbose
    console.log "Check for existing package.json".grey
  file = path.join command.dir, 'package.json'
  if fs.existsSync file
    return cb()
  console.log "Create new package.json file"
  gitname = path.basename command.dir
  gituser = command.user ? 'alinex'
  pack =
    name: command.package
    version: '0.0.0'
    description: ''
    copyright: PKG.copyright
    keywords: ''
    homepage: "http://#{gituser}.github.io/#{gitname}/"
    repository:
      type: 'git'
      url: "https://github.com/#{gituser}/#{gitname}.git"
    bugs: "https://github.com/#{gituser}/#{gitname}/issues",
    author: PKG.author
    contributors: []
    license: PKG.license
    main: './lib/index.js'
    scripts:
      prepublish: "node_modules/.bin/coffee -c -m -o lib src"
    directories:
      lib: './lib'
    dependencies: {}
    devDependencies:
      "coffee-script": ">=1.7.0"
    optionalDependencies: {}
    engines: PKG.engines
    os: []
  fs.writeFile file, JSON.stringify(pack, null, 2), cb

# ### Create a README.md file
createReadme = (commander, command, cb) ->
  if commander.verbose
    console.log "Check for README.md".grey
  file = path.join command.dir, 'README.md'
  if fs.existsSync file
    return cb()
  console.log "Create new README.md file"
  fs.writeFile file, """
    Package: #{command.package}
    =================================================

    Description comes here...


    License
    -------------------------------------------------

    Copyright #{(new Date()).getFullYear()} Alexander Schilling

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    >  <http://www.apache.org/licenses/LICENSE-2.0>

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    """, cb

# ### Create an initial changelog
createChangelog = (commander, command, cb) ->
  if commander.verbose
    console.log "Check for existing changelog".grey
  file = path.join command.dir, 'Changelog.md'
  if fs.existsSync file
    return cb()
  console.log "Create new changelog file"
  fs.writeFile file, """
    Version changes
    =================================================

    The following list gives a short overview about what is changed between
    individual versions:


    """, cb

# ### Create new GitHub repository if not existing
createGitHub = (commander, command, cb) ->
  unless command.password
    return cb "Can't connect to GitHub API without --password"
  if commander.verbose
    console.log "Check existing GitHub repository".grey
  pack = JSON.parse fs.readFileSync path.join command.dir, 'package.json'
  unless pack.repository.type is 'git'
    return cb "Only git repositories can be added to github."
  gitname = path.basename command.dir
  gituser = command.user ? 'alinex'
  request {
    uri: "https://api.github.com/repos/#{gituser}/#{gitname}"
    auth:
      user: gituser
      pass: command.password
    headers:
      'User-Agent': command.user
  }, (err, response, body) ->
    return cb err if err
    answer = JSON.parse response.body
    unless answer.message?
      return cb()
    unless answer.message is 'Not Found'
      return cb answer.message
    console.log "Create new GitHub repository"
    request {
      uri: "https://api.github.com/user/repos"
      auth:
        user: command.user
        pass: command.password
      headers:
        'User-Agent': command.user
      method: 'POST'
      body: JSON.stringify
        name: gitname
        description: pack.description
        homepage: pack.homepage
        private: false
        has_issues: true
        has_wiki: false
        has_downloads: true
    }, (err, response, body) ->
      return cb err if err
      unless response?.statusCode is 201
        return cb "GitHub status was #{response.statusCode} in try to create repository"
      console.log "Connect with GitHub repository"
      execFile "git", [
        'remote'
        'add', 'origin', pack.repository.url
      ], { cwd: command.dir }, (err, stdout, stderr) ->
        console.log stdout.trim().grey if stdout and commander.verbose
        console.error stderr.trim().magenta if stderr
        cb err

# ### Make initial commit
initialCommit = (commander, command, cb) ->
  if commander.verbose
    console.log "Check if git already used".grey
  execFile "git", [ 'log' ], { cwd: command.dir }, (err, stdout, stderr) ->
    return cb() if stdout.trim()
    console.log "Initial commit"
    execFile "git", [ 'add', '*' ], { cwd: command.dir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and commander.verbose
      console.error stderr.trim().magenta if stderr
      execFile "git", [ 'commit', '-m', 'Initial commit' ], { cwd: command.dir }
      , (err, stdout, stderr) ->
        console.log stdout.trim().grey if stdout and commander.verbose
        console.error stderr.trim().magenta if stderr
        console.log "Push to origin"
        execFile "git", [ 'push', 'origin', 'master' ], { cwd: command.dir }
        , (err, stdout, stderr) ->
          console.log stdout.trim().grey if stdout and commander.verbose
          console.error stderr.trim().magenta if stderr
          cb()
