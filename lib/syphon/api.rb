require 'syphon/core_ext/action_dispatch'

class Syphon::Api
  autoload :Resource,       'syphon/api/resource'
  autoload :RailsConfig,    'syphon/api/rails_config'
  autoload :ModelProxy,     'syphon/api/model_proxy'
  autoload :ModelDecorator, 'syphon/api/model_decorator'
  autoload :CRUDController, 'syphon/api/crud_controller'

  private_class_method :new # enforce singleton

  class << self

    attr_accessor :resource_set

    def api(config = nil, &definition)
      @resource_set = Syphon::ResourceDSL.parse(config, 
        { resource_class: Syphon::Api::Resource }, 
        &definition)
    end

    def draw_routes!(application)
      @resource_set.each do |name, resource|
        RailsConfig.add_resource(application, resource)
      end
    end

    # Pretend we're a Rack app so rails can route to us.
    #
    def draw_discovery_route!(application, path)
      resource_set = @resource_set
      application.routes.draw do
        match path => proc { |env| [200, {"Content-TYpe" => 'application/json'}, [resource_set.to_json]] }
      end
    end

  end
end
