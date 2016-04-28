# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

# include base modules
chalk = require 'chalk'
path = require 'path'
inquirer = require 'inquirer'
# include alinex modules
async = require 'alinex-async'
fs = require 'alinex-fs'
# internal mhelper modules
builder = require '../index'


# Setup
# -------------------------------------------------

exports.title = 'create a new package (interactive)'
exports.description = """
This command will create a new package and will therefore ask you some questions
interactively to do this.
"""


# Handler
# ------------------------------------------------

exports.handler = (options, cb) ->
  # step over directories
  dir = options._[1]
  unless dir
    err = new Error "Missing directory to create"
    err.exit = 2
    return cb err
  builder.info dir, options, 'started'
  async.series [
    (cb) -> createDir dir, options, cb
  ], (err, results) ->
    builder.results dir, options, "Results for #{path.basename dir}", results
    builder.info dir, options, 'done'
    cb err

# Helper
# ------------------------------------------------

createDir = (dir, options, cb) ->
  builder.debug dir, options, "create doc/ folder"
  fs.mkdirs dir, cb

  
