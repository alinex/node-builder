# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node packages
path = require 'path'
async = require 'async'
stylus = require 'stylus'
axis = require 'axis'
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
  fs.find "#{dir}/var/src/template",
    include: '*.styl'
  , (err, files) ->
    return cb() if err or not files
    builder.info dir, options, "compile stylus"
    # make all manpages
    async.each files, (file, cb) ->
      builder.debug dir, options, "compile #{file}"
      fs.readFile file, 'utf8', (err, data) ->
        return cb err if err
        stylus data
        .set 'filename', file
        .set 'compress', true
        .use axis()
        .render (err, css) ->
          return cb err if err
          cssfile = "#{path.dirname file}/#{path.basename file, path.extname file}.css"
          fs.writeFile cssfile, css, 'utf8', cb
    , cb
