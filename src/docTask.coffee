# Create API documentation
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
async = require 'async'
fs = require 'fs-extra'
path = require 'path'
colors = require 'colors'
{execFile} = require 'child_process'
os = require 'os'
crypto = require 'crypto'

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
  createDoc commander, command, (err) ->
    return cb err if err or not command.publish
    async.series [
      (cb) -> createTmpDir commander, command, cb
      (cb) -> cloneGit commander, command, cb
      (cb) -> checkoutPages commander, command, cb
      (cb) -> updateDoc commander, command, cb
      (cb) -> pushOrigin commander, command, cb
    ], (err) ->
      throw err if err
      fs.remove command.tmpdir, cb

# ### Create initial git repository
createDoc = (commander, command, cb) ->
  if fs.existsSync path.join(command.dir, 'doc')
    if commander.verbose
      console.log "Remove old documentation".grey
    fs.removeSync path.join(command.dir, 'doc'), (err) ->
  console.log "Create html documentation"
  docker = path.join GLOBAL.ROOT_DIR, "node_modules/.bin/docker"
  unless fs.existsSync docker
    return cb "Missing docker installation in #{docker}."
  execFile docker, [
    '-i', command.dir
    '-u'
    if command.watch then '-w' else ''
    '-x', '.git,bin,doc,node_modules,test,lib,public,view,log,config,*/angular'
    '-o', path.join command.dir, 'doc'
    '-c', 'autumn'
    '--extras', 'fileSearch,goToLine'
  ], (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and commander.verbose
    console.error stderr.trim().magenta if stderr
    return cb err if err
    # create index.html
    fs.writeFile path.join(command.dir, 'doc', 'index.html'), """
      <html>
      <head>
        <meta http-equiv="refresh" content="0; url=README.md.html" />
        <script type="text/javascript">
            window.location.href = "README.md.html"
        </script>
        <title>Page Redirection</title>
      </head>
      <body>
        If you are not redirected automatically, follow the link to the <a href='README.md.html'>README</a>.
      </body>
      </html>
      """, cb

# ### Create temporary directory
createTmpDir = (commander, command, cb) ->
  filename = 'alinex-make-' + crypto.randomBytes(4).readUInt32LE(0) + '-gh';
  command.tmpdir = path.join os.tmpdir(), filename
  if commander.verbose
    console.log "Create temporary directory at #{command.tmpdir}".grey
  fs.mkdirs command.tmpdir, cb

# ### Clone git repository
cloneGit = (commander, command, cb) ->
  file = path.join command.dir, 'package.json'
  pack = JSON.parse fs.readFileSync file  
  console.log "Cloning git repository"
  execFile 'git', [
    'clone'
    pack.repository.url
    command.tmpdir
  ], (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and commander.verbose
    console.error stderr.trim().magenta if stderr
    cb err

# ### Checkout gh-pages branch
checkoutPages = (commander, command, cb) ->
  console.log "Checkout gh-pages branch"
  execFile 'git', [ 
    'checkout', 'gh-pages' 
  ], { cwd: command.tmpdir }, (err, stdout, stderr) ->    
    console.log stdout.trim().grey if stdout and commander.verbose
    console.error stderr.trim().magenta if stderr
    return cb() unless err 
    execFile 'git', [
      'checkout'
      '--orphan'
      'gh-pages'
    ], { cwd: command.tmpdir }, (err, stdout, stderr) ->    
      console.log stdout.trim().grey if stdout and commander.verbose
      console.error stderr.trim().magenta if stderr
      cb err

# ### Update the documentation
updateDoc = (commander, command, cb) ->
  console.log "Update documentation"
  if commander.verbose
    console.log "Remove old documentation".grey
  execFile 'git', [ 
    'rm', '-rf', '.' 
  ], { cwd: command.tmpdir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and commander.verbose
    console.error stderr.trim().magenta if stderr
    if commander.verbose
      console.log "Copy new documentation into repository".grey
    fs.copy path.join(command.dir, 'doc'), command.tmpdir, (err) ->
      return cb err if err
      if commander.verbose
        console.log "Add files to git".grey
      execFile 'git', [ 
        'add', '*' 
      ], { cwd: command.tmpdir }, (err, stdout, stderr) ->
        console.log stdout.trim().grey if stdout and commander.verbose
        console.error stderr.trim().magenta if stderr
        return cb err if err
        if commander.verbose
          console.log "Commit changes".grey
        execFile 'git', [ 
          'commit'
          '-m', "Updated documentation"
        ], { cwd: command.tmpdir }, (err, stdout, stderr) ->
          console.log stdout.trim().grey if stdout and commander.verbose
          console.error stderr.trim().magenta if stderr
          cb err

# ### Push to git origin
pushOrigin = (commander, command, cb) ->
  console.log "Push to git origin"
  execFile "git", [
    'push'
    'origin', 'gh-pages'
  ], { cwd: command.tmpdir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and commander.verbose
    console.error stderr.trim().magenta if stderr
    return cb err if err
    cb()

