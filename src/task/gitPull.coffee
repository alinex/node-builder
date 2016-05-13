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
  builder.info dir, options, "pull from git origin"
  # run the pull options
  builder.exec dir, options, 'git pull',
    cmd: 'git'
    args: [ 'pull', '-t', '-p', 'origin', 'master' ]
    cwd: dir
    env:
      HOME: process.env.HOME
    retry:
      times: 3
  , (err, proc) ->
    if err
      err.description = "STDERR: #{proc.stderr()}" if proc.stderr()
    cb err
