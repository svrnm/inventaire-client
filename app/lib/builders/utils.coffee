module.exports = (Backbone, _, app, window)->
  # _ starts as a global object with just the underscore lib

  # extending _ with invUtils functions
  _ = invUtils _

  # add client-specific utils
  local = require('lib/utils')(Backbone, _, app, window)
  _.extend _, local

  # http requests handler returning promises
  _.preq = require 'lib/preq'

  _.isMobile = require 'lib/mobile_check'

  return _