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
      @name = resource.resource_name
      @model = resource.model_klass
      @fields = resource.fields
      @resources = resource.resources
      @collections = resource.collections
      @resource_set = resource.resource_set
      @columns = @fields + foreign_keys
    end

  private

    def foreign_keys
      @model.reflect_on_all_associations.select { |a| 
        a.macro == :belongs_to }.map { |a| 
          (a.options[:foreign_key] || "#{a.name}_id").to_s }
    end

    def foreign_key_for_assoc(assoc)
      assoc = @model.reflect_on_all_associations.detect { |a| a.name == assoc.to_sym }
      (assoc && assoc.options[:foreign_key] || "#{@name}_id").to_s
    end

    # FIXME: clean this up
    #
    def link(object)
      return unless object
      attributes = object.attributes

      @resources.each do |resource|
        name = resource.resource_name
        attributes[name] = \
          if (relation = object.send(name))
            resource.resource_uri(relation.send(relation.class.primary_key))
          else nil
          end
      end

      @collections.each do |resource|
        name = resource.collection_name
        attributes[name] = \
          if (relation = object.send(name).any?)
            fkey = foreign_key_for_assoc(name)
            pkey = (fkey == "#{@name}_id" ? :id : fkey)
            "#{resource.collection_uri}?#{resource_query(fkey, object.send(pkey))}"
          else []
          end
      end

      attributes.except(*foreign_keys)
    end

    def resource_query(fkey, id)
      {where: { fkey => id }}.to_query
    end

  end
end
