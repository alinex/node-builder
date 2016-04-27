# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# internal mhelper modules
builder = require '../index'


# Pull newest git changes
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
module.exports = (dir, options, cb) ->
  builder.info dir, options, "check git status"
  # run the pull options
  builder.exec dir, options, 'git pull',
    cmd: 'git'
    args: [ 'pull', '-t', '-p', 'origin', 'master' ]
    cwd: dir
    retry:
      times: 3
  , cb
