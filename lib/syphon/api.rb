require 'syphon/core_ext/action_dispatch'

class Syphon::Api
  autoload :Resource,       'syphon/api/resource'
  autoload :RailsConfig,    'syphon/api/rails_config'
  autoload :ModelProxy,     'syphon/api/model_proxy'
  autoload :ModelDecorator, 'syphon/api/model_decorator'
  autoload :CRUDController, 'syphon/api/crud_controller'

  private_class_method :new # enforce singleton

  class << self

    attr_accessor :resources

    def api(config = nil, &definition)
      @resources = Syphon::ResourceDSL.parse(config, 
        { resource_class: Syphon::Api::Resource }, 
        &definition)
    end

    def draw_routes!(application)
      @resources.each do |name, resource|
        RailsConfig.add_resource(application, resource)
      end
    end

    # Pretend we're a Rack app so rails can route to us.
    #
    def draw_discovery_route!(application, path)
      api = self
      application.routes.draw do
        match path => proc { |env| [200, {"Content-TYpe" => 'application/json'}, [api.resource_map.to_json]] }
      end
    end

    def resource_map
      @resource_map ||= @resources.map { |n, r| r.serialize }
    end

  end
end
