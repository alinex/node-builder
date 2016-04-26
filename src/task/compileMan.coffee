# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node packages
path = require 'path'
# use marked-man binary
# alinex packages
fs = require 'alinex-fs'
async = require 'alinex-async'
# internal mhelper modules
builder = require '../index'


# Compile md -> man page
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
module.exports = (dir, options, cb) ->
  # check for configured man pages
  builder.task 'packageJson', dir, options, (err, pack) ->
    return cb err if err
    return cb() unless pack.man?
    builder.debug dir, options, "compile man pages"
    pack.man = [pack.man] if typeof pack.man is 'string'
    src = path.join dir, 'src'
    # create output directory
    fs.mkdirs path.join(dir, 'man'), (err) ->
      return cb err if err
      # make all manpages
      async.each pack.man, (name, cb) ->
        input = "#{src}/#{name}.md"
        fs.exists input, (exists) ->
          return cb new Error "The file '#{input}' didn't exist" unless exists
          builder.noisy dir, options, "create #{pack.man}"
          fs.npmbin 'marked-man', path.dirname(path.dirname __dirname), (err, cmd) ->
            return cb err if err
            builder.exec dir, options, 'compile into man',
              cmd: cmd
              args: [ input ]
              cwd: dir
            , (err, proc) ->
              return cb err if err
              builder.noisy dir, options, "write into " + path.join(dir, name)
              fs.writeFile path.join(dir, name), proc.stdout(), cb
      , cb
