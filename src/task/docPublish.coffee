# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node packages
path = require 'path'
# alinex packages
fs = require 'alinex-fs'
async = require 'alinex-async'
# internal mhelper modules
builder = require '../index'


# Create new API documentation
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
# - `publish` - (boolean) flag if result should be published
module.exports = (dir, options, cb) ->
  return cb() unless options.publish
  builder.info dir, options, "publish documentation"
  builder.task "packageJson", dir, options, (err, pack) ->
    return cb err if err
    if pack.scripts?['doc-publish']?
      builder.exec dir, options, "publish script",
        cmd: 'sh'
        args: ['-c', pack.scripts['doc-publish']]
        cwd: dir
      , cb()
    else if ~pack.repository?.url?.indexOf 'github.com/'
      fs.tempdir null, 'alinex-builder-', (err, tmpdir) ->
        return cb err if err
        async.series [
          (cb) -> cloneGit dir, options, tmpdir, pack, cb
          (cb) -> checkout dir, options, tmpdir, cb
          (cb) -> removeFiles dir, options, tmpdir, cb
          (cb) -> copyFiles dir, options, tmpdir, cb
          (cb) -> commit dir, options, tmpdir, cb
          (cb) -> push dir, options, tmpdir, cb
        ], (err) ->
          fs.remove tmpdir, ->
          return cb err
    # Publication was not possible
    else
      cb new Error "Could not publish, specify doc-publish script in package.json"


# Helper
# ------------------------------------------------------------

cloneGit = (dir, options, tmpdir, pack, cb) ->
  builder.exec dir, options, "git clone",
    cmd: 'git'
    args: ['clone', pack.repository.url, tmpdir]
    cwd: dir
  , cb

checkout = (dir, options, tmpdir, cb) ->
  builder.exec dir, options, "checkout gh-pages",
    cmd: 'git'
    args: ['checkout', 'gh-pages']
    cwd: tmpdir
  , (err) ->
    return cb() unless err
    builder.exec dir, options, "checkout gh-pages (orphan)",
      cmd: 'git'
      args: ['checkout', '--orphan', 'gh-pages']
      cwd: tmpdir
    , cb

removeFiles = (dir, options, tmpdir, cb) ->
  builder.exec dir, options, "remove old files",
    cmd: 'git'
    args: ['rm', '-rf', '.']
    cwd: tmpdir
  , cb

copyFiles = (dir, options, tmpdir, cb) ->
  builder.debug dir, options, "copy new files"
  fs.copy path.join(dir, 'doc'), tmpdir, (err) ->
    return cb err if err
    builder.exec dir, options, "git add",
      cmd: 'git'
      args: ['add', '*']
      cwd: tmpdir
    , cb

commit = (dir, options, tmpdir, cb) ->
  builder.exec dir, options, "git commit",
    cmd: 'git'
    args: [
      'commit'
      '--allow-empty'
      '-m', "Updated documentation"
    ]
    cwd: tmpdir
  , cb

push = (dir, options, tmpdir, cb) ->
  builder.exec dir, options, "git push origin",
    cmd: 'git'
    args: ['push', 'origin', 'gh-pages']
    cwd: tmpdir
  , cb
