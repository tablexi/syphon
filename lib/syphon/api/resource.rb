class Syphon::Api::Resource < Syphon::Resource

  attr_accessor :model, :controller
  attr_reader   :super_controller

  def initialize(name, resource_set, context, opts = {})
    super
    @model = name
    @controller = name
    @super_controller = context.super_controller # can be nil
  end

  def build_controller
    return if controller_class

    model_proxy = Class.new(Syphon::Api::ModelProxy)
    model_proxy.configure_for_resource(self)
    controller = Class.new(super_controller_class || ActionController::Base)
    controller.send(:include, Syphon::Api::CRUDController)
    controller.model_proxy = model_proxy

    namespaced_module.const_set(controller_name, controller)
  end

  def draw_route(application)
    # need the resource in the routes scope
    resource = self
    application.routes.draw do
      nested_namespace(resource.namespace.split('/')) do
        resources resource.name, :controller => resource.controller, 
                                 :only => resource.allowed_actions
      end
    end
  end

  [:controller, :super_controller].each do |attr|
    send(:define_method, "#{attr}_name") do
      camelize_controller(instance_variable_get("@#{attr}"))
    end

    send(:define_method, "#{attr}_class") do
      constantize(namespace_class( send("#{attr}_name")))
    end
  end

  def model_class
    constantize(@model.to_s.classify)
  end

end
