require 'json'
require 'active_support'
require 'syphon/version'

module Syphon
end

require 'syphon/core_ext/action_dispatch'
require 'syphon/api'
require 'syphon/api/resource'
require 'syphon/api/dsl_context'
require 'syphon/api/model_proxy'
require 'syphon/api/crud_controller'
