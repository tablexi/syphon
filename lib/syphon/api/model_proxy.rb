class Syphon::Api::ModelProxy
  class_attribute :model, :fields

  class << self

    def all(conditions = [])
      conditions ||= []
      conditions.sort_by! { |v| v.is_a?(Hash) ? 0 : 1 } # query conditions must come first
      conditions.reduce(model.select(fields)) do |query, cond|
        case cond
        when Hash
          cond.reduce(query) { |query, (cond, val)| query.send(cond, val) }
        else
          query.send(cond)
        end
      end
    end

    def find(id)
      model.select(fields).find_by_id(id)
    end

    def create(attributes = {})
      obj = model.create(attributes)
      obj.valid? ? find(obj.id) : obj
    end

    def update(id, attributes = {})
      model.update(id, attributes)
    end

    def destroy(id)
      model.destroy(id)
    end

  end
end
