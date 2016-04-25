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


# Helper
# ------------------------------------------------

module.exports = (dir, args, cb) ->
  # check for configured man pages
  builder.task 'packageJson', dir, args, (err, pack) ->
    return cb err if err
    return cb() unless pack.man?
    builder.debug "compile man pages", dir, args
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
          builder.noisy "create #{pack.man}", dir, args
          fs.npmbin 'marked-man', path.dirname(path.dirname __dirname), (err, cmd) ->
            return cb err if err
            builder.exec 'compile into man',
              cmd: cmd
              args: [ input ]
              cwd: dir
            , (err, proc) ->
              return cb err if err
              builder.noisy "write into " + path.join(dir, name), dir, args
              fs.writeFile path.join(dir, name), proc.stdout(), cb
      , cb
