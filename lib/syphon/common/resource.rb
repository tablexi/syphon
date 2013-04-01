require 'active_support'
require 'active_support/core_ext/string/inflections'

class Syphon::Resource

  HIDDEN_INSTANCE_VARS = [:@resource_set, :@resources, :@collections].freeze
  ACTIONS = [ :index, :show, :create, :update, :destroy].freeze

  attr_reader   :name, :resource_set, :namespace, :only, :except
  attr_accessor :fields, :resources, :collections

  def initialize(name, resource_set, context, opts = {})
    @name = name
    @resource_set = resource_set

    @fields = context.fields || [] 
    @resources = context.resources || [] 
    @collections = context.collections || []

    @namespace = context.namespace[1..-1] # remove leading slash
    @uri = "/#{@namespace}/#{@name}"

    only = context.only || opts[:only] || ACTIONS
    except = context.except || opts[:except] || []
    @only = (ACTIONS && only) - except
    @except = ACTIONS - @only
  end

  def collection_uri
    @uri
  end

  def resource_uri(id)
    "#{@uri}/#{id}"
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
      resources: @resources.map { |r| r.name },
      collections: @collections.map { |r| r.name }, 
      only: @only
    }
  end

  def finalize!
    map_resource_associations!
  end

  # prettier printing
  #
  def instance_variables
    super - HIDDEN_INSTANCE_VARS
  end

private

  def map_resource_associations!
    map_associations!(@resources)
    map_associations!(@collections)
  end

  def map_associations!(resources)
    resources.map! do |resource|
      @resource_set[to_collection_name(resource)] || 
      @resource_set[to_resource_name(resource)]
    end.compact!
  end

  def to_resource_name(name)
    name.to_s.singularize
  end

  def to_collection_name(name)
    name.to_s.pluralize
  end

end
