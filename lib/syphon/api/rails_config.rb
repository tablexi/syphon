class Syphon::Api::RailsConfig
  extend Syphon::Inflections

  private_class_method :new

  class << self

    def add_resource(application, resource)
      @app = application
      @resource = resource

      build_controller_chain

      unless @resource.hidden
        if @resource.routes.empty? 
          draw_resourceful_routes(@app)
        else
          draw_custom_routes(@app)
        end
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

    def draw_resourceful_routes(app)
      resource = @resource

      @app.routes.draw do
        nested_namespace(resource.namespace.split('/')) do
          resources resource.name, :controller => resource.controller, 
                                   :only => resource.only
        end
      end
    end

    def draw_custom_routes(app)
      resource = @resource
      routes = @resource.routes
      controller = @resource.controller

      @app.routes.draw do
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
