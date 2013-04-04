class Syphon::Api::ModelDecorator
  extend Forwardable

  class_attribute :resource, :associations, :fields, :aliases, :instance_writer => false  
  def_delegators :resource, :fields, :renames, :resource_name, :joins, :resources, :collections

  class << self

    def init(resource)
      self.resource = resource
      self.associations = fetch_assoc_details
      self
    end

  private

    def fetch_assoc_details
      model = resource.model_klass
      return {} unless model && model.ancestors.include?(ActiveRecord::Base)
      model.reflect_on_all_associations.reduce({}) do |assocs, a| 
        assocs[a.name] = { type: a.macro,
                           foreign_key: (a.options[:foreign_key] || 
                              (a.macro == :belongs_to ? "#{a.name}_id" : "#{resource.resource_name}_id")).to_s }
        assocs
      end
    end

  end

  def initialize(instance)
    @instance = instance
  end

  def to_h
    to_resource_hash
  end

private

  def to_resource_hash
     stringify_large_vals \
     rename_aliased_fields \
     add_collection_links \
     add_resource_links \
     merge_nested_resources \
       collect_whitelisted_fields
  end

  def collect_whitelisted_fields
    fields.reduce({}) do |attrs, field|
      attrs[field] = @instance.send(field) if 
        @instance.respond_to?(field)
      attrs
    end
  end

  def merge_nested_resources(attrs)
    add_resource_fields(joins, attrs) do |resource, assoc|
      if resource.controller_klass.respond_to?(:model_proxy)
        proxy = resource.controller_klass.model_proxy
        assoc.is_a?(Array) ? assoc.map { |a| proxy.wrap(a) } : proxy.wrap(assoc)
      else assoc
      end
    end
  end

  def add_resource_links(attrs)
    add_resource_fields(resources, attrs) do |resource, assoc|
      resource.resource_uri assoc.send(assoc.class.primary_key)
    end
  end

  def add_collection_links(attrs)
    add_resource_fields(collections, attrs) do |resource, assoc|
      assoc_fkey = associations[resource.collection_name][:foreign_key]
      assoc_pkey = @instance.class.primary_key
      resource.query_uri(assoc_fkey, @instance.send(assoc_pkey))
    end
  end

  def rename_aliased_fields(attrs)
    renames.reduce(attrs) do |attrs, (old, new)|
      attrs[new] = attrs.delete(old) if attrs[old]
      attrs
    end
  end

  # JS ends up rounding integers that are larger than can be represented by the
  # IEEE spec, so send long keys over ast strings
  #
  def stringify_large_vals(attrs)
    attrs.each do |k,v|
      attrs[k] = v.to_s if 
        v.is_a?(Numeric) && v > 10000000000
    end
  end

 # resource helper

  def add_resource_fields(associations, attrs)
    associations.reduce(attrs) do |attrs, name|
      if !@instance.respond_to?(name)
        attrs
      elsif (assoc = @instance.send(name)) && 
            (assoc_resource = resource[name])
        attrs[name] = yield(assoc_resource, assoc)
        attrs
      else attrs.merge(name => nil)
      end
    end
  end

end
