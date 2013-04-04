class Syphon::Api::Resource < Syphon::Resource

  COMMANDS = [:primary_key, :model, :controller, :routes, :fields, :renames].freeze
  SPLAT = [:fields].freeze

  attr_accessor *COMMANDS
  attr_reader   :super_controller

  def initialize(name, resource_set, context, opts = {})
    super
    @hidden = opts[:hidden]
    @primary_key = :id
    @model = name
    @controller = name
    @routes = {}
    @fields = [] 
    @renames = [] 
    @super_controller = context.super_controller # can be nil
  end

  def self.commands
    commands = COMMANDS.inject({}) do |h,c| 
      h[c] = { splat: SPLAT.include?(c) }; h 
    end

    super.merge(commands)
  end

  def build_controller!
    build_controller_chain
  end

  def draw_routes!(app)
    unless @hidden
      @routes.empty? ? draw_resourceful_routes(app) : draw_custom_routes(app)
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
    controller = controller_klass || 
      Class.new(super_controller_klass || ActionController::Base)

    controller.send(:include, Syphon::Api::CRUDController)
    controller.init(self)

    const_namespace.const_set(controller_name, controller) unless controller.name
  end

  def draw_resourceful_routes(app)
    resource = self
    app.routes.draw do
      nested_namespace(resource.namespace.split('/')) do
        resources resource.name, :controller => resource.controller, 
                                 :only => resource.only
      end
    end
  end

  def draw_custom_routes(app)
    resource = self
    routes = @routes
    controller = @controller
    app.routes.draw do
      nested_namespace(resource.namespace.split('/')) do
        routes.each do |action, route|
          requests, route = route if route.is_a?(Array)
          match route => "#{controller}##{action}", 
            :via => requests || [:get]
        end
      end
    end
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
