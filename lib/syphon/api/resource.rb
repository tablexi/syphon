class Syphon::Api::Resource

  ACTIONS = [ :index, :show, :create, :update, :destroy].freeze

  attr_accessor :api, :model, :controller, :fields, :resources, :collections
  attr_reader   :name, :namespace, :super_controller, :allowed_actions, :disallowed_actions

  def initialize(name, context, opts = {})
    @name = @model = @controller = name
    @namespace = context.namespace[1..-1] # remove leading slash
    @super_controller = context.super_controller # can be nil
    @fields, @resources, @collections = [], [], []
    @uri = "/#{@namespace}/#{@name}"

    @allowed_actions = ACTIONS && (opts[:only] || ACTIONS) - (opts[:except] || [])
    @disallowed_actions = ACTIONS - allowed_actions
  end

  def build_controller
    return if controller_class

    model_proxy = Class.new(Syphon::Api::ModelProxy)
    model_proxy.configure_for_resource(self)
    controller = Class.new(super_controller_class || ActionController::Base)
    controller.send(:include, Syphon::Api::CRUDController)
    controller.model_proxy = model_proxy

    module_namespace.const_set(controller_name, controller)
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

  # uri helpers

  def collection_uri
    @uri
  end

  def resource_uri(id)
    "#{@uri}/#{id}"
  end

private

  def module_namespace
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

  # inflection

  def camelize(name)
    name.to_s.camelize
  end

  def camelize_controller(name)
    "#{camelize(name)}Controller"
  end

  def namespace_class(name)
    "#{@namespace.camelize}::#{name}"
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
