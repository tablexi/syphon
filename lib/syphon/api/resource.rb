class Syphon::Api::Resource < Syphon::Resource
  include Syphon::Inflections

  COMMANDS = [:primary_key, :foreign_key, :model, :scope, :controller, :routes, :fields, :renames].freeze
  SPLAT = [:fields].freeze

  attr_accessor *COMMANDS
  attr_reader   :super_controller, :hidden

  def initialize(name, resource_set, context, opts = {})
    super
    @hidden = opts[:hidden]
    @primary_key = :id
    @foreign_key = "#{resource_name}_id".to_sym
    @model = name
    @scope = nil
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

  def namespace_module
    module_name = namespace.camelize
    mod = constantize(module_name)

    if mod
      return mod
    else
      modules = module_name.split('::')
      modules.reduce(Object) do |mod, name|
        mod.const_defined?(name, false) ? 
             mod.const_get(name) : 
             mod.const_set(name, Module.new)
      end
    end
  end

  def controller_class
    constantize with_namespace controllerize @controller
  end

  def super_controller_class
    constantize controllerize @super_controller
  end

  def model_class
    constantize classify @model
  end

private

  def with_namespace(name)
    "#{@namespace.camelize}::#{name}"
  end

end
