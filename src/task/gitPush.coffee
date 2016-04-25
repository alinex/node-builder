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
module.exports = (dir, args, cb) ->
  builder.debug dir, args, "check git status"
  # run the pull options
  builder.exec dir, args, 'git push',
    cmd: 'git'
    args: [ 'push', '--tags', 'origin', 'master' ]
    cwd: dir
    retry:
      times: 3
  , cb
