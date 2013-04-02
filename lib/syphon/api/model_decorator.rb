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
                           foreign_key: (a.options[:foreign_key] || "#{a.name}_id").to_s }
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

  #FIXME: refactor
  def merge_nested_resources(attrs)
    joins.reduce(attrs) do |attrs, name|
      my_resource = resource.find_resource(name)
      # check if controller was built by Syphon
      #
      attrs[name] = \
        if my_resource.controller_klass.respond_to?(:model_proxy)
          val = @instance.send(name)
          model_proxy = my_resource.controller_klass.model_proxy
          if val.is_a? Array
            val.map { |v| model_proxy.wrap(v) }
          else model_proxy.wrap(val)
          end
        else 
          @instance.send(name)
        end
      attrs
    end
  end

  def add_resource_links(attrs)
    resources.reduce(attrs) do |attrs, name|
      my_resource = resource.find_resource(name)
      name = my_resource.resource_name
      attrs[name] = \
        if (relation = @instance.send(name))
          my_resource.resource_uri(relation.send(relation.class.primary_key))
        else nil
        end
      attrs
    end
  end

  def add_collection_links(attrs)
    collections.reduce(attrs) do |attrs, name|
      my_resource = resource.find_resource(name)
      name = my_resource.collection_name
      attrs[name] = \
        if (relation = @instance.send(name).any?)
          binding.pry
          fkey = associations[name][:foreign_key]
          pkey = (fkey == "#{my_resource.resource_name}_id" ? :id : fkey)
          "#{my_resource.collection_uri}?#{resource_query(fkey, @instance.send(pkey))}"
        else []
        end
      attrs
    end
  end

  def reject_foreign_keys(attrs)
    attrs.except(*foreign_keys)
  end

  def resource_query(fkey, id)
    {where: { fkey => id }}.to_query
  end

end
