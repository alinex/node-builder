# Create new node module
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
debug = require('debug')('make:create')
async = require 'async'
fs = require 'alinex-fs'
path = require 'path'
chalk = require 'chalk'
{execFile} = require 'child_process'
request = require 'request'
prompt = require 'prompt'

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
  prompt.start()
  async.series [
    (cb) -> createDir dir, options, cb
    (cb) -> initGit dir, options, cb
    (cb) -> createGitHub dir, options, cb
    (cb) -> createPackage dir, options, cb
    (cb) -> createTravis dir, options, cb
    (cb) -> createReadme dir, options, cb
    (cb) -> createChangelog dir, options, cb
    (cb) -> initialCommit dir, options, cb
  ], (err) ->
    throw err if err
    console.log chalk.yellow "You may now work with the new package."
    cb()

# ### Create the directory
createDir = (dir, options, cb) ->
  # check if directory already exist
  if fs.existsSync dir
    if options.verbose
      console.log chalk.grey "Directory #{dir} already exists."
    return cb()
  # create directory
  console.log "Create directory #{dir}"
  fs.mkdirs path.join(dir, 'src'), (err) ->
    return cb err if err
    fs.mkdirs path.join(dir, 'test'), (err) ->
      return cb err if err
      # create .npmignore file
      file = path.join dir, '.npmignore'
      fs.copy path.join(GLOBAL.ROOT_DIR, '.npmignore'), file, cb

# ### Create initial git repository
# It will set the `options.git` variable to the local uri
initGit = (dir, options, cb) ->
  # check for existing git repository
  if options.verbose
    console.log chalk.grey "Check for configured git"
  if fs.existsSync path.join dir, '.git'
    options.git = 'file://' + fs.realpathSync dir
    return cb()
  # create a new repository
  prompt.get
    message: "Should a git repository be initialized?"
    validator: /y[es]*|n[o]?/,
    warning: 'You must respond with yes or no',
    default: 'yes'
  , (err, input) ->
    return cb err if err or input.question isnt 'yes'
    console.log "Init new git repository"
    debug "exec #{dir}> git init"
    execFile "git", [ 'init' ], { cwd: dir }, (err, stdout, stderr) ->
      console.log chalk.grey stdout.trim() if stdout and options.verbose
      console.error chalk.magenta stderr.trim() if stderr
      file = path.join dir, '.gitignore'
      return cb err if err or fs.existsSync file
      options.git = 'file://' + fs.realpathSync dir
      fs.copy path.join(GLOBAL.ROOT_DIR, '.gitignore'), file, cb

# ### Create new GitHub repository if not existing
# It will set the `options.github` variable
createGitHub = (dir, options, cb) ->
  return cb() if options.private
  # check for existing package with github url
  if options.verbose
    console.log chalk.grey "Check for configured git"
  file = path.join dir, 'package.json'
  if fs.existsSync file
    pack = JSON.parse fs.readFileSync file
    unless pack.repository.type is 'git'
      console.out chalk.yellow "Only git repositories can be added to github."
      return cb()
    console.log pack.repository.url
    console.log ~pack.repository.url.indexOf 'github.com/'
    if ~pack.repository.url.indexOf 'github.com/'
      options.github = pack.repository.url
      return cb()
  # check for other remote origin
  debug "exec #{dir}> git remote show origin"
  execFile "git", [ 'remote', 'show', 'origin' ], { cwd: dir }, (err, stdout, stderr) ->
    unless err
      console.log chalk.grey stdout.trim() if stdout and options.verbose
      console.log "Skipped GitHub because other origin exists already"
      return cb()
    # create github repository
    prompt.get
      message: "Should a github repository be initialized?"
      validator: /y[es]*|n[o]?/,
      warning: 'You must respond with yes or no',
      default: 'yes'
    , (err, input) ->
      console.log input
      return cb err if err or input.question isnt 'yes'
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
        gitname = path.basename dir
        options.github = "https://github.com/#{input.username}/#{gitname}"
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
          debug "POST https://api.github.com/user/repos"
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
            debug "exec #{dir}> git remote add origin #{options.github}"
            execFile "git", [
              'remote'
              'add', 'origin', options.github
            ], { cwd: dir }, (err, stdout, stderr) ->
              console.log chalk.grey stdout.trim() if stdout and options.verbose
              console.error chalk.magenta stderr.trim() if stderr
              cb err

# ### Create new package.json
createPackage = (dir, options, cb) ->
  # check if package.json exists
  if options.verbose
    console.log chalk.grey "Check for existing package.json"
  file = path.join dir, 'package.json'
  if fs.existsSync file
    console.log chalk.yellow "Skipped package.json creation, because already exists"
    return cb()
  console.log "Create new package.json file"
  gitname = path.basename dir
  gituser = path.basename path.dirname options.github
  pack =
    name: options.package
    version: '0.0.0'
    description: ''
    copyright: "#{PKG.author?.name ? ''} #{(new Date()).getFullYear()}"
    private: options.private ? false
    keywords: []
    homepage: if options.github then "http://#{gituser}.github.io/#{gitname}/" else ""
    repository:
      type: 'git'
      url: options.github ? options.git
    bugs: if options.github then "#{options.github}/issues" else ""
    author: PKG.author
    contributors: []
    license: PKG.license
    main: './lib/index.js'
    scripts:
      prepublish: "node_modules/.bin/builder -c compile"
      test: "node_modules/.bin/builder -c test"
    directories:
      lib: './lib'
    dependencies: {}
    devDependencies:
      "alinex-builder": "1.x"
      "chai": "2.x"
    optionalDependencies: {}
    engines: PKG.engines
    os: []
  fs.writeFile file, JSON.stringify(pack, null, 2), cb

# ### Create a README.md file
createReadme = (dir, options, cb) ->
  if options.verbose
    console.log chalk.grey "Check for README.md"
  file = path.join dir, 'README.md'
  if fs.existsSync file
    return cb()
  console.log "Create new README.md file"
  gitname = path.basename dir
  gituser = path.basename path.dirname options.github
  doc =
    badges: ''
    install: ''
  if options.github
    doc.badges = "\n[![Build Status]
    (https://travis-ci.org/#{gituser}/#{gitname}.svg?branch=master)]\
    (https://travis-ci.org/#{gituser}/#{gitname})
    \n[![Coverage Status]
    (https://coveralls.io/repos/#{gituser}/#{gitname}/badge.png?branch=master)]\
    (https://coveralls.io/r/#{gituser}/#{gitname}?branch=master)"
  unless options.private
    doc.badges += "\n[![Dependency Status]
    (https://gemnasium.com/#{gituser}/#{gitname}.png)]\
    (https://gemnasium.com/#{gituser}/#{gitname})"
    doc.install = "\n\
    [![NPM](https://nodei.co/npm/#{options.package}.png?downloads=true&stars=true)]\
    (https://nodei.co/npm/#{options.package}/)"

  fs.writeFile file, """
    Package: #{options.package}
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
createChangelog = (dir, options, cb) ->
  if options.verbose
    console.log chalk.grey "Check for existing changelog"
  file = path.join dir, 'Changelog.md'
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
createTravis = (dir, options, cb) ->
  unless options.github
    return cb()
  if options.verbose
    console.log chalk.grey "Check for existing travis configuration"
  file = path.join dir, '.travis.yml'
  if fs.existsSync file
    return cb()
  gituser = path.basename path.dirname options.github
  console.log "Create new travis-ci configuration"
  console.log chalk.yellow.bold "Log into https://travis-ci.org/profile/#{gituser}
    and activate Travis CI"
  console.log chalk.yellow.bold "Log into https://coveralls.io/repos/new?name=#{gituser}
    and activate coveralls"
  console.log chalk.yellow.bold "Log into https://gemnasium.com/projects/new_from_github
    and activate dependency checks"
  coveralls = "
    COVERALLS_SERVICE_NAME=travis-ci
    COVERALLS_REPO_TOKEN=haQKkRgwLHbwX1dp8ltFXFTPO48c5EEWo
    node_modules/.bin/alinex-make test -c --coveralls"
  fs.writeFile file, """
    language: node_js
    node_js:
       - "0.10"
       - "0.11"
       - "0.12"
       - "io.js"
    after_success:
       - #{coveralls}
    """, cb

# ### Make initial commit
initialCommit = (dir, options, cb) ->
  if options.verbose
    console.log chalk.grey "Check if git already used"
  debug "exec #{dir}> git log"
  execFile "git", [ 'log' ], { cwd: dir }, (err, stdout, stderr) ->
    return cb() if stdout.trim()
    console.log "Initial commit"
    debug "exec #{dir}> git add *"
    execFile "git", [ 'add', '*' ], { cwd: dir }, (err, stdout, stderr) ->
      console.log chalk.grey stdout.trim() if stdout and options.verbose
      console.error chalk.magenta stderr.trim() if stderr
      debug "exec #{dir}> git commit -m \"Initial commit\""
      execFile "git", [ 'commit', '-m', 'Initial commit' ]
      , { cwd: dir }, (err, stdout, stderr) ->
        console.log chalk.grey stdout.trim() if stdout and options.verbose
        console.error chalk.magenta stderr.trim() if stderr
        console.log "Push to origin"
        debug "exec #{dir}> git push origin master"
        execFile "git", [ 'push', 'origin', 'master' ],
        { cwd: dir }, (err, stdout, stderr) ->
          console.log chalk.grey stdout.trim() if stdout and options.verbose
          console.error chalk.magenta stderr.trim() if stderr
          cb()
