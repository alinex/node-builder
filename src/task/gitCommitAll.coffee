# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# internal mhelper modules
builder = require '../index'


# Helper
# ------------------------------------------------

module.exports = (dir, args, cb) ->
  builder.debug dir, args, "commit all changes"
  # run the pull options
  builder.exec dir,args, 'git add all',
    cmd: 'git'
    args: [ 'add', '-A' ]
    cwd: dir
  , (err) ->
    return cb err if err
    builder.exec dir,args, 'git commit',
      cmd: 'git'
      args: [ 'commit', '-m', args.message ]
      cwd: dir
      retry:
        times: 3
      check:
        noExitCode: true
    , cb
