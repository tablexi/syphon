require 'syphon/version'

module Syphon
  autoload :Api,         'syphon/api'
  autoload :Client,      'syphon/client'

  autoload :Inflections, 'syphon/common/inflections'
  autoload :Resource,    'syphon/common/resource'
  autoload :ResourceSet, 'syphon/common/resource_set'
  autoload :ResourceDSL, 'syphon/common/resource_dsl'
end
