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
module.exports = (dir, options, cb) ->
  builder.info dir, options, "check git status"
  # run the pull options
  builder.exec dir, options, 'git status',
    cmd: 'git'
    args: [ 'status' ]
    cwd: dir
    env:
      LANG: 'C'
  , (err, proc) ->
    return cb err if err
    return cb() if ~proc.stdout().indexOf 'nothing to commit'
    cb null, proc.stdout()
