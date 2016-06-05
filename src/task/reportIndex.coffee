# Test Script
# ========================================================================


# Node modules
# -------------------------------------------------

path = require 'path'
async = require 'async'
# alinex modules
fs = require 'alinex-fs'
# internal mhelper modules
builder = require '../index'


# Pull newest git changes
# ------------------------------------------------
# _Arguments:_
#
# - `verbose` - (integer) verbose level
module.exports = (dir, options, cb) ->
  builder.info dir, options, "create report index"
  # run
  async.map [
    'lcov-report/index.html'
    'profiling.txt'
  ], (index, cb) ->
    source = "#{dir}/report/#{index}"
    fs.readFile source, 'UTF8', (err, data) ->
      return cb() if err
      if index.match /.html/i
        # html
        base = path.dirname index
        match = data.match /<head>([\s\S]*?)<\/head>[\s\S]*?<body>([\s\S]*)<\/body>/i
        head = match[1].replace /<meta\s[\s\S]*?>\s*/g, ''
        .replace /<title>[\s\S]*?<\/title>\s*/g, ''
        .replace /\shref="(.*?)"/g, (e, link) ->
          return e if link.match /^(\/|(ht|f)tps?:)/i
          ' href="' + base + '/' + link + '"'
        body = match[2]
        .replace /\shref="(.*?)"/g, (e, link) ->
          return e if link.match /^(\/|(ht|f)tps?:)/i
          ' href="' + base + '/' + link + '"'
      else
        head = ''
        body = "<pre>#{data}</pre>"
      # specific changes to file
      switch index
        when 'lcov-report/index.html'
          body = body.replace /<h1>/, '<h1>Coverage of'
          .replace /^[\s\S]*<div class="wrapper">\s*/, ''
          .replace /\s*<!-- for sticky footer[\s\S]*/, ''
        when 'profiling.txt'
          body = body.replace /^[\s\S]*\[Summary\]:\s*/, '<h1>&nbsp;Profiling<br/><br/></h1><pre>  '
          .replace /\s*\[[\s\S]*/, '</pre>'
          body += '<p><a href="' + index + '">&nbsp;&nbsp;See the full data.</a></p>'
      cb null, [head, body]
  , (_, results) ->
    wstream = fs.createWriteStream "#{dir}/report/index.html"
    wstream.write '<!doctype html><html lang="en"><head>'
    wstream.write r[0] for r in results when r
    wstream.write '<title>Reports for ' + path.basename(dir) + '</title></head><body>'
    wstream.write "<h1>Reports for #{path.basename dir}</h1>"
    wstream.write r[1] for r in results when r
    wstream.write '</body></html>'
    wstream.end()
    wstream.on 'finish', cb
