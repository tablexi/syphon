require 'json'
require 'active_support'
require 'syphon/dsl_context'
require 'syphon/core_ext/action_dispatch'

class Syphon::Api
  autoload :Resource,       'syphon/api/resource'
  autoload :ModelProxy,     'syphon/api/model_proxy'
  autoload :CRUDController, 'syphon/api/crud_controller'

  private_class_method :new # enforce singleton

  class << self

    attr_accessor :resources

    def api(&definition)
      @resources = Syphon::DSLContext[definition, resource_class: Syphon::Api::Resource]
      @resources.each { |n, r| r.api = self } # hack, figure out a better way to backreference
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
