# Create API documentation
# =================================================


# Node modules
# -------------------------------------------------

# include alinex modules
Spawn = require 'alinex-spawn'
fs = require 'alinex-fs'
# include base modules
debug = require('debug')('builder')
async = require 'async'
path = require 'path'
chalk = require 'chalk'
{exec,execFile} = require 'child_process'
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
  pack = JSON.parse fs.readFileSync path.join dir, 'package.json'
  # Create the html documentation out of source files
  createDoc dir, options, (err) ->
    return cb err if err
    async.parallel [
      (cb) ->
        async.filter [
          path.join GLOBAL.ROOT_DIR, 'var/local/docstyle', (pack.name.split /-/)[0] + '.css'
          path.join GLOBAL.ROOT_DIR, 'var/src/docstyle', (pack.name.split /-/)[0] + '.css'
        ], fs.exists, (files) ->
          return cb() unless files.length
          fs.copy files[0], path.join(dir, 'doc', 'doc-style.css'),
            overwrite: true
          , cb
      (cb) ->
        async.filter [
          path.join GLOBAL.ROOT_DIR, 'var/local/docstyle', (pack.name.split /-/)[0] + '.js'
          path.join GLOBAL.ROOT_DIR, 'var/src/docstyle', (pack.name.split /-/)[0] + '.js'
        ], fs.exists, (files) ->
          return cb() unless files.length
          fs.copy files[0], path.join(dir, 'doc', 'doc-script.js'),
            overwrite: true
          , cb
    ], (err) ->
      return cb err if err
      # Check if --publish flag is set
      return publish dir, options, pack, cb if options.publish
      return openUrl options, url, cb if options.browser
      cb()

publish = (dir, options, pack, cb) ->
  # Publish using script from package.json
  if pack.scripts?['doc-publish']?
    debug "exec #{dir}> #{pack.scripts['doc-publish']}"
    exec pack.scripts['doc-publish'], { cwd: dir }, (err, stdout, stderr) ->
      if options.verbose
        console.log chalk.grey stdout.toString().trim() if stdout
      console.log chalk.magenta stderr.toString().trim() if stderr
      return cb err if err
      return openUrl options, url, cb if options.browser
      return cb()
  # Or publish to GitHub
  else if ~pack.repository?.url?.indexOf 'github.com/'
    fs.tempdir null, 'alinex-make-', (err, tmpdir) ->
      return cb err if err
      async.series [
        (cb) -> cloneGit dir, tmpdir, options, cb
        (cb) -> checkoutPages dir, tmpdir, options, cb
        (cb) -> updateDoc dir, tmpdir, options, cb
        (cb) -> pushOrigin dir, tmpdir, options, cb
      ], (err) ->
        return cb err if err
        fs.remove tmpdir, (err) ->
          return openUrl options, url, cb if options.browser
          return cb()
  # Publication was not possible
  else
    console.error chalk.magenta "Could not publish, specify doc-publish script in package.json"
    return openUrl options, url, cb if options.browser
    return cb()

# ### Open the given url in the default browser
openUrl = (options, target, cb) ->
  if options.verbose
    console.log chalk.grey "Open #{target} in browser"
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
  async.series [
    (cb) ->
      fs.exists docPath, (exists) ->
        return cb() unless exists
        if options.verbose
          console.log chalk.grey "Remove old documentation"
        fs.remove docPath, cb
    (cb) ->
      console.log chalk.grey "Create new documentation folder" if options.verbose
      fs.mkdirs docPath, cb
    (cb) ->
      # create index.html
      console.log chalk.grey "Create index page" if options.verbose
      fs.writeFile path.join(docPath, 'index.html'), """
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
        """, cb
    (cb) ->
      console.log "Create html documentation"
      fs.npmbin 'docker', path.dirname(path.dirname __dirname), (err, cmd) ->
        return cb err if err
        args = [
          '-i', dir
          '-u'
          if options.watch then '-w' else ''
          '-x', '.git,bin,doc,node_modules,test,lib,public,view,log,config,*/angular'
          '-o', path.join dir, 'doc'
          '-c', 'autumn'
          '--extras', 'fileSearch,goToLine'
        ]
        proc = new Spawn
          cmd: cmd
          args: args
          check: (proc) -> new Error "Got exit code of #{proc.code}" if proc.code
        proc.run cb
    (cb) ->
      # correct internal links
      fs.npmbin 'replace', path.dirname(path.dirname __dirname), (err, cmd) ->
        return cb err if err
        console.log chalk.grey "Correcting local links" if options.verbose
        proc = new Spawn
          cmd: cmd
          args: [
            '(<a href="(?!#|.+?://)[^?#"]+[^/?#"])(.*?")'
            '$1.html$2'
            path.join dir, 'doc'
            '-r'
          ]
        proc.run cb
    (cb) ->
      # correct internal links
      fs.npmbin 'replace', path.dirname(path.dirname __dirname), (err, cmd) ->
        pack = JSON.parse fs.readFileSync path.join dir, 'package.json'
        return cb() unless pack?.repository?.url? and ~pack.repository.url.indexOf 'github.com'
        proc = new Spawn
          cmd: cmd
          args: [
            '(<div id="container">)'
            '$1<a id="fork" href="'+pack.repository.url+'" title="Fork me on GitHub"></a>'
            path.join dir, 'doc'
            '-r'
          ]
        proc.run cb
    (cb) ->
      # copy images
      from = path.join dir, 'src'
      to = path.join docPath, 'src'
      fs.copy from, to,
        include: '*.{png,jpg,gif}'
      , cb
  ], cb

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
    console.log chalk.grey stdout.trim() if stdout and options.verbose
    console.error chalk.magenta stderr.trim() if stderr
    cb err

# ### Checkout gh-pages branch
checkoutPages = (dir, tmpdir, options, cb) ->
  console.log "Checkout gh-pages branch"
  debug "exec #{tmpdir}> git checkout gh-pages"
  execFile 'git', [
    'checkout', 'gh-pages'
  ], { cwd: tmpdir }, (err, stdout, stderr) ->
    console.log chalk.grey stdout.trim() if stdout and options.verbose
    console.error chalk.magenta stderr.trim() if stderr
    return cb() unless err
    debug "exec #{tmpdir}> git checkout --orphan gh-pages"
    execFile 'git', [
      'checkout'
      '--orphan'
      'gh-pages'
    ], { cwd: tmpdir }, (err, stdout, stderr) ->
      console.log chalk.grey stdout.trim() if stdout and options.verbose
      console.error chalk.magenta stderr.trim() if stderr
      cb err

# ### Update the documentation
updateDoc = (dir, tmpdir, options, cb) ->
  console.log "Update documentation"
  if options.verbose
    console.log chalk.grey "Remove old documentation"
  debug "exec #{tmpdir}> git rm -rf ."
  execFile 'git', [
    'rm', '-rf', '.'
  ], { cwd: tmpdir }, (err, stdout, stderr) ->
    console.log stdout.trim().grey if stdout and options.verbose
    console.error stderr.trim().magenta if stderr
    if options.verbose
      console.log chalk.grey "Copy new documentation into repository"
    fs.copy path.join(dir, 'doc'), tmpdir, (err) ->
      return cb err if err
      if options.verbose
        console.log chalk.grey "Add files to git"
      debug "exec #{tmpdir}> git add *"
      execFile 'git', [
        'add', '*'
      ], { cwd: tmpdir }, (err, stdout, stderr) ->
        console.log stdout.trim().grey if stdout and options.verbose
        console.error stderr.trim().magenta if stderr
        return cb err if err
        if options.verbose
          console.log chalk.grey "Commit changes"
        debug "exec #{tmpdir}> git commit -m \"Updated documentation\""
        execFile 'git', [
          'commit'
          '-m', "Updated documentation"
        ], { cwd: tmpdir }, (err, stdout, stderr) ->
          console.log chalk.grey stdout.trim() if stdout and options.verbose
          console.error chalk.magenta stderr.trim() if stderr
          cb err

# ### Push to git origin
pushOrigin = (dir, tmpdir, options, cb) ->
  console.log "Push to git origin"
  debug "exec #{tmpdir}> git push origin gh-pages"
  execFile "git", [
    'push'
    'origin', 'gh-pages'
  ], { cwd: tmpdir }, (err, stdout, stderr) ->
    console.log chalk.grey stdout.trim() if stdout and options.verbose
    console.error chalk.magenta stderr.trim() if stderr
    return cb err if err
    cb()

