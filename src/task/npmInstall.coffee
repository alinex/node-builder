# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# internal mhelper modules
builder = require '../index'


# Install using npm
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
module.exports = (dir, options, cb) ->
  builder.info dir, options, "install through npm"
  # run the pull options
  builder.exec dir, options, 'npm install',
    cmd: 'npm'
    args: [ 'install' ]
    cwd: dir
    retry:
      times: 3
  , cb
