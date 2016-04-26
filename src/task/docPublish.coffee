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
  builder.debug dir, options, "publish documentation"
  builder.task "packageJson", dir, options, (err, pack) ->
    return cb err if err
    if pack.scripts?['doc-publish']?
      builder.debug dir, options, "run publish script"
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
  builder.debug dir, options, "cloning git repository"
  builder.exec dir, options, "publish script",
    cmd: 'git'
    args: ['clone', pack.repository.url, tmpdir]
    cwd: dir
  , cb

checkout = (dir, options, tmpdir, cb) ->
  builder.debug dir, options, "checkout gh-pages"
  builder.exec dir, options, "checkout",
    cmd: 'git'
    args: ['checkout', 'gh-pages']
    cwd: tmpdir
  , (err) ->
    return cb() unless err
    builder.debug dir, options, "checkout gh-pages (orphan)"
    builder.exec dir, options, "checkout",
      cmd: 'git'
      args: ['checkout', '--orphan', 'gh-pages']
      cwd: tmpdir
    , cb

removeFiles = (dir, options, tmpdir, cb) ->
  builder.debug dir, options, "remove old files"
  builder.exec dir, options, "remove",
    cmd: 'git'
    args: ['rm', '-rf', '.']
    cwd: tmpdir
  , cb

copyFiles = (dir, options, tmpdir, cb) ->
  builder.debug dir, options, "copy new files"
  fs.copy path.join(dir, 'doc'), tmpdir, (err) ->
    return cb err if err
    builder.debug dir, options, "add files to git"
    builder.exec dir, options, "git add",
      cmd: 'git'
      args: ['add', '*']
      cwd: tmpdir
    , cb

commit = (dir, options, tmpdir, cb) ->
  builder.debug dir, options, "commit changes"
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
  builder.debug dir, options, "push to github"
  builder.exec dir, options, "git push origin",
    cmd: 'git'
    args: ['push', 'origin', 'gh-pages']
    cwd: tmpdir
  , cb
