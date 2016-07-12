# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node packages
path = require 'path'
async = require 'async'
# alinex packages
fs = require 'alinex-fs'
# used through shell
# - require 'alinex-codedoc'
# - require 'replace'
# internal mhelper modules
builder = require '../index'


# Create new API documentation
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
# - `publish` - (boolean) flag if result should be published
module.exports = (dir, options, cb) ->
  builder.info dir, options, "create api documentation"
  docPath = path.join dir, 'doc'
  builder.task "packageJson", dir, options, (err, pack) ->
    alinex = (pack.name.split /-/)[0] is 'alinex'
    fs.npmbin 'replace', path.dirname(path.dirname __dirname), (err, replace) ->
      return cb err if err
      async.series [
        (cb) -> revodeDir dir, options, docPath, cb
        (cb) -> createFolder dir, options, docPath, cb
        (cb) ->
          async.parallel [
            (cb) -> createIndex dir, options, docPath, cb
            (cb) -> codedoc dir, options, docPath, cb
#            (cb) -> copyImages dir, options, docPath, cb
          ], cb
#        (cb) -> githubLink dir, options, docPath, pack, replace, cb
#        (cb) -> addViewport dir, options, docPath, replace, cb
#        (cb) -> emptyCode dir, options, docPath, cb
#        (cb) -> emptyLines dir, options, docPath, cb
#        (cb) -> addAlinex dir, options, docPath, alinex, replace, cb
#        (cb) -> copyCss dir, options, pack, cb
#        (cb) -> copyJs dir, options, pack, cb
      ], (err) -> cb err


# Helper
# -------------------------------------------------------------

revodeDir = (dir, options, docPath, cb) ->
  fs.exists docPath, (exists) ->
    return cb() unless exists
    builder.debug dir, options, "remove doc/ folder"
    fs.remove docPath, cb

createFolder = (dir, options, docPath, cb) ->
  builder.debug dir, options, "create doc/ folder"
  fs.mkdirs docPath, cb

createIndex = (dir, options, docPath, cb) ->
  builder.debug dir, options, "create index page"
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

codedoc = (dir, options, docPath, cb) ->
  fs.npmbin 'codedoc', path.dirname(path.dirname __dirname), (err, cmd) ->
    return cb err if err
    args = [
      '-i', dir
      '-o', docPath
    ]
    builder.exec dir, options, 'create api',
      cmd: cmd
      args: args
      cwd: dir
      check:
        noExitCode: true
    , cb

copyImages = (dir, options, docPath, cb) ->
  # copy images
  builder.debug dir, options, "copy images"
  from = path.join dir, 'src'
  to = path.join docPath, 'src'
  fs.copy from, to,
    include: '*.{png,jpg,gif}'
  , cb

githubLink = (dir, options, docPath, pack, replace, cb) ->
  return cb() unless pack.repository.url.match /github\.com/
  builder.exec dir, options, 'add github link',
    cmd: replace
    args: [
      '(<div id="container")>'
      '$1 tabindex="0"><a id="fork" href="'+pack.repository.url+'"
      title="Fork me on GitHub"></a>'
      docPath,
      '-r'
    ]
    cwd: dir
  , cb

addViewport = (dir, options, docPath, replace, cb) ->
  builder.exec dir, options, 'add viewport',
    cmd: replace
    args: [
      '(</head>)'
      '<meta name="viewport" content="width=device-width, initial-scale=1.0" />$1'
      docPath
      '-r'
    ]
    cwd: dir
  , cb

emptyCode = (dir, options, docPath, cb) ->
  builder.exec dir, options, 'remove empty code',
    cmd: 'sh'
    args: [
      '-c'
      "find #{docPath} -name \\*.html | xargs sed -i ':a;N;$!ba;s/<pre[^>]*>\\s*<\\/pre>//g'"
    ]
    cwd: dir
  , cb

emptyLines = (dir, options, docPath, cb) ->
  # remove empty lines at end of code elements
  builder.exec dir, options, 'remove empty lines in code',
    cmd: 'sh'
    args: [
      '-c'
      "find #{docPath} -name \\*.html | xargs sed -i ':a;N;$!ba;s/\\s*<\\/pre>/<\\/pre>/g'"
    ]
    cwd: dir
  , cb

addAlinex = (dir, options, docPath, alinex, replace, cb) ->
  return cb() unless alinex
  builder.exec dir, options, 'add alinex header',
    cmd: replace
    args: [
      '(<div id="sidebar_wrapper">)'
      '''
      <nav>
      <div class="logo"><a href="http://alinex.github.io"
        onmouseover="logo.src='https://alinex.github.io/images/Alinex-200.png'"
        onmouseout="logo.src='https://alinex.github.io/images/Alinex-black-200.png'">
        <img name="logo" src="https://alinex.github.io/images/Alinex-black-200.png"
          width="150" title="Alinex Universe Homepage" />
        </a>
        <img src="http://alinex.github.io/images/Alinex-200.png"
          style="display:none" alt="preloading" />
      </div>
      <div class="links">
        <a href="http://alinex.github.io/blog"
          class="btn btn-primary"><span class="glyphicon-pencil"></span> Blog</a>
        <a href="http://alinex.github.io/develop"
          class="btn btn-primary"><span class="glyphicon-book"></span> Develop</a>
        <a href="http://alinex.github.io/code.html"
          class="btn btn-warning"><span class="glyphicon-cog"></span> Code</a>
      </div>
      </nav>$1
      '''
      docPath
      '-r'
    ]
    cwd: dir
  , cb

copyCss = (dir, options, pack, cb) ->
  async.filter [
    path.join __dirname, '../../var/local/docstyle', (pack.name.split /-/)[0] + '.css'
    path.join __dirname, '../../var/src/docstyle', (pack.name.split /-/)[0] + '.css'
  ], (file, cb) ->
    fs.exists file, (exists) -> cb null, exists
  , (err, files) ->
    return cb err if err
    return cb() unless files.length
    fs.copy files[0], path.join(dir, 'doc', 'doc-style.css'),
      overwrite: true
    , cb

copyJs = (dir, options, pack, cb) ->
  async.filter [
    path.join __dirname, '../../var/local/docstyle', (pack.name.split /-/)[0] + '.js'
    path.join __dirname, '../../var/src/docstyle', (pack.name.split /-/)[0] + '.js'
  ], (file, cb) ->
    fs.exists file, (exists) -> cb null, exists
  , (err, files) ->
    return cb() unless files.length
    fs.copy files[0], path.join(dir, 'doc', 'doc-script.js'),
      overwrite: true
    , cb
