class Syphon::Resource
  include Syphon::Inflections

  HIDDEN_INSTANCE_VARS = [:@resource_set].freeze
  ACTIONS = [ :index, :show, :create, :update, :destroy].freeze
  COMMANDS = [:joins, :resources, :collections].freeze

  attr_reader   :name, :namespace, :only, :except, :resource_set
  attr_accessor *COMMANDS, :decorator_class

  def initialize(name, resource_set, context, opts = {})
    @name = name
    @resource_set = resource_set

    @joins = context.joins || [] 
    @resources = context.resources || [] 
    @collections = context.collections || []

    @namespace = context.namespace
    @namespace = @namespace[1..-1] if @namespace[0] == ?/
    @uri = @namespace.empty? ? "/#{@name}" : "/#{@namespace}/#{@name}"

    only = Array(context.only || opts[:only] || ACTIONS)
    except = Array(context.except || opts[:except] || [])
    @only = (ACTIONS && only) - except
    @except = ACTIONS - @only
  end

  def self.commands
    COMMANDS.inject({}) { |h,c| h[c] = { splat: true }; h }
  end

  def collection_uri
    @uri
  end

  def resource_uri(id)
    "#{@uri}/#{id}"
  end

  def query_uri(fkey, id)
    "#{self.collection_uri}?#{resource_query(fkey, id)}"
  end

  def resource_name
    @resource_name ||= singularize(@name).to_sym
  end

  def collection_name
    @collection_name ||= pluralize(@name).to_sym
  end

  def serialize
    {
      name: @name,
      namespace: "/#{@namespace}",
      resources: @resources,
      collections: @collections, 
      only: @only
    }
  end

  # prettier printing
  #
  def instance_variables
    super - HIDDEN_INSTANCE_VARS
  end

private

  def resource_query(fkey, id)
   {where: { fkey => id }}.to_query
  end

end
