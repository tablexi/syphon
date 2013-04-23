class Syphon::Api::RailsConfig
  extend Syphon::Inflections

  private_class_method :new

  class << self

    def add_resource_route(resource)
      @resource = resource

      build_controller_chain

      unless @resource.hidden
        if @resource.routes.empty? 
          draw_resourceful_routes
        else
          draw_custom_routes
        end
      end
    end

    def add_discovery_route(path, resource_set)
      Rails.application.routes.draw do
        match path => proc { |env| [200, {"Content-TYpe" => 'application/json'}, [resource_set.to_json]] }
      end
    end

  private

    def build_controller_chain
      controller = @resource.controller_class || 
        Class.new(@resource.super_controller_class || ActionController::Base)

      # inherit from CRUDController to add decorator helper functions
      # even if the controller already exists
      #
      controller.send(:include, Syphon::Api::CRUDController)
      controller.init(@resource)

      # set a constant name for the controller if it was built
      #
      unless controller.name
        @resource.namespace_module.const_set(
          controllerize(@resource.controller), 
          controller)
      end
    end

    def draw_resourceful_routes
      resource = @resource

      Rails.application.routes.draw do
        nested_namespace(resource.namespace.split('/')) do
          resources resource.name, :controller => resource.controller, 
                                   :only => resource.only
        end
      end
    end

    def draw_custom_routes
      resource = @resource
      routes = @resource.routes
      controller = @resource.controller

      Rails.application.routes.draw do
        nested_namespace(resource.namespace.split('/')) do
          routes.each do |action, route|
            route, opts = route if route.is_a?(Array)
            match( { route => "#{controller}##{action}" }.merge(opts || {}) )
          end
        end
      end
    end

  end
end
