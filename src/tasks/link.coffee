# Link local modules
# =================================================


# Node modules
# -------------------------------------------------

# include base modules
path = require 'path'
chalk = require 'chalk'
# include alinex modules
fs = require 'alinex-fs'
path = require 'path'
async = require 'alinex-async'
Exec = require 'alinex-exec'
{string} = require 'alinex-util'

# Main routine
# -------------------------------------------------
#
# __Arguments:__
#
# * `dir`
#   Directory to operate on
# * `options`
#   Command specific parameters and options.
# * `callback(err)`
#   The callback will be called just if an error occurred or with `null` if
#   execution finished.
module.exports.run = (dir, options, cb) ->
  console.log "Link locals package #{dir}"
  find dir, options, (err, links) ->
    return cb err if err
    async.each links, (link, cb) ->
      console.log chalk.grey "#{link[0]} => #{link[1]}" if options.verbose
      # rm link[0]
      fs.remove path.join(dir, 'node_modules', link[0]), (err) ->
        # make new link
        fs.symlink path.join(dir, '../..', link[1]), path.join(dir, 'node_modules', link[0]), cb
    , cb

find = (dir, options, cb) ->
  fs.readdir path.join(dir, 'node_modules'), (err, list1) ->
    return cb err if err
    fs.readdir path.join(dir, '..'), (err, list2) ->
      return cb err if err
      res = []
      if options.local?
        for p in options.local
          if p in list1 and p in list2
            res.push [p, p]
          else if "node-#{p}" in list2
            res.push ["alinex-#{p}", "node-#{p}"]
      else
        for p in list2
          if string.starts p, 'node-'
            res.push [p.replace(/node/, 'alinex'), p]
      cb null, res
