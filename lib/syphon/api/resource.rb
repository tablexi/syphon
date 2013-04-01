class Syphon::Api::Resource < Syphon::Resource

  attr_accessor :model, :controller
  attr_reader   :super_controller

  def initialize(name, resource_set, context, opts = {})
    super
    @model = name
    @controller = name
    @super_controller = context.super_controller # can be nil
  end

  def build_controller!
    return if controller_klass
    const_namespace.const_set(controller_name, build_controller_chain)
  end

  def draw_route!(application)
    # need the resource in the routes scope
    resource = self
    application.routes.draw do
      nested_namespace(resource.namespace.split('/')) do
        resources resource.name, :controller => resource.controller, 
                                 :only => resource.only
      end
    end
  end

  # inflection helpers
  #
  [:controller, :super_controller].each do |attr|
    send(:define_method, "#{attr}_name") do
      val = instance_variable_get("@#{attr}")
      val && normalize_controller(val)
    end

    send(:define_method, "#{attr}_klass") do
      val = send("#{attr}_name")
      val && constantize(namespace_const(val))
    end
  end

  def model_klass
    @model && constantize(@model.to_s.classify)
  end

private

  def build_controller_chain
    model_proxy = Class.new(Syphon::Api::ModelProxy)
    model_proxy.configure_for_resource(self)
    controller = Class.new(super_controller_klass || ActionController::Base)
    controller.send(:include, Syphon::Api::CRUDController)
    controller.model_proxy = model_proxy
    controller
  end

  def normalize_controller(name)
    "#{name.to_s.camelize}Controller"
  end

  def namespace_const(name)
    "#{@namespace.camelize}::#{name}"
  end

  def const_namespace
    module_name = @namespace.camelize
    mod = constantize(module_name)

    if mod
      return mod
    else
      modules = module_name.split('::').reverse
      modules.reduce(Object) do |mod, name|
        mod.const_set(name, Module.new)
      end
    end
  end

  # Fixes stupid safe_constantize behavior where
  # "NS1::NS2::SomeClass".safe_constantize returns 
  # ::SomeClass if it exists
  #
  def constantize(name)
    const = name.safe_constantize
    const.to_s == name ? const : nil
  end

end
