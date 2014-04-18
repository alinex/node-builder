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
prompt = require 'prompt'

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
  prompt.start()
  async.series [
    (cb) -> createDir command, cb
    (cb) -> initGit command, cb
    (cb) -> createGitHub command, cb
    (cb) -> createPackage command, cb
    (cb) -> createTravis command, cb
    (cb) -> createReadme command, cb
    (cb) -> createChangelog command, cb
    (cb) -> initialCommit command, cb
  ], (err) ->
    throw err if err
    console.log "You may now work with the new package.".yellow
    cb()

# ### Create the directory
createDir = (command, cb) ->
  # check if directory already exist
  if fs.existsSync command.dir
    if command.verbose
      console.log "Directory #{command.dir} already exists.".grey
    return cb()
  # create directory
  console.log "Create directory #{command.dir}"
  fs.mkdirs path.join(command.dir, 'src'), (err) ->
    return cb err if err
    fs.mkdirs path.join(command.dir, 'test'), (err) ->
      return cb err if err
      # create .npmignore file
      file = path.join command.dir, '.npmignore'
      fs.copy path.join(GLOBAL.ROOT_DIR, '.npmignore'), file, cb

# ### Create initial git repository
# It will set the `command.git` variable to the local uri
initGit = (command, cb) ->
  # check for existing git repository
  if command.verbose
    console.log "Check for configured git".grey
  if fs.existsSync path.join command.dir, '.git'
    command.git = 'file://' + fs.realpathSync command.dir
    return cb()
  # create a new repository
  prompt.get
    message: "Should a git repository be initialized?"
    validator: /y[es]*|n[o]?/,
    warning: 'You must respond with yes or no',
    default: 'yes'
  , (err, input) ->
    return cb err if err or not input.question is 'yes'
    console.log "Init new git repository"
    execFile "git", [ 'init' ], { cwd: command.dir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and command.verbose
      console.error stderr.trim().magenta if stderr
      file = path.join command.dir, '.gitignore'
      return cb err if err or fs.existsSync file
      command.git = 'file://' + fs.realpathSync command.dir
      fs.copy path.join(GLOBAL.ROOT_DIR, '.gitignore'), file, cb

# ### Create new GitHub repository if not existing
# It will set the `command.github` variable
createGitHub = (command, cb) ->
  return cb() if command.private
  # check for existing package with github url
  if command.verbose
    console.log "Check for configured git".grey
  file = path.join command.dir, 'package.json'
  if fs.existsSync file
    pack = JSON.parse fs.readFileSync file
    unless pack.repository.type is 'git'
      console.out "Only git repositories can be added to github.".yellow
      return cb()
    console.log pack.repository.url
    console.log ~pack.repository.url.indexOf 'github.com/'
    if ~pack.repository.url.indexOf 'github.com/'
      command.github = pack.repository.url
      return cb()
  # check for other remote origin
  execFile "git", [ 'remote', 'show', 'origin' ], { cwd: command.dir }, (err, stdout, stderr) ->
    unless err
      console.log stdout.trim().grey if stdout and command.verbose
      console.log "Skipped GitHub because other origin exists already"
      return cb()
    # create github repository
    prompt.get
      message: "Should a github repository be initialized?"
      validator: /y[es]*|n[o]?/,
      warning: 'You must respond with yes or no',
      default: 'yes'
    , (err, input) ->
      return cb err if err or not input.question is 'yes'
      console.log "Init new git repository"
      prompt.get [{
        message: "GitHub username:"
        name: 'username'
        required: true
        default: 'alinex'
      }, {
        message: "Password for GitHub login:"
        name: 'password'
        hidden: true
        required: true
      }, {
        message: "Give a short description of this module."
        name: 'description'
        required: true
      }], (err, input) ->
        gitname = path.basename command.dir
        command.github = "https://github.com/#{input.username}/#{gitname}"
        request {
          uri: "https://api.github.com/repos/#{input.username}/#{gitname}"
          auth:
            user: input.username
            pass: input.password
          headers:
            'User-Agent': input.username
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
              user: input.username
              pass: input.password
            headers:
              'User-Agent': input.username
            method: 'POST'
            body: JSON.stringify
              name: gitname
              description: input.description
              homepage: "http://#{input.username}.github.io/#{gitname}"
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
              'add', 'origin', command.github
            ], { cwd: command.dir }, (err, stdout, stderr) ->
              console.log stdout.trim().grey if stdout and command.verbose
              console.error stderr.trim().magenta if stderr
              cb err

# ### Create new package.json
createPackage = (command, cb) ->
  # check if package.json exists
  if command.verbose
    console.log "Check for existing package.json".grey
  file = path.join command.dir, 'package.json'
  if fs.existsSync file
    console.log "Skipped package.json creation, because already exists".yellow
    return cb()
  console.log "Create new package.json file"
  gitname = path.basename command.dir
  gituser = path.basename path.dirname command.github
  pack =
    name: command.package
    version: '0.0.0'
    description: ''
    copyright: "#{PKG.author?.name ? ''} #{(new Date()).getFullYear()}"
    private: command.private ? false
    keywords: ''
    homepage: if command.github then "http://#{gituser}.github.io/#{gitname}/" else ""
    repository:
      type: 'git'
      url: command.github ? command.git
    bugs: if command.github then "#{command.github}/issues" else ""
    author: PKG.author
    contributors: []
    license: PKG.license
    main: './lib/index.js'
    scripts:
      prepublish: "node_modules/.bin/alinex-make compile"
      test: "node_modules/.bin/alinex-make test"
    directories:
      lib: './lib'
    dependencies: {}
    devDependencies:
      "alinex-make": "0.2.x"
    optionalDependencies: {}
    engines: PKG.engines
    os: []
  pack.devDependencies.coveralls = "2.x" if command.github
  fs.writeFile file, JSON.stringify(pack, null, 2), cb

# ### Create a README.md file
createReadme = (command, cb) ->
  if command.verbose
    console.log "Check for README.md".grey
  file = path.join command.dir, 'README.md'
  if fs.existsSync file
    return cb()
  console.log "Create new README.md file"
  gitname = path.basename command.dir
  gituser = path.basename path.dirname command.github
  doc =
    badges: ''
    install: ''
  if command.github
    doc.badges = "\n[![Build Status]
    (https://travis-ci.org/#{gituser}/#{gitname}.svg?branch=master)]\
    (https://travis-ci.org/#{gituser}/#{gitname})
    \n[![Coverage Status]
    (https://coveralls.io/repos/#{gituser}/#{gitname}/badge.png?branch=master)]\
    (https://coveralls.io/r/#{gituser}/#{gitname}?branch=master)"
  unless command.private
    doc.badges += "\n[![Dependency Status]
    (https://gemnasium.com/#{gituser}/#{gitname}.png)]\
    (https://gemnasium.com/#{gituser}/#{gitname})"
    doc.install = "\n\
    [![NPM](https://nodei.co/npm/#{command.package}.png?downloads=true&stars=true)]\
    (https://nodei.co/npm/#{command.package}/)"

  fs.writeFile file, """
    Package: #{command.package}
    =================================================
    #{doc.badges}

    Description comes here...


    Install
    -------------------------------------------------
    #{doc.install}


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
createChangelog = (command, cb) ->
  if command.verbose
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

# ### Create a travis configuration file
createTravis = (command, cb) ->
  unless command.github
    return cb()
  if command.verbose
    console.log "Check for existing travis configuration".grey
  file = path.join command.dir, '.travis.yml'
  if fs.existsSync file
    return cb()
  gituser = path.basename path.dirname command.github
  console.log "Create new travis-ci configuration"
  console.log "Log into https://travis-ci.org/profile/#{gituser}
    and activate Travis CI".yellow.bold
  console.log "Log into https://coveralls.io/repos/new?name=#{gituser}
    and activate coveralls".yellow.bold
  console.log "Log into https://gemnasium.com/projects/new_from_github
    and activate dependency checks".yellow.bold
  coveralls = "
    COVERALLS_SERVICE_NAME=travis-ci
    COVERALLS_REPO_TOKEN=haQKkRgwLHbwX1dp8ltFXFTPO48c5EEWo
    node_modules/.bin/alinex-make test -c --coveralls"
  fs.writeFile file, """
    language: node_js
    node_js:
       - "0.11"
       - "0.10"
    after_success:
       - #{coveralls}
    """, cb

# ### Make initial commit
initialCommit = (command, cb) ->
  if command.verbose
    console.log "Check if git already used".grey
  execFile "git", [ 'log' ], { cwd: command.dir }, (err, stdout, stderr) ->
    return cb() if stdout.trim()
    console.log "Initial commit"
    execFile "git", [ 'add', '*' ], { cwd: command.dir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and command.verbose
      console.error stderr.trim().magenta if stderr
      execFile "git", [ 'commit', '-m', 'Initial commit' ]
      , { cwd: command.dir }, (err, stdout, stderr) ->
        console.log stdout.trim().grey if stdout and command.verbose
        console.error stderr.trim().magenta if stderr
        console.log "Push to origin"
        execFile "git", [ 'push', 'origin', 'master' ],
        { cwd: command.dir }, (err, stdout, stderr) ->
          console.log stdout.trim().grey if stdout and command.verbose
          console.error stderr.trim().magenta if stderr
          cb()
