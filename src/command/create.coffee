# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# include base modules
chalk = require 'chalk'
path = require 'path'
inquirer = require 'inquirer'
# include alinex modules
async = require 'alinex-async'
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
  ask dir, options, (err, answer) ->
    return cb err if err
    console.log answer
    console.log 'lllllllllllllllllll'
    async.series [
      (cb) -> createDir dir, options, cb
#      (cb) -> initGit dir, options, cb
#      (cb) -> createNodePackage dir, options, cb
#      (cb) -> initGitHub dir, options, cb
  #    (cb) -> createTravis dir, options, cb
  #    (cb) -> createReadme dir, options, cb
  #    (cb) -> createChangelog dir, options, cb
  #    (cb) -> initialCommit dir, options, cb
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
      type: 'confirm'
      name: 'initGit'
      message: "Should a git repository be initialized?"
      when: -> not system.hasGit
    ,
      type: 'confirm'
      name: 'github'
      message: "Should a github repository be used?"
      when: (answer) -> answer.initGit
    ]
    .then (answer) ->
      console.log()
      console.log '-----'
      cb null, util.extend system, answer

# add bottombar

createDir = (dir, options, cb) ->
  builder.info dir, options, "create folder if neccessary"
  fs.mkdirs dir, (err) -> cb err

# ### Create initial git repository
# It will set the `options.git` variable to the local uri
initGit = (dir, options, cb) ->
  fs.exists "#{dir}/.git", (exists) ->
    if exists
      data.git = true
      return cb()
    console.log()
    inquirer.prompt [
      type: 'confirm'
      name: 'git'
      message: "Should a git repository be initialized?"
    ]
    .then (answer) ->
      util.extend data, answer
      console.log()
      return cb() unless answer.git
      builder.exec dir, options, "init git",
        cmd: 'git'
        args: ['init']
        cwd: dir
      , (err) ->
        return cb err if err
        async.filter [
          path.resolve __dirname, '../../var/src/template/git'
          path.resolve __dirname, '../../var/local/template/git'
        ], fs.exists, (files) ->
          return cb() unless files.length
          async.each files, (file, cb) ->
            builder.debug dir, options, "copy template from #{file}"
            fs.copy file, path.join(dir),
              overwrite: true
            , cb
          , cb
        , cb

# ### Create new package.json
createNodePackage = (dir, options, cb) ->
  fs.exists "#{dir}/package.json", (exists) ->
    if exists
      builder.task 'packageJson', dir, options, (err, pack) ->
        data.pack = pack
        return cb err
    builder.debug dir, options, "create node package"


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
        prepublish: "node_modules/.bin/builder -c compile --uglify"
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

test = ->
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
      prepublish: "node_modules/.bin/builder -c compile --uglify"
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



# ### Create new GitHub repository if not existing
# It will set the `options.github` variable
initGitHub = (dir, options, cb) ->
  return cb() unless data.git
  console.log()
  inquirer.prompt [
    type: 'confirm'
    name: 'git'
    message: "Should a git repository be initialized?"
  ]

  return cb() if options.private
  # check for existing package with github url
  if options.verbose
    console.log chalk.grey "Check for configured git"
  file = path.join dir, 'package.json'
  if fs.existsSync file
    try
      pack = JSON.parse fs.readFileSync file
    catch error
      return cb new Error "Could not load #{file} as valid JSON: #{error.message}"
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
  execFile "git", ['remote', 'show', 'origin'], {cwd: dir}, (err, stdout) ->
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
        }, (err, response) ->
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
          }, (err, response) ->
            return cb err if err
            unless response?.statusCode is 201
              return cb "GitHub status was #{response.statusCode} in try to create repository"
            console.log "Connect with GitHub repository"
            debug "exec #{dir}> git remote add origin #{options.github}"
            execFile "git", [
              'remote'
              'add', 'origin', options.github
            ], {cwd: dir}, (err, stdout, stderr) ->
              console.log chalk.grey stdout.trim() if stdout and options.verbose
              console.error chalk.magenta stderr.trim() if stderr
              cb err
