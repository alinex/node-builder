# Create API documentation
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
async = require 'async'
fs = require 'fs-extra'
path = require 'path'
colors = require 'colors'
{exec, execFile, spawn} = require 'child_process'
os = require 'os'
crypto = require 'crypto'

tools = require './tools'

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
#
# This task will create the documentation and publish it if switch `--publish`
# is set. The publication can be done to github pages or using the `doc-publish`
# script if defined.
module.exports.run = (command, cb) ->
  url = path.join command.dir, 'doc', 'index.html'
  if command.watch and command.browser
    setTimeout ->
      openUrl command, url
    , 5000
  # Create the html documentation out of source files
  createDoc command, (err) ->
    return cb err if err
    # Check for specific doc style
    pack = JSON.parse fs.readFileSync path.join command.dir, 'package.json'
    file = path.join GLOBAL.ROOT_DIR, 'var/local/docstyle', (pack.name.split /-/)[0] + '.css'
    unless fs.existsSync file
      file = path.join GLOBAL.ROOT_DIR, 'var/src/docstyle', (pack.name.split /-/)[0] + '.css'
    # Use specific doc style
    if fs.existsSync file
      fs.copySync file, path.join(command.dir, 'doc', 'doc-style.css')
    # Check if --publish flag is set
    unless command.publish
      return openUrl command, url, cb if command.browser
      cb()
    # Publish  using script from package.json
    if pack.scripts?['doc-publish']?
      console.log pack.scripts['doc-publish']
      exec pack.scripts['doc-publish'], { cwd: command.dir }, (err, stdout, stderr) ->
        if command.verbose
          console.log stdout.toString().trim().grey if stdout
        console.log stderr.toString().trim().magenta if stderr
        return cb err if err
        return openUrl command, url, cb if command.browser
        return cb()
    # Or publish to GitHub
    else if ~pack.repository?.url?.indexOf 'github.com/'
      async.series [
        (cb) -> createTmpDir command, cb
        (cb) -> cloneGit command, cb
        (cb) -> checkoutPages command, cb
        (cb) -> updateDoc command, cb
        (cb) -> pushOrigin command, cb
      ], (err) ->
        throw err if err
        fs.remove command.tmpdir, (err) ->
          return openUrl command, url, cb if command.browser
          return cb()
    # Publication was not possible
    else
      console.error "Could not publish, specify doc-publish script in package.json".magenta
      return openUrl command, url, cb if command.browser
      return cb()

# ### Open the given url in the default browser
openUrl = (command, target, cb) ->
  if command.verbose
    console.log "Open #{target} in browser".grey
  opener = switch process.platform
    when 'darwin' then 'open'
    # if the first parameter to start is quoted, it uses that as the title
    # so we pass a blank title so we can quote the file we are opening
    when 'win32' then 'start ""'
    # use Portlands xdg-open everywhere else
    else path.join GLOBAL.ROOT_DIR, 'bin/xdg-open'
  return exec opener + ' "' + escape(target) + '"', cb

# ### Create initial git repository
createDoc = (command, cb) ->
  docPath = path.join command.dir, 'doc'
  if fs.existsSync docPath
    if command.verbose
      console.log "Remove old documentation".grey
    fs.removeSync docPath
  # create index.html
  fs.mkdirsSync docPath
  fs.writeFileSync path.join(docPath, 'index.html'), """
    <html>
    <head>
      <meta http-equiv="refresh" content="0; url=README.md.html" />
      <script type="text/javascript">
          window.location.href = "README.md.html"
      </script>
      <title>Page Redirection</title>
    </head>
    <body>
      If you are not redirected automatically, follow the link to the
      <a href='README.md.html'>README</a>.
    </body>
    </html>
    """
  console.log "Create html documentation"
  docker = path.join GLOBAL.ROOT_DIR, "node_modules/.bin/docker"
  unless fs.existsSync docker
    return cb "Missing docker installation in #{docker}."
  proc = spawn docker, [
    '-i', command.dir
    '-u'
    if command.watch then '-w' else ''
    '-x', '.git,bin,doc,node_modules,test,lib,public,view,log,config,*/angular'
    '-o', path.join command.dir, 'doc'
    '-c', 'autumn'
    '--extras', 'fileSearch,goToLine'
  ]
  proc.stdout.on 'data', (data) ->
    unless ~data.toString().indexOf "Done."
      if command.verbose
        console.log data.toString().trim().grey
  proc.stderr.on 'data', (data) ->
    console.error data.toString().trim().magenta
  # Error management
  proc.on 'error', cb
  proc.on 'exit', (status) ->    
    return cb new Error "Docker exited with status #{status}" if status != 0
    # correct internal links
    tools.findbin 'replace', (err, cmd) ->
      if err
        console.warn err.toString().magenta
        return cb()
      console.log "Correcting local links".grey if command.verbose
      execFile cmd, [
        '(<a href="(?![#\/]|(ht|f)tps?://)[^?#"]+)(.*?)"'
        '$1.html$2"'
        path.join command.dir, 'doc'
        '-r'
      ], (err, stdout, stderr) ->
        console.log stdout.trim().grey if stdout and command.verbose
        console.error stderr.trim().magenta if stderr
        return cb err if err
        pack = JSON.parse fs.readFileSync path.join command.dir, 'package.json'
        return cb unless pack?.repository?.url? and ~pack.repository.url.indexOf 'github.com'
        execFile cmd, [
          '(<div id="container">)'
          '$1<a id="fork" href="'+pack.repository.url+'" title="Form me on GitHub"></a>'
          path.join command.dir, 'doc'
          '-r'
        ], (err, stdout, stderr) ->
          console.log stdout.trim().grey if stdout and command.verbose
          console.error stderr.trim().magenta if stderr
          cb err

# ### Create temporary directory
createTmpDir = (command, cb) ->
  filename = 'alinex-make-' + crypto.randomBytes(4).readUInt32LE(0) + '-gh'
  command.tmpdir = path.join os.tmpdir(), filename
  if command.verbose
    console.log "Create temporary directory at #{command.tmpdir}".grey
  fs.mkdirs command.tmpdir, cb

# ### Clone git repository
cloneGit = (command, cb) ->
  file = path.join command.dir, 'package.json'
  pack = JSON.parse fs.readFileSync file
  console.log "Cloning git repository"
  execFile 'git', [
    'clone'
    pack.repository.url
    command.tmpdir
  ], (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and command.verbose
    console.error stderr.trim().magenta if stderr
    cb err

# ### Checkout gh-pages branch
checkoutPages = (command, cb) ->
  console.log "Checkout gh-pages branch"
  execFile 'git', [
    'checkout', 'gh-pages'
  ], { cwd: command.tmpdir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and command.verbose
    console.error stderr.trim().magenta if stderr
    return cb() unless err
    execFile 'git', [
      'checkout'
      '--orphan'
      'gh-pages'
    ], { cwd: command.tmpdir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and command.verbose
      console.error stderr.trim().magenta if stderr
      cb err

# ### Update the documentation
updateDoc = (command, cb) ->
  console.log "Update documentation"
  if command.verbose
    console.log "Remove old documentation".grey
  execFile 'git', [
    'rm', '-rf', '.'
  ], { cwd: command.tmpdir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and command.verbose
    console.error stderr.trim().magenta if stderr
    if command.verbose
      console.log "Copy new documentation into repository".grey
    fs.copy path.join(command.dir, 'doc'), command.tmpdir, (err) ->
      return cb err if err
      if command.verbose
        console.log "Add files to git".grey
      execFile 'git', [
        'add', '*'
      ], { cwd: command.tmpdir }, (err, stdout, stderr) ->
        console.log stdout.trim().grey if stdout and command.verbose
        console.error stderr.trim().magenta if stderr
        return cb err if err
        if command.verbose
          console.log "Commit changes".grey
        execFile 'git', [
          'commit'
          '-m', "Updated documentation"
        ], { cwd: command.tmpdir }, (err, stdout, stderr) ->
          console.log stdout.trim().grey if stdout and command.verbose
          console.error stderr.trim().magenta if stderr
          cb err

# ### Push to git origin
pushOrigin = (command, cb) ->
  console.log "Push to git origin"
  execFile "git", [
    'push'
    'origin', 'gh-pages'
  ], { cwd: command.tmpdir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and command.verbose
    console.error stderr.trim().magenta if stderr
    return cb err if err
    cb()

