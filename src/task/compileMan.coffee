# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node packages
path = require 'path'
async = require 'async'
marked = require 'marked-man'
# alinex packages
fs = require 'alinex-fs'
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
    builder.info dir, options, "compile man pages"
    pack.man = [pack.man] if typeof pack.man is 'string'
    src = path.join dir, 'src'
    # create output directory
    fs.mkdirs path.join(dir, 'man'), (err) ->
      return cb err if err
      # make all manpages
      async.each pack.man, (name, cb) ->
        input = "#{src}/#{name}.md"
        dest = "#{dir}/#{name}"
        fs.exists input, (exists) ->
          return cb new Error "The file '#{input}' didn't exist" unless exists
          builder.debug dir, options, "create #{name}"
          fs.readFile input, 'utf8', (err, md) ->
            return cb err if err
            roff = marked.parse md,
              format: "roff"
              name: path.basename input, path.extname input
              date: '1979-01-01'
              gfm: true
              breaks: true
            fs.writeFile dest, roff, 'utf8', cb
      , cb
