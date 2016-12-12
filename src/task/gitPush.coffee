# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# internal mhelper modules
builder = require '../index'


# Push last changes to git
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
module.exports = (dir, options, cb) ->
  builder.info dir, options, "check git status"
  # run the pull options
  builder.exec dir, options, 'git push',
    cmd: 'git'
    args: [ 'push', '--all', 'origin' ]
    cwd: dir
    env:
      HOME: process.env.HOME
    retry:
      times: 3
  , cb
