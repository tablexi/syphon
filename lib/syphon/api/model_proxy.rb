class Syphon::Api::ModelProxy
  class << self

    def all(conditions = [])
      conditions ||= []

      # query conditions must come first
      conditions.sort_by! { |v| v.is_a?(Hash) ? 0 : 1 }

      results = conditions.reduce(@model.select(@columns)) do |query, cond|
        case cond
        when Hash
          cond.reduce(query) { |query, (cond, val)| query.send(cond, val) }
        else
          query.send(cond)
        end
      end

      results.map { |o| link o }
    end

    def find(id)
      link @model.select(@columns).find_by_id(id)
    end

    def create(attributes = {})
      obj = @model.create(attributes)
      obj.valid? ? find(obj.id) : obj
    end

    def update(id, attributes = {})
      @model.update(id, attributes)
    end

    def destroy(id)
      @model.destroy(id)
    end

    def configure_for_resource(resource)
      @resource_set = resource.resource_set
      @model = resource.model_class
      @fields = resource.fields
      @resources = resource.resources
      @collections = resource.collections

      @columns = @fields + resource_fields
    end

  private

    # FIXME: why send the full hyperlink? a query hash or id would be easier
    #
    def link(object)
      attributes = object.attributes

      @resources.each do |name|
        resource = @resource_set[pluralize(name)]
        resource_id = object.send(name).id
        # attributes[name] = resource.resource_uri(resource_id)
        attributes[name] = resource_id
        attributes.delete(fkey(name)) if attributes.key?(fkey(name))
      end

      @collections.each do |name|
        resource = @resource_set[name]
        # attributes[name] = "#{resource.collection_uri}?#{resource_query(object.id).to_query}"
        attributes[name] = resource_query(object.id)
      end

      attributes
    end

    def pluralize(name)
      name.to_s.pluralize.to_sym
    end

    def resource_fields
     (@resources.map { |r| fkey(r) } & @model.column_names)
    end

    def fkey(resource_name)
      "#{resource_name}_id"
    end

    def resource_query(id)
      {where: { "#{@model.name.downcase}_id" => id }}
    end

  end
end
