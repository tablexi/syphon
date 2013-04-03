class Syphon::Api::ModelDecorator
  extend Forwardable

  class_attribute :resource, :associations, :columns, :dynamic_fields, :foreign_keys, :instance_writer => false  
  def_delegators :resource, :resource_name, :joins, :resources, :collections

  class << self

    def init(resource)
      self.resource = resource
      @model = resource.model_klass
      @fields = resource.fields.map(&:to_s)

      self.associations = fetch_assoc_details
      self.foreign_keys = fetch_foreign_keys
      self.dynamic_fields = @fields - @model.column_names
      self.columns = @fields - dynamic_fields + foreign_keys

      self
    end

  private

    def fetch_assoc_details
      @model.reflect_on_all_associations.reduce({}) do |assocs, a| 
        assocs[a.name] = { type: a.macro,
                           foreign_key: (a.options[:foreign_key] || 
                              (a.macro == :belongs_to ? "#{a.name}_id" : "#{resource.resource_name}_id")).to_s }
        assocs
      end
    end

    def fetch_foreign_keys
      associations.reduce([]) do |keys, (n,a)| 
        a[:type] == :belongs_to ? keys << a[:foreign_key] : keys
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
     reject_foreign_keys \
     add_collection_links \
     add_resource_links \
     merge_nested_resources \
     merge_dynamic_fields \
     reject_unwanted_fields \
      @instance.attributes
  end

  def reject_unwanted_fields(attrs)
    attrs.slice(*columns)
  end

  def merge_dynamic_fields(attrs)
    dynamic_fields.reduce(attrs) do |attrs, field|
      attrs[field] = @instance.send(field)
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

  def reject_foreign_keys(attrs)
    attrs.except(*foreign_keys)
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
