# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# include base modules
chalk = require 'chalk'
path = require 'path'
inquirer = require 'inquirer'
request = require 'request'
async = require 'async'
# include alinex modules
fs = require 'alinex-fs'
util = require 'alinex-util'
# internal mhelper modules
builder = require '../index'


# Setup
# -------------------------------------------------

exports.title = 'create a new package (interactive)'
exports.description = """
This command will create a new package and will therefore ask you some questions
interactively to do this.
"""

# Handler
# ------------------------------------------------

exports.handler = (options, cb) ->
  # step over directories
  dir = path.resolve options._[1]
  unless dir
    err = new Error "Missing directory to create"
    err.exit = 2
    return cb err
  builder.info dir, options, "started on #{dir}"
  ask dir, options, (err, data) ->
    return cb err if err
    util.extend options, data
    options.message = "Initial setup of new project"
    async.series [
      (cb) -> createDir dir, options, cb
      (cb) -> initGit dir, options, cb
      (cb) -> createNodePackage dir, options, cb
      (cb) -> updatePackageJson dir, options, cb
      (cb) -> initGitHub dir, options, cb
      (cb) -> builder.task 'gitCommitAll', dir, options, cb
      (cb) -> builder.task 'gitPush', dir, options, cb
    ], (err, results) ->
      builder.results dir, options, "Results for #{path.basename dir}", results
      builder.info dir, options, 'done'
      cb err

# Helper
# ------------------------------------------------

ask = (dir, options, cb) ->
  builder.info dir, options, "get information"
  # check system
  async.parallel
    hasDir: (cb) -> fs.exists dir, (exists) -> cb null, exists
    hasGit: (cb) -> fs.exists "#{dir}/.git", (exists) -> cb null, exists
    hasPack: (cb) -> fs.exists "#{dir}/package.json", (exists) -> cb null, exists
    pack: (cb) -> builder.task 'packageJson', dir, options, (err, pack) -> cb null, pack
  , (err, system) ->
    return cb err if err
    system.pack ?= {}
    # ask what to do
    builder.debug dir, options, "ask interactive"
    console.log()
    inquirer.prompt [
      type: 'input'
      name: 'name'
      message: "Give a package name like alinex-...:"
      when: -> not system.pack.name
    ,
      type: 'input'
      name: 'description'
      message: "Give a short description:"
      when: -> not system.pack.description
    ,
      type: 'confirm'
      name: 'private'
      message: "Should this be kept private?"
      default: false
      when: -> not system.pack.private?
    ,
      type: 'confirm'
      name: 'initGit'
      message: "Should a git repository be initialized?"
      when: -> not system.hasGit
    ,
      type: 'confirm'
      name: 'initGithub'
      message: "Should a github repository be used?"
      when: (answer) -> answer.initGit and not (system.pack.private or answer.private)
    ,
      type: 'input'
      name: 'user'
      message: "Your github username:"
      default: 'alinex'
      when: (answer) -> answer.initGithub
    ,
      type: 'password'
      name: 'password'
      message: "Your password for github:"
      when: (answer) -> answer.initGithub
    ]
    .then (answer) ->
      answer.pack =
        name: answer.name
      delete answer.name
      console.log()
      cb null, util.extend system, answer

# add bottombar

createDir = (dir, options, cb) ->
  return cb() if options.hasDir
  builder.info dir, options, "create folder if neccessary"
  fs.mkdirs dir, (err) -> cb err

# ### Create initial git repository
# It will set the `options.git` variable to the local uri
initGit = (dir, options, cb) ->
  return cb() unless options.initGit
  builder.info dir, options, "initialize git"
  builder.exec dir, options, "git init",
    cmd: 'git'
    args: ['init']
    cwd: dir
  , (err) ->
    return cb err if err
    async.filter [
      path.resolve __dirname, '../../var/src/template/git'
      path.resolve __dirname, '../../var/local/template/git'
    ], (file, cb) ->
      fs.exists file, (exists) -> cb null, exists
    , (err, files) ->
      return cb err if err
      return cb() unless files.length
      async.each files, (file, cb) ->
        builder.debug dir, options, "copy template from #{file}"
        fs.copy file, path.join(dir),
          overwrite: true
        , cb
      , cb
    , cb

createNodePackage = (dir, options, cb) ->
  return cb() if options.hasPack
  builder.info dir, options, "create node package"
  async.filter [
    path.resolve __dirname, '../../var/src/template/node'
    path.resolve __dirname, '../../var/local/template/node'
  ], (file, cb) ->
    fs.exists file, (exists) -> cb null, exists
  , (err, files) ->
    return cb err if err
    return cb() unless files.length
    async.each files, (file, cb) ->
      builder.debug dir, options, "copy template from #{file}"
      fs.copy file, path.join(dir),
        overwrite: true
      , cb
    , (err) ->
      return cb err if err
      fs.find dir,
        type: 'file'
        exclude: '**/.git/**'
      , (err, list) ->
        return cb err if err
        async.each list, (file, cb) ->
          # read, replace
          builder.noisy dir, options, "replace variables in #{file}"
          fs.readFile file, 'utf8', (err, content) ->
            content = content.replace /###<year>###/g, (new Date()).getFullYear()
            content = content.replace /###<pack>###/g, options.pack.name
            content = content.replace /###<user>###/g, options.user
            content = content.replace /###<username>###/g, options.username
            content = content.replace /###<dirname>###/g, path.basename dir
            content = content.replace /###<title>###/g,
            options.pack.name.split(/-/).map((e) -> util.string.ucFirst e). join ' '
            fs.writeFile file, content, 'utf8', cb
        , cb

updatePackageJson = (dir, options, cb) ->
  return cb() if options.hasPack
  builder.info dir, options, "update package.json"
  return cb()
  setup =
    description: options.description
    copyright: "#{options.user} #{(new Date()).getFullYear()}"
  setup.private = options.private if options.private?
  setup.homepage = "http://#{options.user}.github.io/#{path.basename dir}/" if options.initGithub
  setup.repository = {}
  if options.hasGit or options.initGit
    setup.repository.type = 'git'
    setup.repository.url = if options.initGithub
      "https://github.com/#{options.user}/#{path.basename dir}"
    else
      "file://#{dir}"
    if options.initGithub
      setup.bugs = "https://#{options.user}.github.io/#{path.basename dir}/issues"
  util.extend options.pack, setup
  cb()

# ### Create new GitHub repository if not existing
# It will set the `options.github` variable
initGitHub = (dir, options, cb) ->
  return cb() unless options.initGithub
  builder.info dir, options, "initialize github"
  builder.exec dir, options, "git remote",
    cmd: 'git'
    args: ['remote', 'show', 'origin']
    cwd: dir
  , (err) ->
    unless err
      console.warn chalk.magenta "Skipped GitHub because other origin exists already"
      return cb()
    builder.debug dir, options, "check github repository"
    builder.noisy dir, options, "GET https://api.github.com/user/repos"
    request {
      uri: "https://api.github.com/repos/#{options.user}/#{path.basename dir}"
      auth:
        user: options.user
        pass: options.password
      headers:
        'User-Agent': options.user
    }, (err, response) ->
      return cb err if err
      answer = JSON.parse response.body
      unless answer.message?
        return cb new Error 'No response from github'
      unless answer.message is 'Not Found'
        return cb new Error answer.message
      builder.debug dir, options, "create github repository"
      builder.noisy dir, options, "POST https://api.github.com/user/repos"
      request {
        uri: "https://api.github.com/user/repos"
        auth:
          user: options.user
          pass: options.password
        headers:
          'User-Agent': options.user
        method: 'POST'
        body: JSON.stringify
          name: path.basename dir
          description: options.description
          homepage: "http://#{options.user}.github.io/#{path.basename dir}"
          private: false
          has_issues: true
          has_wiki: false
          has_downloads: true
      }, (err, response) ->
        return cb err if err
        unless response?.statusCode is 201
          return cb new Error "GitHub status was #{response.statusCode} in try
          to create repository"
        builder.debug dir, options, "set github as origin"
        builder.exec dir, options, 'git remote add',
          cmd: 'git'
          args: [
            'remote', 'add'
            'origin', "https://github.com/#{options.user}/#{path.basename dir}"
          ]
          cwd: dir
        , cb
