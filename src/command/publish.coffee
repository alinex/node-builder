# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# include base modules
path = require 'path'
moment = require 'moment'
# include alinex modules
fs = require 'alinex-fs'
async = require 'alinex-async'
# internal mhelper modules
builder = require '../index'


# Setup
# -------------------------------------------------

exports.title = 'publish package in npm'
exports.description = """
Build and publish package to npm.
"""

exports.options =
  major:
    type: 'boolean'
    describe: 'release next major version'
  minor:
    type: 'boolean'
    describe: 'release next minor version'
  version:
    type: 'string'
    describe: 'version to release'
  release:
    type: 'string'
    describe: 'release message'
  try:
    type: 'boolean'
    describe: 'try if publication is possible'
  force:
    type: 'boolean'
    describe: 'force publish also on problems'


# Handler
# ------------------------------------------------

exports.handler = (options, cb) ->
  # step over directories
  builder.dirs options, (dir, options, cb) ->
    builder.task "packageJson", dir, options, (err, pack) ->
      return cb err if err
      if pack.scripts.test?.match /^node_modules\/\.bin\/builder\s+test\s+(-s|--skip-unused)/
        options['skip-unused'] = true
      async.series [
        # precheck
        (cb) -> builder.task 'clean', dir, {verbose: options.verbose, auto: true}, cb
        (cb) -> builder.task 'npmInstall', dir, options, cb
        (cb) ->
          async.parallel [
            (cb) ->
              async.series [
                (cb) -> builder.task 'gitCommitAll', dir, options, cb
                (cb) -> builder.task 'gitPush', dir, options, cb
              ], cb
            (cb) -> builder.task 'lintCoffee', dir, options, cb
            (cb) ->
              async.series [
                (cb) -> builder.task 'testCheck', dir, options, cb
                (cb) -> builder.task 'testMocha', dir, options, (err) -> cb err
              ], cb
            (cb) -> builder.task 'npmChanges', dir, options, cb
          ], (err, results) ->
            return cb err if err
            if resultsJoin(results).trim() and not options.force
              err = new Error "Stopped publish, you may use --force switch"
              return cb err, results
            cb()
        # create
        (cb) -> getVersion dir, options, pack, cb
        (cb) ->
          async.parallel [
            (cb) -> writePackageJson dir, options, pack, cb
            (cb) -> updateChangelog dir, options, cb
          ], cb
        (cb) ->
          builder.task 'gitCommitAll', dir,
            verbose: options.verbose
            message: "Added information for version #{options.version}"
          , cb
        (cb) -> builder.task 'gitPush', dir, options, cb
        # publish
        (cb) ->
          async.parallel [
            (cb) ->
              async.series [
                (cb) -> gitTag dir, options, pack, cb
                (cb) -> builder.task 'gitPush', dir, options, cb
              ], cb
            (cb) -> pushNpm dir, options, cb
            (cb) ->
              async.series [
                (cb) -> builder.task 'docUpdate', dir, options, cb
                (cb) -> builder.task 'docPublish', dir, options, cb
              ], cb
          ], cb
      ], (err, results) ->
        builder.results dir, options, "Results for #{path.basename dir}", results
        cb err
  , cb


# Helper
# ------------------------------------------------------------------

resultsJoin = (res) ->
  return res if typeof res is 'string'
  if Array.isArray res
    res.map (e) -> resultsJoin e
    .join ''
  else
    ''

getVersion = (dir, options, pack, cb) ->
  options.oldVersion = pack.version
  builder.info dir, options, "old version is #{options.oldVersion}"
  if options.version
    return cb new Error "Stopped because of try run" if options.try
    return cb()
  # calculate new version
  version = pack.version.split /\./
  if options.major
    version[0]++
    version[1] = version[2] = 0
  else if options.minor
    version[1]++
    version[2] = 0
  else
    version[2]++
  options.version = version.join '.'
  builder.info dir, options, "new version is #{options.version}"
  return cb new Error "Stopped because of try run" if options.try
  cb()

writePackageJson = (dir, options, pack, cb) ->
  builder.info dir, options, "change package.json"
  file = path.join dir, 'package.json'
  pack.version = options.version
  fs.writeFile file, JSON.stringify(pack, null, 2), cb

# ### add changes since last version to Changelog
updateChangelog = (dir, options, cb) ->
  builder.info dir, options, "update changelog"
  args = ['log', '--pretty=format:%s']
  unless options.oldVersion is '0.0.0'
    args.push "v#{options.oldVersion}..HEAD"
  builder.exec dir, options, "git log",
    cmd: 'git'
    args: args
    cwd: dir
  , (err, proc) ->
    return cb err if err
    file = path.join dir, 'Changelog.md'
    lines = fs.readFileSync(file, 'utf-8').split /\n/
    newlines = proc.stdout().trim().split(/\n/).map (val) -> "- #{val}"
    release = if options.release then "#{options.release}\n\n" else ''
    changelog = lines[..5].join('\n') + """

      Version #{options.version} (#{moment().format('YYYY-MM-DD')})
      -------------------------------------------------
      #{release + newlines.join '\n'}

      """ + lines[5..].join('\n')
    builder.debug dir, options, "write new changelog"
    fs.writeFile file, changelog, cb


# ### Add version tag to git
gitTag = (dir, options, pack, cb) ->
  changelog = ''
  if pack.homepage?
    changelog = " see more in [Changelog.md](#{pack.homepage}/Changelog.md.html)"
  builder.info dir, options, "add new tag"
  builder.exec dir, options, 'git tag',
    cmd: 'git'
    args: [
      'tag'
      '-a', "v#{options.version}"
      '-m', "Created version #{options.version}#{changelog}"
    ]
    cwd: dir
  , cb

# ### Push new version to npm
pushNpm = (dir, options, cb) ->
  builder.info dir, options, 'publish on npm'
  builder.exec dir, options, 'npm publish',
    cmd: 'npm'
    args: ['publish']
    cwd: dir
  , (err) ->
    cb err, "Created version #{options.version}"
