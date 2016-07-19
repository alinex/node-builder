# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# node packages
path = require 'path'
async = require 'async'
chalk = require 'chalk'
# alinex packages
fs = require 'alinex-fs'
codedoc = require 'alinex-codedoc'
# used through shell
# - require 'replace'
# internal mhelper modules
builder = require '../index'


# Create new API documentation
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
# - `publish` - (boolean) flag if result should be published
module.exports = (dir, options, cb) ->
  builder.info dir, options, "create api documentation"
  docPath = path.join dir, 'doc'
  async.series [
    (cb) -> removeDir dir, options, docPath, cb
    (cb) -> createDoc dir, options, docPath, cb
  ], (err) -> cb err


# Helper
# -------------------------------------------------------------

removeDir = (dir, options, docPath, cb) ->
  fs.exists docPath, (exists) ->
    return cb() unless exists
    builder.debug dir, options, "remove doc/ folder"
    fs.remove docPath, cb

createDoc = (dir, options, docPath, cb) ->
  builder.debug dir, options, "extract documentation"
  readExcludes dir, (err, list) ->
    return cb err if err
    codedoc.setup (err) ->
      return cb err if err
      codedoc.run
        input: dir
        find:
          exclude: list
        output: "#{dir}/doc"
        style: 'codedoc'
        code: options.code
      , cb

readExcludes = (dir, cb) ->
  async.detectSeries ["#{dir}/.docignore", "#{dir}/.gitignore"], (file, cb) ->
    fs.exists file, (exists) -> cb null, exists
  , (err, file) ->
    return cb() unless file
    fs.readFile file, 'utf8', (err, res) ->
      if err
        console.error chalk.magenta "Could not read #{file} for excludes"
        return cb()
      list = ".git/\n#{res}".split /\s*\n\s*/
      .filter (e) -> e.trim().length
      .map (e) ->
        e.replace /^\//, ''
        .replace /\./, '\\.'
        .replace /\*+/, '.*'
      cb null, new RegExp "^(#{list.join '|'})"
