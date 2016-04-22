# Main controlling class
# =================================================


# Node Modules
# -------------------------------------------------

# include base modules
chalk = require 'chalk'
path = require 'path'
# include alinex modules
fs = require 'alinex-fs'
async = require 'alinex-async'
config = require 'alinex-config'
Exec = require 'alinex-exec'


# Helper
# -------------------------------------------------
exports.setup = (cb) ->
  async.each [Exec], (mod, cb) ->
    mod.setup cb
  , (err) ->
    return cb err if err
# no own schema
#    # add schema for module's configuration
#      config.setSchema '/scripter', schema
    # set module search path
    config.register 'scripter', path.dirname __dirname
    cb()
