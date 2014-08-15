# Create API documentation
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
debug = require('debug')('make:doc')
async = require 'async'
fs = require 'alinex-fs'
path = require 'path'
colors = require 'colors'
{exec, execFile, spawn} = require 'child_process'
os = require 'os'
crypto = require 'crypto'

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
#
# This task will create the documentation and publish it if switch `--publish`
# is set. The publication can be done to github pages or using the `doc-publish`
# script if defined.
module.exports.run = (dir, options, cb) ->
  url = path.join dir, 'doc', 'index.html'
  if options.watch and options.browser
    setTimeout ->
      openUrl options, url
    , 5000
  # Create the html documentation out of source files
  createDoc dir, options, (err) ->
    return cb err if err
    # Check for specific doc style
    pack = JSON.parse fs.readFileSync path.join dir, 'package.json'
    file = path.join GLOBAL.ROOT_DIR, 'var/local/docstyle', (pack.name.split /-/)[0] + '.css'
    unless fs.existsSync file
      file = path.join GLOBAL.ROOT_DIR, 'var/src/docstyle', (pack.name.split /-/)[0] + '.css'
    # Use specific doc style
    if fs.existsSync file
      fs.copySync file, path.join(dir, 'doc', 'doc-style.css'),
        overwrite: true
    # Check for specific doc script
    pack = JSON.parse fs.readFileSync path.join dir, 'package.json'
    file = path.join GLOBAL.ROOT_DIR, 'var/local/docstyle', (pack.name.split /-/)[0] + '.js'
    unless fs.existsSync file
      file = path.join GLOBAL.ROOT_DIR, 'var/src/docstyle', (pack.name.split /-/)[0] + '.js'
    # Use specific doc style
    if fs.existsSync file
      fs.copySync file, path.join(dir, 'doc', 'doc-script.js'),
        overwrite: true
    # Check if --publish flag is set
    unless options.publish
      return openUrl options, url, cb if options.browser
      cb()
    # Publish using script from package.json
    if pack.scripts?['doc-publish']?
      debug "exec #{dir}> #{pack.scripts['doc-publish']}"
      exec pack.scripts['doc-publish'], { cwd: dir }, (err, stdout, stderr) ->
        if options.verbose
          console.log stdout.toString().trim().grey if stdout
        console.log stderr.toString().trim().magenta if stderr
        return cb err if err
        return openUrl options, url, cb if options.browser
        return cb()
    # Or publish to GitHub
    else if ~pack.repository?.url?.indexOf 'github.com/'
      createTmpDir dir, options, (err, tmpdir) ->
        return cb err if err
        async.series [
          (cb) -> cloneGit dir, tmpdir, options, cb
          (cb) -> checkoutPages dir, tmpdir, options, cb
          (cb) -> updateDoc dir, tmpdir, options, cb
          (cb) -> pushOrigin dir, tmpdir, options, cb
        ], (err) ->
          throw err if err
          fs.remove tmpdir, (err) ->
            return openUrl options, url, cb if options.browser
            return cb()
    # Publication was not possible
    else
      console.error "Could not publish, specify doc-publish script in package.json".magenta
      return openUrl options, url, cb if options.browser
      return cb()

# ### Open the given url in the default browser
openUrl = (options, target, cb) ->
  if options.verbose
    console.log "Open #{target} in browser".grey
  opener = switch process.platform
    when 'darwin' then 'open'
    # if the first parameter to start is quoted, it uses that as the title
    # so we pass a blank title so we can quote the file we are opening
    when 'win32' then 'start ""'
    # use Portlands xdg-open everywhere else
    else path.join GLOBAL.ROOT_DIR, 'bin/xdg-open'
  debug "exec> #{opener} \"#{encodeURI target}\""
  return exec opener + ' "' + encodeURI(target) + '"', cb

# ### Create initial git repository
createDoc = (dir, options, cb) ->
  docPath = path.join dir, 'doc'
  if fs.existsSync docPath
    if options.verbose
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
  args = [
    '-i', dir
    '-u'
    if options.watch then '-w' else ''
    '-x', '.git,bin,doc,node_modules,test,lib,public,view,log,config,*/angular'
    '-o', path.join dir, 'doc'
    '-c', 'autumn'
    '--extras', 'fileSearch,goToLine'
  ]
  debug "exec> #{docker} #{args.join ' '}"
  proc = spawn docker, args
  proc.stdout.on 'data', (data) ->
    unless ~data.toString().indexOf "Done."
      if options.verbose
        console.log data.toString().trim().grey
  proc.stderr.on 'data', (data) ->
    console.error data.toString().trim().magenta
  # Error management
  proc.on 'error', cb
  proc.on 'exit', (status) ->
    return cb new Error "Docker exited with status #{status}" if status != 0
    # correct internal links
    fs.npmbin 'replace', path.dirname(__dirname), (err, cmd) ->
      if err
        console.warn err.toString().magenta
        return cb()
      console.log "Correcting local links".grey if options.verbose
      args = [
        '(<a href="(?!#|.+?://(?!alinehhhx.github.io))[^?#"]+[^/?#"])(.*?")'
        '$1.html$2'
        path.join dir, 'doc'
        '-r'
      ]
      debug "exec> #{cmd} #{args.join ' '}"
      execFile cmd, args, (err, stdout, stderr) ->
        console.log stdout.trim().grey if stdout and options.verbose
        console.error stderr.trim().magenta if stderr
        return cb err if err
        pack = JSON.parse fs.readFileSync path.join dir, 'package.json'
        return cb unless pack?.repository?.url? and ~pack.repository.url.indexOf 'github.com'
        args = [
          '(<div id="container">)'
          '$1<a id="fork" href="'+pack.repository.url+'" title="Fork me on GitHub"></a>'
          path.join dir, 'doc'
          '-r'
        ]
        debug "exec> #{cmd} #{args.join ' '}"
        execFile cmd, args, (err, stdout, stderr) ->
          console.log stdout.trim().grey if stdout and options.verbose
          console.error stderr.trim().magenta if stderr
          cb err

# ### Create temporary directory
createTmpDir = (dir, options, cb) ->
  filename = 'alinex-make-' + crypto.randomBytes(4).readUInt32LE(0) + '-gh'
  tmpdir = path.join os.tmpdir(), filename
  if options.verbose
    console.log "Create temporary directory at #{tmpdir}".grey
  fs.mkdirs tmpdir, (err) ->
    return cb err if err
    cb null, tmpdir

# ### Clone git repository
cloneGit = (dir, tmpdir, options, cb) ->
  file = path.join dir, 'package.json'
  pack = JSON.parse fs.readFileSync file
  console.log "Cloning git repository"
  debug "exec> git clone #{pack.repository.url} #{tmpdir}"
  execFile 'git', [
    'clone'
    pack.repository.url
    tmpdir
  ], (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and options.verbose
    console.error stderr.trim().magenta if stderr
    cb err

# ### Checkout gh-pages branch
checkoutPages = (dir, tmpdir, options, cb) ->
  console.log "Checkout gh-pages branch"
  debug "exec #{tmpdir}> git checkout gh-pages"
  execFile 'git', [
    'checkout', 'gh-pages'
  ], { cwd: tmpdir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and options.verbose
    console.error stderr.trim().magenta if stderr
    return cb() unless err
    debug "exec #{tmpdir}> git checkout --orphan gh-pages"
    execFile 'git', [
      'checkout'
      '--orphan'
      'gh-pages'
    ], { cwd: tmpdir }, (err, stdout, stderr) ->
      console.log stdout.trim().grey if stdout and options.verbose
      console.error stderr.trim().magenta if stderr
      cb err

# ### Update the documentation
updateDoc = (dir, tmpdir, options, cb) ->
  console.log "Update documentation"
  if options.verbose
    console.log "Remove old documentation".grey
  debug "exec #{tmpdir}> git rm -rf ."
  execFile 'git', [
    'rm', '-rf', '.'
  ], { cwd: tmpdir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and options.verbose
    console.error stderr.trim().magenta if stderr
    if options.verbose
      console.log "Copy new documentation into repository".grey
    fs.copy path.join(dir, 'doc'), tmpdir, (err) ->
      return cb err if err
      if options.verbose
        console.log "Add files to git".grey
      debug "exec #{tmpdir}> git add *"
      execFile 'git', [
        'add', '*'
      ], { cwd: tmpdir }, (err, stdout, stderr) ->
        console.log stdout.trim().grey if stdout and options.verbose
        console.error stderr.trim().magenta if stderr
        return cb err if err
        if options.verbose
          console.log "Commit changes".grey
        debug "exec #{tmpdir}> git commit -m \"Updated documentation\""
        execFile 'git', [
          'commit'
          '-m', "Updated documentation"
        ], { cwd: tmpdir }, (err, stdout, stderr) ->
          console.log stdout.trim().grey if stdout and options.verbose
          console.error stderr.trim().magenta if stderr
          cb err

# ### Push to git origin
pushOrigin = (dir, tmpdir, options, cb) ->
  console.log "Push to git origin"
  debug "exec #{tmpdir}> git push origin gh-pages"
  execFile "git", [
    'push'
    'origin', 'gh-pages'
  ], { cwd: tmpdir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and options.verbose
    console.error stderr.trim().magenta if stderr
    return cb err if err
    cb()

