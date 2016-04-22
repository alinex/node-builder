# Test Script
# ========================================================================

exports.title = 'show changes since last release'
exports.description = 'list the changes since last published version'

#exports.options =
#  xtest:
#    alias: 'x'
#    type: 'string'

exports.handler = (args, cb) ->
  # shortcuts to predefined objects
  debug = exports.debug
  # do the job
  debug "running now..."
  console.log args
  # done ending function
  cb()
