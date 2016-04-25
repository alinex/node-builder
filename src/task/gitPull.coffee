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
module.exports = (dir, args, cb) ->
  builder.debug dir, args, "check git status"
  # run the pull options
  builder.exec dir, args, 'git pull',
    cmd: 'git'
    args: [ 'pull', '-t', '-p', 'origin', 'master' ]
    cwd: dir
    retry:
      times: 3
  , cb
