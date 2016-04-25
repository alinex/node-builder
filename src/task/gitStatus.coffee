# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# internal mhelper modules
builder = require '../index'


# Check git status
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
module.exports = (dir, args, cb) ->
  builder.debug dir, args, "check git status"
  # run the pull options
  builder.exec dir, args, 'git status',
    cmd: 'git'
    args: [ 'status' ]
    cwd: dir
    env:
      LANG: 'C'
  , (err, proc) ->
    return cb err if err
    return cb() if ~proc.stdout().indexOf 'nothing to commit'
    cb null, proc.stdout()
