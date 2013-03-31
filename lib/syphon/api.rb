require 'json'
require 'ostruct'
require 'active_support'
require 'syphon/common/resource'
require 'syphon/common/resource_dsl'
require 'syphon/core_ext/action_dispatch'

class Syphon::Api
  autoload :Resource,       'syphon/api/resource'
  autoload :ModelProxy,     'syphon/api/model_proxy'
  autoload :CRUDController, 'syphon/api/crud_controller'

  private_class_method :new # enforce singleton

  class << self

    attr_accessor :resources

    def api(&definition)
      @resources = Syphon::ResourceDSL[definition, resource_class: Syphon::Api::Resource]
    end

    def draw_routes!(application)
      return if @resources.empty?
      @resources.each do |name, resource|
        resource.build_controller
        resource.draw_route(application)
      end
    end

  end
end
