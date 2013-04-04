require 'active_support'
require 'active_support/core_ext/string/inflections'

class Syphon::Resource

  HIDDEN_INSTANCE_VARS = [:@resource_set].freeze
  ACTIONS = [ :index, :show, :create, :update, :destroy].freeze
  COMMANDS = [:joins, :resources, :collections].freeze

  attr_reader   :name, :namespace, :only, :except
  attr_accessor *COMMANDS

  def initialize(name, resource_set, context, opts = {})
    @name = name
    @resource_set = resource_set

    @joins = [] 
    @resources = [] 
    @collections = []

    @namespace = context.namespace[1..-1] # remove leading slash
    @uri = "/#{@namespace}/#{@name}"

    only = context.only || opts[:only] || ACTIONS
    except = context.except || opts[:except] || []
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
    @resource_name ||= to_resource_name(@name)
  end

  def collection_name
    @collection_name ||= to_collection_name(@name)
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

  def [](resource)
    if resource.is_a? Class
      @resource_set.detect { |r| r.model_klass == resource }
    else
      @resource_set[to_collection_name(resource)] || 
      @resource_set[to_resource_name(resource)]
    end
  end

private

  def to_resource_name(name)
    name.to_s.singularize.to_sym
  end

  def to_collection_name(name)
    name.to_s.pluralize.to_sym
  end

  def resource_query(fkey, id)
    {where: { fkey => id }}.to_query
  end

end
