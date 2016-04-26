# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# internal mhelper modules
builder = require '../index'


# Commit all changed files
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
# - `message` - (string) commit message
module.exports = (dir, options, cb) ->
  return cb() unless options.message
  builder.debug dir, options, "commit all changes"
  # run the pull options
  builder.exec dir, options, 'git add all',
    cmd: 'git'
    args: [ 'add', '-A' ]
    cwd: dir
  , (err) ->
    return cb err if err
    builder.exec dir, options, 'git commit',
      cmd: 'git'
      args: [ 'commit', '-m', options.message ]
      cwd: dir
      retry:
        times: 3
      check:
        noExitCode: true
    , cb
