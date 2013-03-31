class Syphon::Resource

  ACTIONS = [ :index, :show, :create, :update, :destroy].freeze

  attr_reader   :name, :resource_set, :namespace, :allowed_actions, :disallowed_actions
  attr_accessor :fields, :resources, :collections

  def initialize(name, resource_set, context, opts = {})
    @name = name
    @resource_set = resource_set
    @context = context

    @fields, @resources, @collections = [], [], []

    @namespace = context.namespace[1..-1] # remove leading slash
    @uri = "/#{@namespace}/#{@name}"

    @allowed_actions = ACTIONS && (opts[:only] || ACTIONS) - (opts[:except] || [])
    @disallowed_actions = ACTIONS - allowed_actions
  end

  # uri helpers

  def collection_uri
    @uri
  end

  def resource_uri(id)
    "#{@uri}/#{id}"
  end

private

  def namespaced_module
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

  def pluralize(name)
    "#{name}s".to_sym
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
