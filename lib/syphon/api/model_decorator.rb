require 'active_support/core_ext/class/attribute'

class Syphon::Api::ModelDecorator
  extend Forwardable

  class_attribute :resource, :associations, :fields, :aliases, :dci_modules, :instance_writer => false
  def_delegators :resource, :fields, :renames, :resource_name, :joins, :resources, :collections

  class << self

    def new_class(*args)
      Class.new(self).init(*args)
    end

    def init(resource)
      resource.decorator_class = self
      self.dci_modules = [*resource.instance_include_modules]
      self.resource = resource
      self.associations = fetch_assoc_details
      self
    end

    def wrap(instance)
      self.dci_modules.each { |mod| instance.send(:extend, mod) }
      self.new(instance).to_h
    end

  private

    def fetch_assoc_details
      model = resource.model_class
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
     link_collections \
     link_resources \
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
      if (decorator = resource.decorator_class)
        assoc.is_a?(Array) ?
          assoc.map { |a| decorator.wrap(a) } :
          decorator.wrap(assoc)
      else assoc
      end
    end
  end

  def link_resources(attrs)
    add_resource_fields(resources, attrs) do |resource, assoc|
      resource.resource_uri assoc.send(resource.primary_key)
    end
  end

  def link_collections(attrs)
    add_resource_fields(collections, attrs) do |resource, assoc|
      assocs = associations[resource.collection_name]
      fkey = (assocs && assocs[:foreign_key]) || klass.resource.foreign_key
      resource.query_uri(fkey, @instance.send(klass.resource.primary_key))
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
            (assoc_resource = resource.resource_set.find(name))
        attrs[name] = yield(assoc_resource, assoc)
        attrs
      else attrs.merge(name => nil)
      end
    end
  end

private

  def klass
    self.class
  end

end
